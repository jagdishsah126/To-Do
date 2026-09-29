import 'package:flutter/material.dart';
import 'package:personal_todo/core/bs_date.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/category.dart';
import 'package:personal_todo/domain/enums.dart';
import 'package:personal_todo/domain/task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.settings,
    this.category,
    required this.onToggleComplete,
    required this.onOpen,
    required this.onDelete,
  });

  final Task task;
  final AppSettings settings;
  final Category? category;
  final VoidCallback onToggleComplete;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      BsDateHelper.formatTaskDate(
        task.scheduledAt,
        mode: settings.dateDisplay,
        use24Hour: settings.use24HourClock,
      ),
      if (category != null) category!.name,
      if (task.recurrence.isRecurring) task.recurrence.type.label,
      task.priority.label,
    ].join(' · ');

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (_) => onToggleComplete(),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration:
                  task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(subtitle),
          trailing: category == null
              ? null
              : CircleAvatar(
                  radius: 8,
                  backgroundColor: Color(category!.colorValue),
                ),
          onTap: onOpen,
        ),
      ),
    );
  }
}

Future<Duration?> showSnoozeSheet(
  BuildContext context,
  AppSettings settings,
) {
  return showModalBottomSheet<Duration>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final options = settings.snoozeMinutes.isEmpty
          ? const [5, 10, 15, 30, 60]
          : settings.snoozeMinutes;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Snooze')),
            ...options.map(
              (m) => ListTile(
                title: Text(m >= 60 ? '${m ~/ 60} hour' : '$m minutes'),
                onTap: () => Navigator.pop(context, Duration(minutes: m)),
              ),
            ),
            ListTile(
              title: const Text('Tomorrow morning (7:00)'),
              onTap: () {
                final now = DateTime.now();
                final tomorrow = DateTime(now.year, now.month, now.day + 1, 7);
                Navigator.pop(context, tomorrow.difference(now));
              },
            ),
          ],
        ),
      );
    },
  );
}
