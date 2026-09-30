class Category {
  const Category({
    required this.id,
    required this.name,
    required this.colorValue,
    this.iconCodePoint = 0xe57f,
  });

  final String id;
  final String name;
  final int colorValue;
  final int iconCodePoint;

  Category copyWith({
    String? name,
    int? colorValue,
    int? iconCodePoint,
  }) =>
      Category(
        id: id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'color_value': colorValue,
        'icon_code_point': iconCodePoint,
      };

  factory Category.fromMap(Map<String, Object?> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
        colorValue: (map['color_value'] as int?) ?? 0xFF1F6F5F,
        iconCodePoint: (map['icon_code_point'] as int?) ?? 0xe57f,
      );
}
