import 'package:flutter/material.dart';
import 'package:personal_todo/core/bs_date.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/category.dart';
import 'package:personal_todo/domain/task.dart';
import 'package:personal_todo/features/common/task_actions.dart';
import 'package:personal_todo/features/common/task_tile.dart';
import 'package:personal_todo/features/task_editor/task_editor_page.dart';
import 'package:personal_todo/services/notification_service.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({
    super.key,
    required this.tasks,
    required this.categories,
    required this.notifications,
    required this.settings,
    required this.onChanged,
    this.onOpenSearch,
  });

  final TaskRepository tasks;
  final CategoryRepository categories;
  final NotificationService notifications;
  final AppSettings settings;
  final VoidCallback onChanged;
  final VoidCallback? onOpenSearch;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  late Future<List<Task>> _future;
  Map<String, Category> _categoryMap = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _refresh() => setState(() {});

  Future<void> _reload() async {
    final cats = await widget.categories.getAll();
    await widget.tasks.applyMissedPolicy(widget.settings.missedPolicy);
    setState(() {
      _categoryMap = {for (final c in cats) c.id: c};
      _future = widget.tasks.getTasksForDay(DateTime.now());
    });
  }

  Future<void> _add() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskEditorPage(
          tasks: widget.tasks,
          categories: widget.categories,
          notifications: widget.notifications,
          settings: widget.settings,
        ),
      ),
    );
    if (ok == true) {
      await _reload();
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = BsDateHelper.formatTaskDate(
      DateTime.now(),
      mode: widget.settings.dateDisplay,
      withTime: false,
      use24Hour: widget.settings.use24HourClock,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          if (widget.onOpenSearch != null)
            IconButton(
              tooltip: 'Search',
              onPressed: widget.onOpenSearch,
              icon: const Icon(Icons.search),
            ),
          IconButton(
            tooltip: 'Test notification',
            onPressed: () async {
              await widget.notifications.requestPermission();
              await widget.notifications.scheduleTestNotification();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test notification in 10 seconds. Lock phone now.'),
                ),
              );
            },
            icon: const Icon(Icons.notifications_active_outlined),
          ),
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: FutureBuilder<List<Task>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = snapshot.data ?? [];
                if (tasks.isEmpty) {
                  return const Center(child: Text('No tasks for today.'));
                }
                final overdue = tasks
                    .where(
                      (t) =>
                          t.isActive && t.scheduledAt.isBefore(DateTime.now()),
                    )
                    .toList();
                final remaining = tasks
                    .where(
                      (t) =>
                          t.isActive && !t.scheduledAt.isBefore(DateTime.now()),
                    )
                    .toList();
                final done = tasks.where((t) => t.isCompleted).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                  children: [
                    if (overdue.isNotEmpty) ...[
                      const Text('OVERDUE',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...overdue.map((t) => _tile(t)),
                      const SizedBox(height: 12),
                    ],
                    if (remaining.isNotEmpty) ...[
                      const Text('TODAY',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...remaining.map((t) => _tile(t)),
                      const SizedBox(height: 12),
                    ],
                    if (done.isNotEmpty) ...[
                      const Text('COMPLETED',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...done.map((t) => _tile(t)),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _tile(Task task) {
    return TaskTile(
      task: task,
      settings: widget.settings,
      category:
          task.categoryId == null ? null : _categoryMap[task.categoryId!],
      onToggleComplete: () async {
        await TaskActions.toggleComplete(
          context: context,
          tasks: widget.tasks,
          notifications: widget.notifications,
          settings: widget.settings,
          task: task,
        );
        await _reload();
        widget.onChanged();
      },
      onOpen: () async {
        await TaskActions.openSheet(
          context: context,
          tasks: widget.tasks,
          categories: widget.categories,
          notifications: widget.notifications,
          settings: widget.settings,
          task: task,
          onChanged: _refresh,
        );
        await _reload();
        widget.onChanged();
      },
      onDelete: () async {
        await TaskActions.delete(
          tasks: widget.tasks,
          notifications: widget.notifications,
          task: task,
        );
        await _reload();
        widget.onChanged();
      },
    );
  }
}
