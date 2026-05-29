class ReportNoteModel {
  const ReportNoteModel({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String authorName;
  final String authorRole;
  final String message;
  final DateTime createdAt;

  factory ReportNoteModel.fromJson(Map<String, dynamic> json) {
    return ReportNoteModel(
      id: json['id'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorRole: json['authorRole'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'authorRole': authorRole,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
