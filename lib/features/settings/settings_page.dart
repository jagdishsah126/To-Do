import 'package:flutter/material.dart';
import 'package:personal_todo/data/backup_service.dart';
import 'package:personal_todo/data/settings_repository.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/category.dart';
import 'package:personal_todo/domain/enums.dart';
import 'package:personal_todo/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settingsRepo,
    required this.notifications,
    required this.backup,
    required this.tasks,
    required this.categories,
    required this.settings,
    required this.onSettingsChanged,
  });

  final SettingsRepository settingsRepo;
  final NotificationService notifications;
  final BackupService backup;
  final TaskRepository tasks;
  final CategoryRepository categories;
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppSettings _settings;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await widget.categories.getAll();
    if (mounted) setState(() => _categories = cats);
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _settings = widget.settings;
  }

  Future<void> _save(AppSettings next) async {
    final notificationSettingsChanged = 
        next.notificationsEnabled != _settings.notificationsEnabled ||
        next.quietHoursEnabled != _settings.quietHoursEnabled ||
        next.quietStartMinute != _settings.quietStartMinute ||
        next.quietEndMinute != _settings.quietEndMinute;
    
    setState(() => _settings = next);
    await widget.settingsRepo.save(next);
    widget.onSettingsChanged(next);
    
    if (notificationSettingsChanged) {
      final pending = await widget.tasks.getPendingReminders();
      await widget.notifications.rescheduleAll(pending, next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(title: Text('Appearance')),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_settings.theme.name),
            onTap: () async {
              final value = await _pickEnum<ThemePreference>(
                title: 'Theme',
                values: ThemePreference.values,
                labelOf: (e) => e.name,
                current: _settings.theme,
              );
              if (value != null) await _save(_settings.copyWith(theme: value));
            },
          ),
          SwitchListTile(
            title: const Text('24-hour clock'),
            value: _settings.use24HourClock,
            onChanged: (v) => _save(_settings.copyWith(use24HourClock: v)),
          ),
          ListTile(
            title: const Text('Accent color'),
            subtitle: Text(_accentColorName(_settings.accentColor)),
            trailing: CircleAvatar(
              radius: 14,
              backgroundColor: Color(_settings.accentColor),
            ),
            onTap: () async {
              final colors = [0xFF00D4AA, 0xFF6C63FF, 0xFFFF6B6B, 0xFF4ECDC4, 0xFFFFE66D, 0xFFA8E6CF];
              final value = await showDialog<int>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Accent color'),
                  content: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: colors.map((c) => InkWell(
                      onTap: () => Navigator.pop(context, c),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(c),
                        child: _settings.accentColor == c
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    )).toList(),
                  ),
                ),
              );
              if (value != null) {
                await _save(_settings.copyWith(accentColor: value));
              }
            },
          ),
          const Divider(),
          const ListTile(title: Text('Calendar')),
          ListTile(
            title: const Text('Date display'),
            subtitle: Text(_settings.dateDisplay.name),
            onTap: () async {
              final value = await _pickEnum<DateDisplayMode>(
                title: 'Date display',
                values: DateDisplayMode.values,
                labelOf: (e) => e.name,
                current: _settings.dateDisplay,
              );
              if (value != null) {
                await _save(_settings.copyWith(dateDisplay: value));
              }
            },
          ),
          const Divider(),
          const ListTile(title: Text('Notifications')),
          SwitchListTile(
            title: const Text('Task notifications'),
            value: _settings.notificationsEnabled,
            onChanged: (v) =>
                _save(_settings.copyWith(notificationsEnabled: v)),
          ),
          ListTile(
            title: const Text('Default reminder'),
            subtitle: Text(
              _settings.defaultReminderMinutes == 0
                  ? 'At task time'
                  : '${_settings.defaultReminderMinutes} minutes before',
            ),
            onTap: () async {
              final options = {0: 'At task time', 5: '5 min', 10: '10 min', 15: '15 min', 30: '30 min', 60: '1 hour'};
              final value = await showDialog<int>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Default reminder'),
                  children: options.entries
                      .map(
                        (e) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, e.key),
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                ),
              );
              if (value != null) {
                await _save(_settings.copyWith(defaultReminderMinutes: value));
              }
            },
          ),
          SwitchListTile(
            title: const Text('Quiet hours'),
            subtitle: Text(
              '${_fmtMinute(_settings.quietStartMinute)} → ${_fmtMinute(_settings.quietEndMinute)}',
            ),
            value: _settings.quietHoursEnabled,
            onChanged: (v) =>
                _save(_settings.copyWith(quietHoursEnabled: v)),
          ),
          if (_settings.quietHoursEnabled) ...[
            ListTile(
              title: const Text('Quiet start'),
              subtitle: Text(_fmtMinute(_settings.quietStartMinute)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: _settings.quietStartMinute ~/ 60,
                    minute: _settings.quietStartMinute % 60,
                  ),
                );
                if (picked != null) {
                  final minutes = picked.hour * 60 + picked.minute;
                  await _save(_settings.copyWith(quietStartMinute: minutes));
                }
              },
            ),
            ListTile(
              title: const Text('Quiet end'),
              subtitle: Text(_fmtMinute(_settings.quietEndMinute)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: _settings.quietEndMinute ~/ 60,
                    minute: _settings.quietEndMinute % 60,
                  ),
                );
                if (picked != null) {
                  final minutes = picked.hour * 60 + picked.minute;
                  await _save(_settings.copyWith(quietEndMinute: minutes));
                }
              },
            ),
          ],
          ListTile(
            title: const Text('Missed task policy'),
            subtitle: Text(_settings.missedPolicy.name),
            onTap: () async {
              final value = await _pickEnum<MissedTaskPolicy>(
                title: 'Missed tasks',
                values: MissedTaskPolicy.values,
                labelOf: (e) => e.name,
                current: _settings.missedPolicy,
              );
              if (value != null) {
                await _save(_settings.copyWith(missedPolicy: value));
              }
            },
          ),
          ListTile(
            title: const Text('Snooze options'),
            subtitle: Text(_settings.snoozeMinutes.join(', ')),
            onTap: () async {
              final controller = TextEditingController(
                text: _settings.snoozeMinutes.join(','),
              );
              final result = await showDialog<List<int>>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Snooze options (minutes)'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 5,10,15,30,60',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final values = controller.text
                            .split(',')
                            .map((e) => int.tryParse(e.trim()) ?? 0)
                            .where((e) => e > 0 && e <= 1440)
                            .toList();
                        Navigator.pop(context, values);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              controller.dispose();
              if (result != null && result.isNotEmpty) {
                await _save(_settings.copyWith(snoozeMinutes: result));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Test notification (10s)'),
            onTap: () async {
              await widget.notifications.requestPermission();
              await widget.notifications.scheduleTestNotification();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scheduled. Lock phone now.')),
              );
            },
          ),
          const Divider(),
          const ListTile(title: Text('Categories')),
          ..._categories.map(
            (c) => ListTile(
              title: Text(c.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _editCategory(c),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _deleteCategory(c),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add category'),
            onTap: _addCategory,
          ),
          const Divider(),
          const ListTile(title: Text('Data')),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export backup'),
            onTap: () async {
              try {
                await widget.backup.exportToFile();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export failed: $e')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import backup'),
            onTap: () async {
              try {
                final count = await widget.backup.importFromPicker();
                final pending = await widget.tasks.getPendingReminders();
                await widget.notifications.rescheduleAll(pending, _settings);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Imported $count tasks')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Import failed: $e')),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever,
                color: Theme.of(context).colorScheme.error),
            title: const Text('Delete all tasks'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete all application data?'),
                  content: const Text(
                    'This cannot be undone unless you have a backup.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete Everything'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                final all = await widget.tasks.getAll();
                for (final t in all) {
                  await widget.notifications.cancelTaskReminder(t.id);
                }
                await widget.tasks.deleteAll();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All tasks deleted')),
                );
              }
            },
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Personal Todo · Offline first · BS calendar · Local reminders',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtMinute(int minuteOfDay) {
    final h = minuteOfDay ~/ 60;
    final m = minuteOfDay % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _accentColorName(int color) {
    return switch (color) {
      0xFF00D4AA => 'Teal',
      0xFF6C63FF => 'Purple',
      0xFFFF6B6B => 'Red',
      0xFF4ECDC4 => 'Cyan',
      0xFFFFE66D => 'Yellow',
      0xFFA8E6CF => 'Mint',
      _ => 'Custom',
    };
  }

  Future<T?> _pickEnum<T>({
    required String title,
    required List<T> values,
    required String Function(T) labelOf,
    required T current,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: values
            .map(
              (v) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, v),
                child: Row(
                  children: [
                    if (v == current) const Icon(Icons.check, size: 18),
                    if (v == current) const SizedBox(width: 8),
                    Text(labelOf(v)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _addCategory() async {
    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result == true && nameController.text.trim().isNotEmpty) {
      final category = Category(
        id: const Uuid().v4(),
        name: nameController.text.trim(),
        colorValue: 0xFF1F6F5F,
      );
      await widget.categories.create(category);
      await _loadCategories();
    }
    nameController.dispose();
  }

  Future<void> _editCategory(Category category) async {
    final nameController = TextEditingController(text: category.name);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true && nameController.text.trim().isNotEmpty) {
      await widget.categories.update(
        category.copyWith(name: nameController.text.trim()),
      );
      await _loadCategories();
    }
    nameController.dispose();
  }

  Future<void> _deleteCategory(Category category) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (result == true) {
      await widget.categories.delete(category.id);
      await _loadCategories();
    }
  }
}
