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
    if (diff.isNegative) return const Color(0xFFFF4757);
    if (diff.inHours < 1) return const Color(0xFFFF6B35);
    if (diff.inHours < 3) return const Color(0xFFFFD93D);
    return const Color(0xFF00D4AA);
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
        decoration: BoxDecoration(
          color: const Color(0xFFFF4757).withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF4757).withOpacity(0.3)),
        ),
        child: const Icon(Icons.delete, color: Color(0xFFFF4757)),
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Checkbox(
                value: widget.task.isCompleted,
                onChanged: (_) => widget.onToggleComplete(),
                activeColor: const Color(0xFF00D4AA),
                checkColor: Colors.black,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              title: Text(
                widget.task.title,
                style: TextStyle(
                  decoration:
                      widget.task.isCompleted ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: widget.task.isCompleted ? Colors.white38 : Colors.white,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)),
                  ),
                  if (_countdown.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _countdownColor().withOpacity(0.15),
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
                      backgroundColor: Color(widget.category!.colorValue).withOpacity(0.2),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(widget.category!.colorValue),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
              onTap: widget.onOpen,
            ),
          ),
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
    backgroundColor: Colors.transparent,
    builder: (context) {
      final options = settings.snoozeMinutes.isEmpty
          ? const [5, 10, 15, 30, 60]
          : settings.snoozeMinutes;
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Snooze',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              ...options.map(
                (m) => ListTile(
                  title: Text(
                    m >= 60 ? '${m ~/ 60} hour' : '$m minutes',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () => Navigator.pop(context, Duration(minutes: m)),
                ),
              ),
              ListTile(
                title: const Text(
                  'Tomorrow morning (7:00)',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  final now = DateTime.now();
                  final tomorrow = DateTime(now.year, now.month, now.day + 1, 7);
                  Navigator.pop(context, tomorrow.difference(now));
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
