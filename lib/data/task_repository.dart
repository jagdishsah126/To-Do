import 'package:personal_todo/data/app_database.dart';
import 'package:personal_todo/domain/category.dart';
import 'package:personal_todo/domain/enums.dart';
import 'package:personal_todo/domain/recurrence.dart';
import 'package:personal_todo/domain/task.dart';
import 'package:personal_todo/services/recurrence_engine.dart';
import 'package:sqflite/sqflite.dart';

class TaskRepository {
  TaskRepository({RecurrenceEngine? recurrenceEngine})
      : _recurrence = recurrenceEngine ?? const RecurrenceEngine();

  final RecurrenceEngine _recurrence;

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Task>> getTasksForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await (await _db).query(
      'tasks',
      where: 'scheduled_at >= ? AND scheduled_at < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'scheduled_at ASC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<List<Task>> getUpcoming({int days = 7}) async {
    final start = DateTime.now();
    final end = DateTime(start.year, start.month, start.day)
        .add(Duration(days: days + 1));
    final rows = await (await _db).query(
      'tasks',
      where: 'scheduled_at >= ? AND scheduled_at < ? AND status != ?',
      whereArgs: [
        start.toIso8601String(),
        end.toIso8601String(),
        TaskStatus.completed.name,
      ],
      orderBy: 'scheduled_at ASC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<List<Task>> getTasksBetween(DateTime start, DateTime end) async {
    final rows = await (await _db).query(
      'tasks',
      where: 'scheduled_at >= ? AND scheduled_at < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'scheduled_at ASC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<List<Task>> search(String query) async {
    final q = '%${query.trim()}%';
    final rows = await (await _db).query(
      'tasks',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: [q, q],
      orderBy: 'scheduled_at DESC',
      limit: 100,
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<Task?> getById(String id) async {
    final rows = await (await _db).query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Task.fromMap(rows.first);
  }

  Future<List<Task>> getAll() async {
    final rows = await (await _db).query('tasks', orderBy: 'scheduled_at ASC');
    return rows.map(Task.fromMap).toList();
  }

  Future<List<Task>> getPendingReminders() async {
    final rows = await (await _db).query(
      'tasks',
      where: 'status IN (?, ?) AND scheduled_at > ?',
      whereArgs: [
        TaskStatus.upcoming.name,
        TaskStatus.snoozed.name,
        DateTime.now().toIso8601String(),
      ],
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<Task> createTask({
    required String title,
    String description = '',
    required DateTime scheduledAt,
    TaskPriority priority = TaskPriority.normal,
    String? categoryId,
    RecurrenceRule recurrence = const RecurrenceRule(),
    int reminderMinutesBefore = 0,
  }) async {
    final now = DateTime.now();
    final id = AppDatabase.instance.uuid.v4();
    final task = Task(
      id: id,
      title: title.trim(),
      description: description.trim(),
      scheduledAt: scheduledAt,
      status: TaskStatus.upcoming,
      priority: priority,
      categoryId: categoryId,
      recurrence: recurrence,
      reminderMinutesBefore: reminderMinutesBefore,
      seriesId: recurrence.isRecurring ? id : null,
      createdAt: now,
      updatedAt: now,
    );
    await (await _db).insert('tasks', task.toMap());
    return task;
  }

  Future<Task> updateTask(Task task) async {
    final updated = task.copyWith(updatedAt: DateTime.now());
    await (await _db).update(
      'tasks',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    return updated;
  }

  Future<Task?> complete(String id) async {
    final task = await getById(id);
    if (task == null) return null;

    final completed = task.copyWith(
      status: TaskStatus.completed,
      updatedAt: DateTime.now(),
    );
    await updateTask(completed);

    if (task.recurrence.isRecurring) {
      final nextAt = _recurrence.nextOccurrence(task.scheduledAt, task.recurrence);
      if (nextAt != null) {
        return createTask(
          title: task.title,
          description: task.description,
          scheduledAt: nextAt,
          priority: task.priority,
          categoryId: task.categoryId,
          recurrence: task.recurrence,
          reminderMinutesBefore: task.reminderMinutesBefore,
        );
      }
    }
    return null;
  }

  Future<Task?> skip(String id) async {
    final task = await getById(id);
    if (task == null) return null;

    final skipped = task.copyWith(
      status: TaskStatus.skipped,
      updatedAt: DateTime.now(),
    );
    await updateTask(skipped);

    if (task.recurrence.isRecurring) {
      final nextAt = _recurrence.nextOccurrence(task.scheduledAt, task.recurrence);
      if (nextAt != null) {
        return createTask(
          title: task.title,
          description: task.description,
          scheduledAt: nextAt,
          priority: task.priority,
          categoryId: task.categoryId,
          recurrence: task.recurrence,
          reminderMinutesBefore: task.reminderMinutesBefore,
        );
      }
    }
    return null;
  }

  Future<Task?> snooze(String id, Duration by) async {
    final task = await getById(id);
    if (task == null) return null;
    final next = DateTime.now().add(by);
    return updateTask(
      task.copyWith(
        scheduledAt: next,
        status: TaskStatus.snoozed,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<Task?> reschedule(String id, DateTime when) async {
    final task = await getById(id);
    if (task == null) return null;
    return updateTask(
      task.copyWith(
        scheduledAt: when,
        status: TaskStatus.upcoming,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> markUpcoming(String id) async {
    final task = await getById(id);
    if (task == null) return;
    await updateTask(
      task.copyWith(status: TaskStatus.upcoming, updatedAt: DateTime.now()),
    );
  }

  Future<void> deleteTask(String id) async {
    await (await _db).delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    await (await _db).delete('tasks');
  }

  Future<void> replaceAll(List<Task> tasks) async {
    final db = await _db;
    final batch = db.batch();
    batch.delete('tasks');
    for (final task in tasks) {
      batch.insert('tasks', task.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> applyMissedPolicy(MissedTaskPolicy policy) async {
    if (policy == MissedTaskPolicy.askUser) return;
    final now = DateTime.now();
    final rows = await (await _db).query(
      'tasks',
      where: 'scheduled_at < ? AND status IN (?, ?)',
      whereArgs: [
        now.toIso8601String(),
        TaskStatus.upcoming.name,
        TaskStatus.snoozed.name,
      ],
    );
    for (final row in rows) {
      final task = Task.fromMap(row);
      switch (policy) {
        case MissedTaskPolicy.markMissed:
          await updateTask(task.copyWith(status: TaskStatus.missed));
        case MissedTaskPolicy.keepOverdue:
          break;
        case MissedTaskPolicy.moveTomorrow:
          final moved = DateTime(
            now.year,
            now.month,
            now.day + 1,
            task.scheduledAt.hour,
            task.scheduledAt.minute,
          );
          await updateTask(
            task.copyWith(scheduledAt: moved, status: TaskStatus.upcoming),
          );
        case MissedTaskPolicy.askUser:
          break;
      }
    }
  }
}

class CategoryRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Category>> getAll() async {
    final rows = await (await _db).query('categories', orderBy: 'name ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<void> replaceAll(List<Category> categories) async {
    final db = await _db;
    final batch = db.batch();
    batch.delete('categories');
    for (final c in categories) {
      batch.insert('categories', c.toMap());
    }
    await batch.commit(noResult: true);
  }
}
