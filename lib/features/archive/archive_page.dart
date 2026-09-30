import 'package:flutter/material.dart';
import 'package:personal_todo/core/bs_date.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/enums.dart';
import 'package:personal_todo/domain/task.dart';
import 'package:personal_todo/services/notification_service.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({
    super.key,
    required this.tasks,
    required this.notifications,
  });

  final TaskRepository tasks;
  final NotificationService notifications;

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  late Future<List<Task>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.tasks.getAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archived Tasks')),
      body: FutureBuilder<List<Task>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data ?? [];
          final archived = tasks
              .where((t) => t.status == TaskStatus.cancelled)
              .toList();

          if (archived.isEmpty) {
            return const Center(
              child: Text(
                'No archived tasks.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: archived.map((t) => _archiveTile(t)).toList(),
          );
        },
      ),
    );
  }

  Widget _archiveTile(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.archive, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  BsDateHelper.formatTaskDate(
                    task.scheduledAt,
                    mode: DateDisplayMode.bsOnly,
                    withTime: false,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await widget.tasks.updateTask(
                task.copyWith(status: TaskStatus.upcoming),
              );
              _load();
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}
