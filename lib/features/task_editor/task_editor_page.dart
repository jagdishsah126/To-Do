import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:personal_todo/core/bs_date.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/category.dart';
import 'package:personal_todo/domain/enums.dart';
import 'package:personal_todo/domain/recurrence.dart';
import 'package:personal_todo/domain/task.dart';
import 'package:personal_todo/services/notification_service.dart';
import 'package:personal_todo/services/warning_service.dart';

class TaskEditorPage extends StatefulWidget {
  const TaskEditorPage({
    super.key,
    required this.tasks,
    required this.categories,
    required this.notifications,
    required this.settings,
    this.existing,
    this.initialDate,
  });

  final TaskRepository tasks;
  final CategoryRepository categories;
  final NotificationService notifications;
  final AppSettings settings;
  final Task? existing;
  final DateTime? initialDate;

  @override
  State<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends State<TaskEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _date;
  late TimeOfDay _time;
  TaskPriority _priority = TaskPriority.normal;
  RecurrenceType _recurrenceType = RecurrenceType.none;
  final Set<int> _weekdays = {};
  int _recurrenceInterval = 1;
  int _reminderMinutes = 0;
  String? _categoryId;
  List<Category> _categories = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final base = existing?.scheduledAt ??
        widget.initialDate ??
        DateTime.now().add(const Duration(minutes: 2));
    _date = DateTime(base.year, base.month, base.day);
    _time = TimeOfDay(hour: base.hour, minute: base.minute);
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description;
      _priority = existing.priority;
      _recurrenceType = existing.recurrence.type;
      _weekdays.addAll(existing.recurrence.weekdays);
      _recurrenceInterval = existing.recurrence.interval;
      _reminderMinutes = existing.reminderMinutesBefore;
      _categoryId = existing.categoryId;
    } else {
      _reminderMinutes = widget.settings.defaultReminderMinutes;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final list = await widget.categories.getAll();
    if (!mounted) return;
    setState(() => _categories = list);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime get _scheduledAt => DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );

  Future<void> _pickDate() async {
    // Pick in AD picker, display as BS via helper text.
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select date (stored AD, shown BS)',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  RecurrenceRule get _rule => RecurrenceRule(
        type: _recurrenceType,
        weekdays: _weekdays.toList()..sort(),
        interval: _recurrenceInterval,
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recurrenceType == RecurrenceType.selectedWeekdays &&
        _weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one weekday.')),
      );
      return;
    }
    if (_scheduledAt.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot schedule tasks in the past.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.notifications.requestPermission();
      late Task task;
      if (widget.existing == null) {
        task = await widget.tasks.createTask(
          title: _titleController.text,
          description: _descriptionController.text,
          scheduledAt: _scheduledAt,
          priority: _priority,
          categoryId: _categoryId,
          recurrence: _rule,
          reminderMinutesBefore: _reminderMinutes,
        );
      } else {
        task = await widget.tasks.updateTask(
          widget.existing!.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            scheduledAt: _scheduledAt,
            priority: _priority,
            categoryId: _categoryId,
            clearCategory: _categoryId == null,
            recurrence: _rule,
            reminderMinutesBefore: _reminderMinutes,
          ),
        );
        await widget.notifications.cancelTaskReminder(task.id);
      }

      await widget.notifications.scheduleTaskReminder(
        task,
        settings: widget.settings,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      await WarningService.instance.logError('TaskEditor', 'Failed to save task', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bsLabel = BsDateHelper.formatTaskDate(
      _scheduledAt,
      mode: widget.settings.dateDisplay,
      use24Hour: widget.settings.use24HourClock,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New Task' : 'Edit Task'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(bsLabel),
                trailing: const Icon(Icons.edit_calendar),
                onTap: () async {
                  await _pickDate();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Time'),
                subtitle: Text(_time.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  await _pickTime();
                },
              ),
              Text(
                'BS: ${BsDateHelper.formatBs(NepaliDateTime.fromDateTime(_date))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskPriority>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: TaskPriority.values
                    .map(
                      (p) => DropdownMenuItem(value: p, child: Text(p.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ..._categories.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RecurrenceType>(
                value: _recurrenceType,
                decoration: const InputDecoration(labelText: 'Recurrence'),
                items: RecurrenceType.values
                    .map(
                      (r) => DropdownMenuItem(value: r, child: Text(r.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _recurrenceType = v!),
              ),
              if (_recurrenceType != RecurrenceType.none) ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '$_recurrenceInterval',
                  decoration: const InputDecoration(labelText: 'Every (interval)'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 1) return 'Must be at least 1';
                    return null;
                  },
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null && n > 0) _recurrenceInterval = n;
                  },
                ),
              ],
              if (_recurrenceType == RecurrenceType.selectedWeekdays) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final day in [1, 2, 3, 4, 5, 6, 7])
                      FilterChip(
                        label: Text(const [
                          '',
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ][day]),
                        selected: _weekdays.contains(day),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _weekdays.add(day);
                            } else {
                              _weekdays.remove(day);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _reminderMinutes,
                decoration: const InputDecoration(labelText: 'Reminder'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('At task time')),
                  DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                  DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                  DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                  DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                  DropdownMenuItem(value: 60, child: Text('1 hour before')),
                ],
                onChanged: (v) => setState(() => _reminderMinutes = v ?? 0),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(_saving ? 'Saving...' : 'Save Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
