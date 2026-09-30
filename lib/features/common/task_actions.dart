import 'package:flutter/material.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/task.dart';
import 'package:personal_todo/features/common/task_tile.dart';
import 'package:personal_todo/features/task_editor/task_editor_page.dart';
import 'package:personal_todo/services/notification_service.dart';

class TaskActions {
  static Future<void> toggleComplete({
    required BuildContext context,
    required TaskRepository tasks,
    required NotificationService notifications,
    required AppSettings settings,
    required Task task,
  }) async {
    if (task.isCompleted) {
      await tasks.markUpcoming(task.id);
      final updated = await tasks.getById(task.id);
      if (updated != null) {
        await notifications.scheduleTaskReminder(updated, settings: settings);
      }
    } else {
      await notifications.cancelTaskReminder(task.id);
      final next = await tasks.complete(task.id);
      if (next != null) {
        await notifications.scheduleTaskReminder(next, settings: settings);
      }
    }
  }

  static Future<void> delete({
    required TaskRepository tasks,
    required NotificationService notifications,
    required Task task,
  }) async {
    await notifications.cancelTaskReminder(task.id);
    await tasks.deleteTask(task.id);
  }

  static Future<void> openSheet({
    required BuildContext context,
    required TaskRepository tasks,
    required CategoryRepository categories,
    required NotificationService notifications,
    required AppSettings settings,
    required Task task,
    VoidCallback? onChanged,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(task.title),
                subtitle: Text(task.description.isEmpty
                    ? 'Task actions'
                    : task.description),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(task.isCompleted ? 'Mark upcoming' : 'Complete'),
                onTap: () async {
                  Navigator.pop(context);
                  await toggleComplete(
                    context: context,
                    tasks: tasks,
                    notifications: notifications,
                    settings: settings,
                    task: task,
                  );
                  onChanged?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.snooze),
                title: const Text('Snooze'),
                onTap: () async {
                  Navigator.pop(context);
                  final duration = await showSnoozeSheet(context, settings);
                  if (duration == null) return;
                  await notifications.cancelTaskReminder(task.id);
                  final updated = await tasks.snooze(task.id, duration);
                  if (updated != null) {
                    await notifications.scheduleTaskReminder(
                      updated,
                      settings: settings,
                    );
                  }
                  onChanged?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.skip_next),
                title: const Text('Skip'),
                onTap: () async {
                  Navigator.pop(context);
                  await notifications.cancelTaskReminder(task.id);
                  final next = await tasks.skip(task.id);
                  if (next != null) {
                    await notifications.scheduleTaskReminder(
                      next,
                      settings: settings,
                    );
                  }
                  onChanged?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Reschedule'),
                onTap: () async {
                  Navigator.pop(context);
                  final date = await showDatePicker(
                    context: context,
                    initialDate: task.scheduledAt,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(task.scheduledAt),
                  );
                  if (time == null) return;
                  final when = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                  await notifications.cancelTaskReminder(task.id);
                  final updated = await tasks.reschedule(task.id, when);
                  if (updated != null) {
                    await notifications.scheduleTaskReminder(
                      updated,
                      settings: settings,
                    );
                  }
                  onChanged?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskEditorPage(
                        tasks: tasks,
                        categories: categories,
                        notifications: notifications,
                        settings: settings,
                        existing: task,
                      ),
                    ),
                  );
                  onChanged?.call();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete,
                    color: Theme.of(context).colorScheme.error),
                title: const Text('Delete'),
                onTap: () async {
                  Navigator.pop(context);
                  await delete(
                    tasks: tasks,
                    notifications: notifications,
                    task: task,
                  );
                  onChanged?.call();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
