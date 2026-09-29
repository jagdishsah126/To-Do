import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:personal_todo/core/bs_date.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/category.dart';
import 'package:personal_todo/domain/task.dart';
import 'package:personal_todo/features/common/task_actions.dart';
import 'package:personal_todo/features/common/task_tile.dart';
import 'package:personal_todo/features/task_editor/task_editor_page.dart';
import 'package:personal_todo/services/notification_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({
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
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late NepaliDateTime _month;
  NepaliDateTime? _selected;
  List<Task> _monthTasks = [];
  Map<String, Category> _categoryMap = {};

  @override
  void initState() {
    super.initState();
    _month = NepaliDateTime.now();
    _selected = NepaliDateTime.now();
    _load();
  }

  Future<void> _load() async {
    final cats = await widget.categories.getAll();
    final first = NepaliDateTime(_month.year, _month.month, 1);
    final daysInMonth = BsDateHelper.daysInMonth(_month.year, _month.month);
    final startAd = first.toDateTime();
    final endAd = NepaliDateTime(_month.year, _month.month, daysInMonth)
        .toDateTime()
        .add(const Duration(days: 1));
    final tasks = await widget.tasks.getTasksBetween(startAd, endAd);
    if (!mounted) return;
    setState(() {
      _categoryMap = {for (final c in cats) c.id: c};
      _monthTasks = tasks;
    });
  }

  List<Task> get _selectedTasks {
    final selected = _selected;
    if (selected == null) return const [];
    final dayStart = selected.toDateTime();
    final dayEnd = dayStart.add(const Duration(days: 1));
    return _monthTasks
        .where(
          (t) =>
              !t.scheduledAt.isBefore(dayStart) &&
              t.scheduledAt.isBefore(dayEnd),
        )
        .toList();
  }

  int _countForDay(int day) {
    final bs = NepaliDateTime(_month.year, _month.month, day);
    final start = bs.toDateTime();
    final end = start.add(const Duration(days: 1));
    return _monthTasks
        .where(
          (t) => !t.scheduledAt.isBefore(start) && t.scheduledAt.isBefore(end),
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final first = NepaliDateTime(_month.year, _month.month, 1);
    final daysInMonth = BsDateHelper.daysInMonth(_month.year, _month.month);
    final blanks = first.weekday - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(BsDateHelper.monthTitle(_month)),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _month = NepaliDateTime(_month.year, _month.month - 1, 1);
              });
              _load();
            },
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _month = NepaliDateTime.now();
                _selected = NepaliDateTime.now();
              });
              _load();
            },
            icon: const Icon(Icons.today),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _month = NepaliDateTime(_month.year, _month.month + 1, 1);
              });
              _load();
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(child: Center(child: Text('Mon'))),
                Expanded(child: Center(child: Text('Tue'))),
                Expanded(child: Center(child: Text('Wed'))),
                Expanded(child: Center(child: Text('Thu'))),
                Expanded(child: Center(child: Text('Fri'))),
                Expanded(child: Center(child: Text('Sat'))),
                Expanded(child: Center(child: Text('Sun'))),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: blanks + daysInMonth,
            itemBuilder: (context, index) {
              if (index < blanks) return const SizedBox.shrink();
              final day = index - blanks + 1;
              final count = _countForDay(day);
              final isSelected = _selected?.day == day &&
                  _selected?.month == _month.month &&
                  _selected?.year == _month.year;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selected = NepaliDateTime(_month.year, _month.month, day);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$day'),
                      if (count > 0)
                        Text(
                          '$count',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
              children: [
                if (_selectedTasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No tasks on this day.')),
                  )
                else
                  ..._selectedTasks.map(
                    (task) => TaskTile(
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
                        await _load();
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
                        await _load();
                        widget.onChanged();
                      },
                      onDelete: () async {
                        await TaskActions.delete(
                          tasks: widget.tasks,
                          notifications: widget.notifications,
                          task: task,
                        );
                        await _load();
                        widget.onChanged();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final initial = (_selected ?? NepaliDateTime.now()).toDateTime();
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => TaskEditorPage(
                tasks: widget.tasks,
                categories: widget.categories,
                notifications: widget.notifications,
                settings: widget.settings,
                initialDate: initial,
              ),
            ),
          );
          if (ok == true) {
            await _load();
            widget.onChanged();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}
