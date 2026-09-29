enum TaskStatus {
  upcoming,
  completed,
  skipped,
  snoozed,
  missed,
  cancelled;

  static TaskStatus fromStorage(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => TaskStatus.upcoming,
    );
  }
}

class Task {
  const Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.scheduledAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime scheduledAt;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCompleted => status == TaskStatus.completed;

  Task copyWith({
    String? title,
    String? description,
    DateTime? scheduledAt,
    TaskStatus? status,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduled_at': scheduledAt.toIso8601String(),
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, Object?> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      status: TaskStatus.fromStorage(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
