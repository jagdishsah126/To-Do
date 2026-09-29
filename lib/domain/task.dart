import 'package:personal_todo/domain/enums.dart';
import 'package:personal_todo/domain/recurrence.dart';

class Task {
  const Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.scheduledAt,
    required this.status,
    this.priority = TaskPriority.normal,
    this.categoryId,
    this.recurrence = const RecurrenceRule(),
    this.reminderMinutesBefore = 0,
    this.seriesId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime scheduledAt;
  final TaskStatus status;
  final TaskPriority priority;
  final String? categoryId;
  final RecurrenceRule recurrence;
  final int reminderMinutesBefore;
  final String? seriesId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCompleted => status == TaskStatus.completed;
  bool get isActive =>
      status == TaskStatus.upcoming ||
      status == TaskStatus.snoozed ||
      status == TaskStatus.missed;

  DateTime get reminderAt =>
      scheduledAt.subtract(Duration(minutes: reminderMinutesBefore));

  Task copyWith({
    String? title,
    String? description,
    DateTime? scheduledAt,
    TaskStatus? status,
    TaskPriority? priority,
    String? categoryId,
    bool clearCategory = false,
    RecurrenceRule? recurrence,
    int? reminderMinutesBefore,
    String? seriesId,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      recurrence: recurrence ?? this.recurrence,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      seriesId: seriesId ?? this.seriesId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'scheduled_at': scheduledAt.toIso8601String(),
        'status': status.name,
        'priority': priority.name,
        'category_id': categoryId,
        'recurrence_type': recurrence.type.name,
        'recurrence_weekdays': recurrence.weekdays.join(','),
        'recurrence_interval': recurrence.interval,
        'reminder_minutes_before': reminderMinutesBefore,
        'series_id': seriesId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Task.fromMap(Map<String, Object?> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      status: TaskStatus.fromStorage(map['status'] as String),
      priority: TaskPriority.fromStorage((map['priority'] as String?) ?? 'normal'),
      categoryId: map['category_id'] as String?,
      recurrence: RecurrenceRule(
        type: RecurrenceType.fromStorage(
          (map['recurrence_type'] as String?) ?? 'none',
        ),
        weekdays: _parseDays(map['recurrence_weekdays'] as String?),
        interval: (map['recurrence_interval'] as int?) ?? 1,
      ),
      reminderMinutesBefore: (map['reminder_minutes_before'] as int?) ?? 0,
      seriesId: map['series_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static List<int> _parseDays(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((e) => e >= 1 && e <= 7)
        .toList();
  }
}
