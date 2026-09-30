import 'package:flutter/material.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/category.dart';
import 'package:personal_todo/domain/task.dart';
import 'package:personal_todo/features/common/task_actions.dart';
import 'package:personal_todo/features/common/task_tile.dart';
import 'package:personal_todo/features/task_editor/task_editor_page.dart';
import 'package:personal_todo/services/notification_service.dart';

class UpcomingPage extends StatefulWidget {
  const UpcomingPage({
    super.key,
    required this.tasks,
    required this.categories,
    required this.notifications,
    required this.settings,
    required this.onChanged,
  });

  final TaskRepository tasks;
  final CategoryRepository categories;
  final NotificationService notifications;
  final AppSettings settings;
  final VoidCallback onChanged;

  @override
  State<UpcomingPage> createState() => _UpcomingPageState();
}

class _UpcomingPageState extends State<UpcomingPage> {
  int _days = 7;
  late Future<List<Task>> _future;
  Map<String, Category> _categoryMap = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final cats = await widget.categories.getAll();
    setState(() {
      _categoryMap = {for (final c in cats) c.id: c};
      _future = widget.tasks.getUpcoming(days: _days);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _days,
            onSelected: (v) {
              _days = v;
              _reload();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 1, child: Text('Tomorrow')),
              PopupMenuItem(value: 7, child: Text('Next 7 days')),
              PopupMenuItem(value: 30, child: Text('Next 30 days')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return const Center(child: Text('No upcoming tasks.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskTile(
                task: task,
                settings: widget.settings,
                category: task.categoryId == null
                    ? null
                    : _categoryMap[task.categoryId!],
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
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
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
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}
