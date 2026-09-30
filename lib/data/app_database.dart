import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  final uuid = const Uuid();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final documents = await getApplicationDocumentsDirectory();
    final dbPath = p.join(documents.path, 'personal_todo.db');

    return openDatabase(
      dbPath,
      version: 3,
      onCreate: (db, version) async {
        await _createV2(db);
        await _seedCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _upgradeToV2(db);
          await _seedCategories(db);
        }
        if (oldVersion < 3) {
          await _upgradeToV3(db);
        }
      },
    );
  }

  Future<void> _createV2(Database db) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        scheduled_at TEXT NOT NULL,
        status TEXT NOT NULL,
        priority TEXT NOT NULL DEFAULT 'normal',
        category_id TEXT,
        recurrence_type TEXT NOT NULL DEFAULT 'none',
        recurrence_weekdays TEXT NOT NULL DEFAULT '',
        recurrence_interval INTEGER NOT NULL DEFAULT 1,
        reminder_minutes_before INTEGER NOT NULL DEFAULT 0,
        series_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_tasks_scheduled_at ON tasks(scheduled_at)',
    );
    await db.execute(
      'CREATE INDEX idx_tasks_status ON tasks(status)',
    );
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        icon_code_point INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL DEFAULT 4278193402
      )
    ''');
    await db.execute('''
      CREATE TABLE task_tags (
        task_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (task_id, tag_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE subtasks (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE task_notes (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE attachments (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size INTEGER NOT NULL DEFAULT 0,
        mime_type TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE task_dependencies (
        task_id TEXT NOT NULL,
        depends_on_task_id TEXT NOT NULL,
        PRIMARY KEY (task_id, depends_on_task_id)
      )
    ''');
  }

  Future<void> _upgradeToV2(Database db) async {
    // Old v1 table may exist with fewer columns — recreate safely.
    final tasks = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='tasks'",
    );
    if (tasks.isNotEmpty) {
      await db.execute('ALTER TABLE tasks RENAME TO tasks_old');
    }
    await _createV2(db);
    if (tasks.isNotEmpty) {
      await db.execute('''
        INSERT INTO tasks (
          id, title, description, scheduled_at, status, priority, category_id,
          recurrence_type, recurrence_weekdays, recurrence_interval,
          reminder_minutes_before, series_id, created_at, updated_at
        )
        SELECT
          id, title, description, scheduled_at, status, 'normal', NULL,
          'none', '', 1, 0, NULL, created_at, updated_at
        FROM tasks_old
      ''');
      await db.execute('DROP TABLE tasks_old');
    }
  }

  Future<void> _upgradeToV3(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    final existing = tables.map((r) => r['name'] as String).toSet();

    if (!existing.contains('tags')) {
      await db.execute('''
        CREATE TABLE tags (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          color_value INTEGER NOT NULL DEFAULT 4278193402
        )
      ''');
    }
    if (!existing.contains('task_tags')) {
      await db.execute('''
        CREATE TABLE task_tags (
          task_id TEXT NOT NULL,
          tag_id TEXT NOT NULL,
          PRIMARY KEY (task_id, tag_id)
        )
      ''');
    }
    if (!existing.contains('subtasks')) {
      await db.execute('''
        CREATE TABLE subtasks (
          id TEXT PRIMARY KEY,
          task_id TEXT NOT NULL,
          title TEXT NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (!existing.contains('task_notes')) {
      await db.execute('''
        CREATE TABLE task_notes (
          id TEXT PRIMARY KEY,
          task_id TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');
    }
    if (!existing.contains('attachments')) {
      await db.execute('''
        CREATE TABLE attachments (
          id TEXT PRIMARY KEY,
          task_id TEXT NOT NULL,
          file_name TEXT NOT NULL,
          file_path TEXT NOT NULL,
          file_size INTEGER NOT NULL DEFAULT 0,
          mime_type TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (!existing.contains('task_dependencies')) {
      await db.execute('''
        CREATE TABLE task_dependencies (
          task_id TEXT NOT NULL,
          depends_on_task_id TEXT NOT NULL,
          PRIMARY KEY (task_id, depends_on_task_id)
        )
      ''');
    }
  }

  Future<void> _seedCategories(Database db) async {
    final existing = await db.query('categories', limit: 1);
    if (existing.isNotEmpty) return;

    const defaults = <Map<String, Object>>[
      {'name': 'Personal', 'color': 0xFF1F6F5F},
      {'name': 'College', 'color': 0xFF2F5D8C},
      {'name': 'Study', 'color': 0xFF6B4E71},
      {'name': 'Coding', 'color': 0xFF3D5A40},
      {'name': 'Trading', 'color': 0xFF8B5E34},
      {'name': 'Health', 'color': 0xFFB04A4A},
      {'name': 'Family', 'color': 0xFF4A6FA5},
      {'name': 'Other', 'color': 0xFF5C5C5C},
    ];

    final batch = db.batch();
    for (final item in defaults) {
      batch.insert('categories', {
        'id': uuid.v4(),
        'name': item['name'],
        'color_value': item['color'],
        'icon_code_point': 0xe57f,
      });
    }
    await batch.commit(noResult: true);
  }
}
