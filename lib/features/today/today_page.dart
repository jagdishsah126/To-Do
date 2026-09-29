import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/task.dart';
import 'package:personal_todo/features/task_editor/task_editor_page.dart';
import 'package:personal_todo/services/notification_service.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({
    super.key,
    required this.repository,
    required this.notifications,
  });

  final TaskRepository repository;
  final NotificationService notifications;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  late Future<List<Task>> _tasksFuture;
  final _timeFormat = DateFormat('h:mm a');
  final _dateFormat = DateFormat('EEE, d MMM yyyy');

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _tasksFuture = widget.repository.getTasksForDay(DateTime.now());
    });
  }

  Future<void> _openEditor() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TaskEditorPage(
          repository: widget.repository,
          notifications: widget.notifications,
        ),
      ),
    );

    if (created == true && mounted) {
      _reload();
    }
  }

  Future<void> _toggleComplete(Task task) async {
    if (task.isCompleted) {
      await widget.repository.markUpcoming(task.id);
      await widget.notifications.scheduleTaskReminder(
        task.copyWith(status: TaskStatus.upcoming),
      );
    } else {
      await widget.repository.markCompleted(task.id);
      await widget.notifications.cancelTaskReminder(task.id);
    }
    _reload();
  }

  Future<void> _deleteTask(Task task) async {
    await widget.notifications.cancelTaskReminder(task.id);
    await widget.repository.deleteTask(task.id);
    _reload();
  }

  Future<void> _testNotification() async {
    final allowed = await widget.notifications.requestPermission();
    if (!mounted) return;

    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notification permission denied. Enable it in phone settings.',
          ),
        ),
      );
      return;
    }

    await widget.notifications.scheduleTestNotification(seconds: 10);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification scheduled in 10 seconds. Lock phone or leave app.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayLabel = _dateFormat.format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            tooltip: 'Test notification (10s)',
            onPressed: _testNotification,
            icon: const Icon(Icons.notifications_active_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              todayLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Task>>(
              future: _tasksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load tasks.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final tasks = snapshot.data ?? const <Task>[];
                if (tasks.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No tasks for today.\nTap + to add one.\n\nUse the bell icon to test notifications.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                  itemCount: tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Dismissible(
                      key: ValueKey(task.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Theme.of(context).colorScheme.error,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteTask(task),
                      child: Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (_) => _toggleComplete(task),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          subtitle: Text(
                            [
                              _timeFormat.format(task.scheduledAt),
                              if (task.description.isNotEmpty) task.description,
                            ].join(' · '),
                          ),
                          onTap: () => _toggleComplete(task),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}
