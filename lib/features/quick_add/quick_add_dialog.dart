import 'package:flutter/material.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/enums.dart';
import 'package:personal_todo/services/notification_service.dart';

Future<void> showQuickAddDialog({
  required BuildContext context,
  required TaskRepository tasks,
  required NotificationService notifications,
  required AppSettings settings,
  required VoidCallback onChanged,
}) async {
  final titleController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Quick Add Task'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  hintText: 'What needs to be done?',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Time'),
                      subtitle: Text(selectedTime.format(context)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setState(() => selectedTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final scheduledAt = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );
              if (scheduledAt.isBefore(DateTime.now())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cannot schedule in the past')),
                );
                return;
              }
              final task = await tasks.createTask(
                title: titleController.text,
                scheduledAt: scheduledAt,
                reminderMinutesBefore: settings.defaultReminderMinutes,
              );
              await notifications.scheduleTaskReminder(task, settings: settings);
              if (context.mounted) Navigator.pop(context);
              onChanged();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
}
