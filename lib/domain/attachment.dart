class Attachment {
  const Attachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.mimeType,
    required this.createdAt,
  });

  final String id;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String mimeType;
  final DateTime createdAt;

  Attachment copyWith({String? fileName, String? filePath}) => Attachment(
        id: id,
        fileName: fileName ?? this.fileName,
        filePath: filePath ?? this.filePath,
        fileSize: fileSize,
        mimeType: mimeType,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'file_name': fileName,
        'file_path': filePath,
        'file_size': fileSize,
        'mime_type': mimeType,
        'created_at': createdAt.toIso8601String(),
      };

  factory Attachment.fromMap(Map<String, Object?> map) => Attachment(
        id: map['id'] as String,
        fileName: map['file_name'] as String,
        filePath: map['file_path'] as String,
        fileSize: (map['file_size'] as int?) ?? 0,
        mimeType: (map['mime_type'] as String?) ?? '',
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
