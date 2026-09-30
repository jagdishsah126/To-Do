import 'package:flutter/material.dart';
import 'package:personal_todo/core/bs_date.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/task.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({
    super.key,
    required this.tasks,
    required this.settings,
  });

  final TaskRepository tasks;
  final AppSettings settings;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late Future<List<Task>> _future;
  late Future<int> _streakFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.tasks.getAll();
    _streakFuture = widget.tasks.getStreakCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: FutureBuilder<List<Task>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data ?? [];
          return _buildStats(context, tasks);
        },
      ),
    );
  }

  Widget _buildStats(BuildContext context, List<Task> tasks) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todayTasks = tasks
        .where((t) =>
            !t.scheduledAt.isBefore(todayStart) &&
            t.scheduledAt.isBefore(todayEnd))
        .toList();
    final todayCompleted =
        todayTasks.where((t) => t.isCompleted).length;

    final weekStart = todayStart.subtract(const Duration(days: 7));
    final weekTasks = tasks
        .where((t) =>
            !t.scheduledAt.isBefore(weekStart) &&
            t.scheduledAt.isBefore(todayEnd))
        .toList();
    final weekCompleted = weekTasks.where((t) => t.isCompleted).length;

    final monthStart = DateTime(now.year, now.month, 1);
    final monthTasks = tasks
        .where((t) =>
            !t.scheduledAt.isBefore(monthStart) &&
            t.scheduledAt.isBefore(todayEnd))
        .toList();
    final monthCompleted = monthTasks.where((t) => t.isCompleted).length;

    final totalCompleted = tasks.where((t) => t.isCompleted).length;
    final totalPending = tasks.where((t) => t.isActive).length;
    final totalMissed = tasks
        .where((t) =>
            t.status == TaskStatus.missed ||
            (t.isActive && t.scheduledAt.isBefore(now)))
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.settings.streaksEnabled) ...[
          _sectionTitle('Streaks'),
          FutureBuilder<int>(
            future: _streakFuture,
            builder: (context, snapshot) {
              final streak = snapshot.data ?? 0;
              return _statRow('Current streak', '$streak days');
            },
          ),
          const Divider(),
        ],
        _sectionTitle('Today'),
        _statRow('Total tasks', todayTasks.length),
        _statRow('Completed', todayCompleted),
        _statRow('Remaining', todayTasks.length - todayCompleted),
        const Divider(),
        _sectionTitle('Last 7 days'),
        _statRow('Total tasks', weekTasks.length),
        _statRow('Completed', weekCompleted),
        _statRow('Completion %',
            weekTasks.isEmpty ? 0 : (weekCompleted * 100 / weekTasks.length).round()),
        const Divider(),
        _sectionTitle('This month'),
        _statRow('Total tasks', monthTasks.length),
        _statRow('Completed', monthCompleted),
        _statRow('Completion %',
            monthTasks.isEmpty ? 0 : (monthCompleted * 100 / monthTasks.length).round()),
        const Divider(),
        _sectionTitle('All time'),
        _statRow('Total tasks', tasks.length),
        _statRow('Completed', totalCompleted),
        _statRow('Pending', totalPending),
        _statRow('Missed/Overdue', totalMissed),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Color(0xFF00D4AA),
        ),
      ),
    );
  }

  Widget _statRow(String label, num value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            '$value',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
