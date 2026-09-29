import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:personal_todo/domain/task.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class TaskRepository {
  Database? _db;
  final _uuid = const Uuid();

  Future<void> init() async {
    final documents = await getApplicationDocumentsDirectory();
    final dbPath = p.join(documents.path, 'personal_todo.db');

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            scheduled_at TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_tasks_scheduled_at ON tasks(scheduled_at)',
        );
      },
    );
  }

  Database get _database {
    final db = _db;
    if (db == null) {
      throw StateError('TaskRepository.init() must be called first.');
    }
    return db;
  }

  Future<List<Task>> getTasksForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final rows = await _database.query(
      'tasks',
      where: 'scheduled_at >= ? AND scheduled_at < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'scheduled_at ASC',
    );

    return rows.map(Task.fromMap).toList();
  }

  Future<Task> createTask({
    required String title,
    String description = '',
    required DateTime scheduledAt,
  }) async {
    final now = DateTime.now();
    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      description: description.trim(),
      scheduledAt: scheduledAt,
      status: TaskStatus.upcoming,
      createdAt: now,
      updatedAt: now,
    );

    await _database.insert('tasks', task.toMap());
    return task;
  }

  Future<void> markCompleted(String id) async {
    await _database.update(
      'tasks',
      {
        'status': TaskStatus.completed.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markUpcoming(String id) async {
    await _database.update(
      'tasks',
      {
        'status': TaskStatus.upcoming.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTask(String id) async {
    await _database.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
