class Subtask {
  const Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? createdAt;

  Subtask copyWith({String? title, bool? isCompleted}) => Subtask(
        id: id,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'is_completed': isCompleted ? 1 : 0,
        'created_at': createdAt?.toIso8601String(),
      };

  factory Subtask.fromMap(Map<String, Object?> map) => Subtask(
        id: map['id'] as String,
        title: map['title'] as String,
        isCompleted: (map['is_completed'] as int?) == 1,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : null,
      );
}
