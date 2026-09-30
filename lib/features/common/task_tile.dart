import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_todo/core/bs_date.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/category.dart';
import 'package:personal_todo/domain/enums.dart';
import 'package:personal_todo/domain/task.dart';

class TaskTile extends StatefulWidget {
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
  final Future<void> Function() onDelete;

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  Timer? _timer;
  String _countdown = '';

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateCountdown();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final diff = widget.task.scheduledAt.difference(now);

    if (widget.task.isCompleted) {
      setState(() => _countdown = '');
      return;
    }

    if (diff.isNegative) {
      final abs = -diff;
      if (abs.inHours > 0) {
        setState(() => _countdown = 'Overdue ${abs.inHours}h ${abs.inMinutes % 60}m');
      } else {
        setState(() => _countdown = 'Overdue ${abs.inMinutes}m');
      }
    } else {
      if (diff.inDays > 0) {
        setState(() => _countdown = '${diff.inDays}d ${diff.inHours % 24}h');
      } else if (diff.inHours > 0) {
        setState(() => _countdown = '${diff.inHours}h ${diff.inMinutes % 60}m');
      } else if (diff.inMinutes > 0) {
        setState(() => _countdown = '${diff.inMinutes}m ${diff.inSeconds % 60}s');
      } else {
        setState(() => _countdown = '${diff.inSeconds}s');
      }
    }
  }

  Color _countdownColor() {
    if (widget.task.isCompleted) return Colors.grey;
    final now = DateTime.now();
    final diff = widget.task.scheduledAt.difference(now);
    if (diff.isNegative) return Colors.red;
    if (diff.inHours < 1) return Colors.orange;
    if (diff.inHours < 3) return Colors.amber.shade700;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      BsDateHelper.formatTaskDate(
        widget.task.scheduledAt,
        mode: widget.settings.dateDisplay,
        use24Hour: widget.settings.use24HourClock,
      ),
      if (widget.category != null) widget.category!.name,
      if (widget.task.recurrence.isRecurring) widget.task.recurrence.type.label,
      widget.task.priority.label,
    ].join(' · ');

    return Dismissible(
      key: ValueKey(widget.task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await widget.onDelete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.task.title} deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {},
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Checkbox(
            value: widget.task.isCompleted,
            onChanged: (_) => widget.onToggleComplete(),
            activeColor: const Color(0xFF1F6F5F),
          ),
          title: Text(
            widget.task.title,
            style: TextStyle(
              decoration:
                  widget.task.isCompleted ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              if (_countdown.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _countdownColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _countdownColor().withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: _countdownColor()),
                      const SizedBox(width: 4),
                      Text(
                        _countdown,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _countdownColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          trailing: widget.category == null
              ? null
              : CircleAvatar(
                  radius: 10,
                  backgroundColor: Color(widget.category!.colorValue),
                ),
          onTap: widget.onOpen,
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
