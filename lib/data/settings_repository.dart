import 'package:personal_todo/data/app_database.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:sqflite/sqflite.dart';

class SettingsRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<AppSettings> load() async {
    final rows = await (await _db).query('settings');
    final map = <String, String>{
      for (final row in rows)
        row['key'] as String: row['value'] as String,
    };
    return AppSettings.fromStorageMap(map);
  }

  Future<void> save(AppSettings settings) async {
    final db = await _db;
    final batch = db.batch();
    for (final entry in settings.toStorageMap().entries) {
      batch.insert(
        'settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
