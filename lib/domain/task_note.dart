class TaskNote {
  const TaskNote({
    required this.id,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TaskNote copyWith({String? content, DateTime? updatedAt}) => TaskNote(
        id: id,
        content: content ?? this.content,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory TaskNote.fromMap(Map<String, Object?> map) => TaskNote(
        id: map['id'] as String,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : null,
      );
}
