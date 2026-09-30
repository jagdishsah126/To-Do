class Tag {
  const Tag({
    required this.id,
    required this.name,
    this.colorValue = 0xFF00D4AA,
  });

  final String id;
  final String name;
  final int colorValue;

  Tag copyWith({String? name, int? colorValue}) => Tag(
        id: id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'color_value': colorValue,
      };

  factory Tag.fromMap(Map<String, Object?> map) => Tag(
        id: map['id'] as String,
        name: map['name'] as String,
        colorValue: (map['color_value'] as int?) ?? 0xFF00D4AA,
      );
}
