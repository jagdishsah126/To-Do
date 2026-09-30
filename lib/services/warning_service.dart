import 'dart:io';

import 'package:path_provider/path_provider.dart';

class WarningService {
  WarningService._();
  static final WarningService instance = WarningService._();

  static const _fileName = 'warnings.log';
  bool _initialized = false;
  File? _file;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/$_fileName');
      _initialized = true;
    } catch (e) {
      // Cannot init warning service
    }
  }

  Future<void> log(String source, String message, [Object? error]) async {
    try {
      await init();
      final file = _file;
      if (file == null) return;

      final timestamp = DateTime.now().toIso8601String();
      final errorStr = error != null ? ' | Error: $error' : '';
      final line = '[$timestamp] [$source] $message$errorStr\n';

      await file.writeAsString(line, mode: FileMode.append);
    } catch (e) {
      // Silently fail - warning logging should never crash the app
    }
  }

  Future<void> logWarning(String source, String message, [Object? error]) =>
      log(source, 'WARNING: $message', error);

  Future<void> logError(String source, String message, [Object? error]) =>
      log(source, 'ERROR: $message', error);

  Future<String> readAll() async {
    try {
      await init();
      final file = _file;
      if (file == null) return 'Warning service not initialized.';
      if (!await file.exists()) return 'No warnings logged yet.';
      return await file.readAsString();
    } catch (e) {
      return 'Failed to read warnings: $e';
    }
  }

  Future<void> clear() async {
    try {
      await init();
      final file = _file;
      if (file == null) return;
      if (await file.exists()) {
        await file.delete();
      }
      _initialized = false;
      _file = null;
    } catch (e) {
      // Silently fail
    }
  }

  Future<int> getWarningCount() async {
    try {
      final content = await readAll();
      if (content.isEmpty || content == 'No warnings logged yet.') return 0;
      return content.split('\n').where((l) => l.isNotEmpty).length;
    } catch (e) {
      return 0;
    }
  }
}
