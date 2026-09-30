import 'package:personal_todo/data/app_database.dart';
import 'package:personal_todo/domain/attachment.dart';
import 'package:personal_todo/domain/category.dart';
import 'package:personal_todo/domain/enums.dart';
import 'package:personal_todo/domain/recurrence.dart';
import 'package:personal_todo/domain/subtask.dart';
import 'package:personal_todo/domain/tag.dart';
import 'package:personal_todo/domain/task.dart';
import 'package:personal_todo/domain/task_note.dart';
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
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(Duration(days: days + 1));
    final rows = await (await _db).query(
      'tasks',
      where: 'scheduled_at >= ? AND scheduled_at < ? AND status NOT IN (?, ?)',
      whereArgs: [
        start.toIso8601String(),
        end.toIso8601String(),
        TaskStatus.completed.name,
        TaskStatus.skipped.name,
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
    final q = '%${query.trim().toLowerCase()}%';
    final rows = await (await _db).query(
      'tasks',
      where: 'LOWER(title) LIKE ? OR LOWER(description) LIKE ?',
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
    String? seriesId,
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
      seriesId: seriesId ?? (recurrence.isRecurring ? id : null),
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
          seriesId: task.seriesId ?? task.id,
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
          seriesId: task.seriesId ?? task.id,
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
    await db.transaction((txn) async {
      await txn.delete('tasks');
      for (final task in tasks) {
        await txn.insert('tasks', task.toMap());
      }
    });
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
          final tomorrow = DateTime(now.year, now.month, now.day)
              .add(const Duration(days: 1));
          final moved = DateTime(
            tomorrow.year,
            tomorrow.month,
            tomorrow.day,
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

  Future<void> applyCarryForward(CarryForwardPolicy policy) async {
    if (policy == CarryForwardPolicy.askUser) return;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final rows = await (await _db).query(
      'tasks',
      where: 'scheduled_at >= ? AND scheduled_at < ? AND status IN (?, ?)',
      whereArgs: [
        yesterday.toIso8601String(),
        DateTime(now.year, now.month, now.day).toIso8601String(),
        TaskStatus.upcoming.name,
        TaskStatus.snoozed.name,
      ],
    );
    for (final row in rows) {
      final task = Task.fromMap(row);
      switch (policy) {
        case CarryForwardPolicy.keepOverdue:
          break;
        case CarryForwardPolicy.moveTomorrow:
          final tomorrow = DateTime(now.year, now.month, now.day)
              .add(const Duration(days: 1));
          final moved = DateTime(
            tomorrow.year,
            tomorrow.month,
            tomorrow.day,
            task.scheduledAt.hour,
            task.scheduledAt.minute,
          );
          await updateTask(
            task.copyWith(scheduledAt: moved, status: TaskStatus.upcoming),
          );
        case CarryForwardPolicy.markMissed:
          await updateTask(task.copyWith(status: TaskStatus.missed));
        case CarryForwardPolicy.askUser:
          break;
      }
    }
  }

  Future<List<Task>> getArchived() async {
    final rows = await (await _db).query(
      'tasks',
      where: 'status = ?',
      whereArgs: [TaskStatus.cancelled.name],
      orderBy: 'updated_at DESC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<void> archiveTask(String id) async {
    final task = await getById(id);
    if (task == null) return;
    await updateTask(task.copyWith(status: TaskStatus.cancelled));
  }

  Future<void> restoreTask(String id) async {
    final task = await getById(id);
    if (task == null) return;
    await updateTask(task.copyWith(status: TaskStatus.upcoming));
  }

  Future<int> getStreakCount() async {
    final tasks = await getAll();
    final completedDates = <DateTime>{};
    for (final task in tasks) {
      if (task.isCompleted) {
        completedDates.add(DateTime(
          task.scheduledAt.year,
          task.scheduledAt.month,
          task.scheduledAt.day,
        ));
      }
    }
    if (completedDates.isEmpty) return 0;
    final sorted = completedDates.toList()..sort();
    var streak = 1;
    for (var i = sorted.length - 1; i > 0; i--) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}

class CategoryRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Category>> getAll() async {
    final rows = await (await _db).query('categories', orderBy: 'name ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<void> create(Category category) async {
    await (await _db).insert('categories', category.toMap());
  }

  Future<void> update(Category category) async {
    await (await _db).update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> delete(String id) async {
    await (await _db).delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> replaceAll(List<Category> categories) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('categories');
      for (final c in categories) {
        await txn.insert('categories', c.toMap());
      }
    });
  }
}

class TagRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Tag>> getAll() async {
    final rows = await (await _db).query('tags', orderBy: 'name ASC');
    return rows.map(Tag.fromMap).toList();
  }

  Future<void> create(Tag tag) async {
    await (await _db).insert('tags', tag.toMap());
  }

  Future<void> update(Tag tag) async {
    await (await _db).update(
      'tags',
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  Future<void> delete(String id) async {
    await (await _db).delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addToTask(String taskId, String tagId) async {
    await (await _db).insert('task_tags', {
      'task_id': taskId,
      'tag_id': tagId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeFromTask(String taskId, String tagId) async {
    await (await _db).delete(
      'task_tags',
      where: 'task_id = ? AND tag_id = ?',
      whereArgs: [taskId, tagId],
    );
  }

  Future<List<Tag>> getForTask(String taskId) async {
    final rows = await (await _db).rawQuery(
      'SELECT t.* FROM tags t INNER JOIN task_tags tt ON t.id = tt.tag_id WHERE tt.task_id = ?',
      [taskId],
    );
    return rows.map(Tag.fromMap).toList();
  }
}

class SubtaskRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Subtask>> getForTask(String taskId) async {
    final rows = await (await _db).query(
      'subtasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Subtask.fromMap).toList();
  }

  Future<void> create(Subtask subtask) async {
    await (await _db).insert('subtasks', subtask.toMap());
  }

  Future<void> update(Subtask subtask) async {
    await (await _db).update(
      'subtasks',
      subtask.toMap(),
      where: 'id = ?',
      whereArgs: [subtask.id],
    );
  }

  Future<void> delete(String id) async {
    await (await _db).delete('subtasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteForTask(String taskId) async {
    await (await _db).delete('subtasks', where: 'task_id = ?', whereArgs: [taskId]);
  }
}

class TaskNoteRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<TaskNote>> getForTask(String taskId) async {
    final rows = await (await _db).query(
      'task_notes',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'created_at DESC',
    );
    return rows.map(TaskNote.fromMap).toList();
  }

  Future<void> create(TaskNote note) async {
    await (await _db).insert('task_notes', note.toMap());
  }

  Future<void> update(TaskNote note) async {
    await (await _db).update(
      'task_notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> delete(String id) async {
    await (await _db).delete('task_notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteForTask(String taskId) async {
    await (await _db).delete('task_notes', where: 'task_id = ?', whereArgs: [taskId]);
  }
}

class AttachmentRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Attachment>> getForTask(String taskId) async {
    final rows = await (await _db).query(
      'attachments',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Attachment.fromMap).toList();
  }

  Future<void> create(Attachment attachment) async {
    await (await _db).insert('attachments', attachment.toMap());
  }

  Future<void> delete(String id) async {
    await (await _db).delete('attachments', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteForTask(String taskId) async {
    await (await _db).delete('attachments', where: 'task_id = ?', whereArgs: [taskId]);
  }
}

class TaskDependencyRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<String>> getDependencies(String taskId) async {
    final rows = await (await _db).query(
      'task_dependencies',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
    return rows.map((r) => r['depends_on_task_id'] as String).toList();
  }

  Future<void> addDependency(String taskId, String dependsOnTaskId) async {
    await (await _db).insert('task_dependencies', {
      'task_id': taskId,
      'depends_on_task_id': dependsOnTaskId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeDependency(String taskId, String dependsOnTaskId) async {
    await (await _db).delete(
      'task_dependencies',
      where: 'task_id = ? AND depends_on_task_id = ?',
      whereArgs: [taskId, dependsOnTaskId],
    );
  }

  Future<void> removeAllDependencies(String taskId) async {
    await (await _db).delete(
      'task_dependencies',
      where: 'task_id = ? OR depends_on_task_id = ?',
      whereArgs: [taskId, taskId],
    );
  }
}
