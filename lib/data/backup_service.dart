import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:personal_todo/data/settings_repository.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/category.dart';
import 'package:personal_todo/domain/task.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  BackupService({
    required this.tasks,
    required this.categories,
    required this.settings,
  });

  final TaskRepository tasks;
  final CategoryRepository categories;
  final SettingsRepository settings;

  Future<String> exportToFile() async {
    final allTasks = await tasks.getAll();
    final allCategories = await categories.getAll();
    final appSettings = await settings.load();

    final payload = {
      'app': 'personal_todo',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': allTasks.map((t) => t.toMap()).toList(),
      'categories': allCategories.map((c) => c.toMap()).toList(),
      'settings': appSettings.toStorageMap(),
    };

    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(
        dir.path,
        'personal_todo_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      ),
    );
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    return file.path;
  }

  Future<int> importFromPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return 0;

    final file = result.files.first;
    final raw = file.bytes != null
        ? utf8.decode(file.bytes!)
        : await File(file.path!).readAsString();

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup file is invalid.');
    }
    if (decoded['app'] != 'personal_todo') {
      throw const FormatException('Not a Personal Todo backup.');
    }
    final version = decoded['version'];
    if (version != 1) {
      throw FormatException('Unsupported backup version: $version');
    }

    final taskMaps = (decoded['tasks'] as List?) ?? const [];
    final categoryMaps = (decoded['categories'] as List?) ?? const [];
    final settingsMap = Map<String, dynamic>.from(
      (decoded['settings'] as Map?) ?? const {},
    );

    final importedTasks = taskMaps
        .whereType<Map>()
        .map((e) => Task.fromMap(Map<String, Object?>.from(e)))
        .toList();
    final importedCategories = categoryMaps
        .whereType<Map>()
        .map((e) => Category.fromMap(Map<String, Object?>.from(e)))
        .toList();

    await tasks.replaceAll(importedTasks);
    if (importedCategories.isNotEmpty) {
      await categories.replaceAll(importedCategories);
    }
    if (settingsMap.isNotEmpty) {
      final mapped = <String, String>{
        for (final e in settingsMap.entries) '${e.key}': '${e.value}',
      };
      await settings.save(AppSettings.fromStorageMap(mapped));
    }

    return importedTasks.length;
  }
}
