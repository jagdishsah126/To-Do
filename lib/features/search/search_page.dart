import 'package:flutter/material.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/category.dart';
import 'package:personal_todo/domain/task.dart';
import 'package:personal_todo/features/common/task_actions.dart';
import 'package:personal_todo/features/common/task_tile.dart';
import 'package:personal_todo/services/notification_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
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
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  List<Task> _results = [];
  Map<String, Category> _categoryMap = {};

  @override
  void initState() {
    super.initState();
    widget.categories.getAll().then((cats) {
      if (!mounted) return;
      setState(() => _categoryMap = {for (final c in cats) c.id: c});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    final results = await widget.tasks.search(q);
    if (!mounted) return;
    setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search tasks',
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _results.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final task = _results[index];
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
              await _search(_controller.text);
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
              );
              await _search(_controller.text);
              widget.onChanged();
            },
            onDelete: () async {
              await TaskActions.delete(
                tasks: widget.tasks,
                notifications: widget.notifications,
                task: task,
              );
              await _search(_controller.text);
              widget.onChanged();
            },
          );
        },
      ),
    );
  }
}
