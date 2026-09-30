import 'package:flutter/material.dart';
import 'package:personal_todo/core/bs_date.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/task.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.tasks});

  final TaskRepository tasks;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Task>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.tasks.getAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task History')),
      body: FutureBuilder<List<Task>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data ?? [];
          final completed = tasks.where((t) => t.isCompleted).toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          final skipped = tasks
              .where((t) => t.status == TaskStatus.skipped)
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          if (completed.isEmpty && skipped.isEmpty) {
            return const Center(
              child: Text(
                'No history yet.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (completed.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'COMPLETED',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00D4AA),
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ...completed.map((t) => _historyTile(t, 'Completed')),
              ],
              if (skipped.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'SKIPPED',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ...skipped.map((t) => _historyTile(t, 'Skipped')),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _historyTile(Task task, String action) {
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
          Icon(
            action == 'Completed' ? Icons.check_circle : Icons.skip_next,
            color: action == 'Completed'
                ? const Color(0xFF00D4AA)
                : Colors.orange,
            size: 20,
          ),
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
                  '${BsDateHelper.formatTaskDate(task.scheduledAt, mode: DateDisplayMode.bsOnly, withTime: false)} · $action',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
