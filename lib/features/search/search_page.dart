import 'package:flutter/material.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/category.dart';
import 'package:personal_todo/domain/enums.dart';
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
  String _statusFilter = 'all';
  String _priorityFilter = 'all';
  String _sortBy = 'date';

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
    var results = await widget.tasks.search(q);
    if (!mounted) return;

    if (_statusFilter != 'all') {
      results = results.where((t) => t.status.name == _statusFilter).toList();
    }
    if (_priorityFilter != 'all') {
      results = results.where((t) => t.priority.name == _priorityFilter).toList();
    }

    switch (_sortBy) {
      case 'date':
        results.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      case 'priority':
        results.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      case 'title':
        results.sort((a, b) => a.title.compareTo(b.title));
    }

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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) {
              setState(() => _sortBy = v);
              _search(_controller.text);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'date', child: Text('Sort by date')),
              PopupMenuItem(value: 'priority', child: Text('Sort by priority')),
              PopupMenuItem(value: 'title', child: Text('Sort by title')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A1F2E),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All statuses')),
                      DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'snoozed', child: Text('Snoozed')),
                      DropdownMenuItem(value: 'skipped', child: Text('Skipped')),
                      DropdownMenuItem(value: 'missed', child: Text('Missed')),
                    ],
                    onChanged: (v) {
                      setState(() => _statusFilter = v ?? 'all');
                      _search(_controller.text);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _priorityFilter,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A1F2E),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All priorities')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'normal', child: Text('Normal')),
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                    ],
                    onChanged: (v) {
                      setState(() => _priorityFilter = v ?? 'all');
                      _search(_controller.text);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
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
                      onChanged: () => _search(_controller.text),
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
          ),
        ],
      ),
    );
  }
}
