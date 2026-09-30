import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:personal_todo/app.dart';
import 'package:personal_todo/data/app_database.dart';
import 'package:personal_todo/data/backup_service.dart';
import 'package:personal_todo/data/settings_repository.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppDatabase.instance.database;

  final tasks = TaskRepository();
  final categories = CategoryRepository();
  final settingsRepo = SettingsRepository();
  final notifications = NotificationService();
  final backup = BackupService(
    tasks: tasks,
    categories: categories,
    settings: settingsRepo,
  );

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
        }
      } catch (e) {
        debugPrint('Notification action failed: $e');
      }
    },
  );
  await notifications.requestPermission();

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
}
