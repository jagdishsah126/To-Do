import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:personal_todo/app.dart';
import 'package:personal_todo/data/app_database.dart';
import 'package:personal_todo/data/backup_service.dart';
import 'package:personal_todo/data/settings_repository.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/services/notification_service.dart';
import 'package:personal_todo/services/warning_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
  };

  try {
    await AppDatabase.instance.database;
  } catch (e, stack) {
    debugPrint('Database init failed: $e');
    debugPrint('Stack: $stack');
    runApp(const _ErrorApp('Database initialization failed.\nPlease reinstall the app.'));
    return;
  }

  final tasks = TaskRepository();
  final categories = CategoryRepository();
  final settingsRepo = SettingsRepository();
  final notifications = NotificationService();
  final backup = BackupService(
    tasks: tasks,
    categories: categories,
    settings: settingsRepo,
  );

  try {
    await notifications.init(
      actionHandler: (actionId, taskId) async {
        try {
          if (taskId == null || taskId.isEmpty) return;
          final settings = await settingsRepo.load();
          switch (actionId) {
            case NotificationService.actionComplete:
              await notifications.cancelTaskReminder(taskId);
              final next = await tasks.complete(taskId);
              if (next != null) {
                await notifications.scheduleTaskReminder(next, settings: settings);
              }
            case NotificationService.actionSnooze:
              await notifications.cancelTaskReminder(taskId);
              final snoozed = await tasks.snooze(taskId, const Duration(minutes: 10));
              if (snoozed != null) {
                await notifications.scheduleTaskReminder(
                  snoozed,
                  settings: settings,
                );
              }
            case NotificationService.actionSkip:
              await notifications.cancelTaskReminder(taskId);
              final next = await tasks.skip(taskId);
              if (next != null) {
                await notifications.scheduleTaskReminder(next, settings: settings);
              }
            default:
              debugPrint('Notification tapped: $taskId');
          }
        } catch (e) {
          debugPrint('Notification action failed: $e');
          await WarningService.instance.logError('NotificationAction', 'Action failed for task $taskId', e);
        }
      },
    );
  } catch (e) {
    debugPrint('Notification init failed: $e');
    await WarningService.instance.logError('Notification', 'Init failed', e);
  }

  try {
    await notifications.requestPermission();
  } catch (e) {
    debugPrint('Notification permission failed: $e');
    await WarningService.instance.logError('Notification', 'Permission request failed', e);
  }

  try {
    final settings = await settingsRepo.load();
    await tasks.applyMissedPolicy(settings.missedPolicy);
    final pending = await tasks.getPendingReminders();
    await notifications.rescheduleAll(pending, settings);

    runApp(
      TodoApp(
        tasks: tasks,
        categories: categories,
        settingsRepo: settingsRepo,
        notifications: notifications,
        backup: backup,
        initialSettings: settings,
      ),
    );
  } catch (e, stack) {
    debugPrint('App init failed: $e');
    debugPrint('Stack: $stack');
    await WarningService.instance.logError('AppInit', 'App initialization failed', e);
    runApp(_ErrorApp('App initialization failed: $e'));
  }
}

class _ErrorApp extends StatelessWidget {
  const _ErrorApp(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
