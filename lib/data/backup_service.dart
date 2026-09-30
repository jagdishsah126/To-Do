import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:personal_todo/data/settings_repository.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/attachment.dart';
import 'package:personal_todo/domain/category.dart';
import 'package:personal_todo/domain/subtask.dart';
import 'package:personal_todo/domain/tag.dart';
import 'package:personal_todo/domain/task.dart';
import 'package:personal_todo/domain/task_note.dart';
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
    final tagRepo = TagRepository();
    final allTags = await tagRepo.getAll();
    final subtaskRepo = SubtaskRepository();
    final noteRepo = TaskNoteRepository();
    final attachmentRepo = AttachmentRepository();

    final allSubtasks = <Map<String, Object?>>[];
    final allNotes = <Map<String, Object?>>[];
    final allAttachments = <Map<String, Object?>>[];
    final allTaskTags = <Map<String, Object?>>[];

    for (final task in allTasks) {
      final subtasks = await subtaskRepo.getForTask(task.id);
      allSubtasks.addAll(subtasks.map((s) => s.toMap()));
      final notes = await noteRepo.getForTask(task.id);
      allNotes.addAll(notes.map((n) => n.toMap()));
      final attachments = await attachmentRepo.getForTask(task.id);
      allAttachments.addAll(attachments.map((a) => a.toMap()));
      final tags = await tagRepo.getForTask(task.id);
      for (final tag in tags) {
        allTaskTags.add({'task_id': task.id, 'tag_id': tag.id});
      }
    }

    final payload = {
      'app': 'personal_todo',
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': allTasks.map((t) => t.toMap()).toList(),
      'categories': allCategories.map((c) => c.toMap()).toList(),
      'tags': allTags.map((t) => t.toMap()).toList(),
      'subtasks': allSubtasks,
      'notes': allNotes,
      'attachments': allAttachments,
      'task_tags': allTaskTags,
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
    final tagMaps = (decoded['tags'] as List?) ?? const [];
    final subtaskMaps = (decoded['subtasks'] as List?) ?? const [];
    final noteMaps = (decoded['notes'] as List?) ?? const [];
    final attachmentMaps = (decoded['attachments'] as List?) ?? const [];
    final taskTagMaps = (decoded['task_tags'] as List?) ?? const [];
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
    final importedTags = tagMaps
        .whereType<Map>()
        .map((e) => Tag.fromMap(Map<String, Object?>.from(e)))
        .toList();
    final importedSubtasks = subtaskMaps
        .whereType<Map>()
        .map((e) => Subtask.fromMap(Map<String, Object?>.from(e)))
        .toList();
    final importedNotes = noteMaps
        .whereType<Map>()
        .map((e) => TaskNote.fromMap(Map<String, Object?>.from(e)))
        .toList();
    final importedAttachments = attachmentMaps
        .whereType<Map>()
        .map((e) => Attachment.fromMap(Map<String, Object?>.from(e)))
        .toList();

    await tasks.replaceAll(importedTasks);
    if (importedCategories.isNotEmpty) {
      await categories.replaceAll(importedCategories);
    }

    final tagRepo = TagRepository();
    final subtaskRepo = SubtaskRepository();
    final noteRepo = TaskNoteRepository();
    final attachmentRepo = AttachmentRepository();

    for (final tag in importedTags) {
      await tagRepo.create(tag);
    }
    for (final subtask in importedSubtasks) {
      await subtaskRepo.create(subtask);
    }
    for (final note in importedNotes) {
      await noteRepo.create(note);
    }
    for (final attachment in importedAttachments) {
      await attachmentRepo.create(attachment);
    }
    for (final tt in taskTagMaps) {
      final taskId = tt['task_id'] as String?;
      final tagId = tt['tag_id'] as String?;
      if (taskId != null && tagId != null) {
        await tagRepo.addToTask(taskId, tagId);
      }
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
