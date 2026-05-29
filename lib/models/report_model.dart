import 'report_note_model.dart';

class ReportModel {
  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reporterRole,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.isValidatedByTeacher,
    required this.notes,
    this.imagePath,
    this.resolvedImagePath,
    this.assignedTo,
    this.isOfflineQueued = false,
  });

  final String id;
  final String reporterId;
  final String reporterName;
  final String reporterRole;
  final String title;
  final String description;
  final String category;
  final String location;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imagePath;
  final String? resolvedImagePath;
  final bool isValidatedByTeacher;
  final String? assignedTo;
  final bool isOfflineQueued;
  final List<ReportNoteModel> notes;

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final noteItems = json['notes'] as List? ?? const [];

    return ReportModel(
      id: json['id'] as String? ?? '',
      reporterId: json['reporterId'] as String? ?? '',
      reporterName: json['reporterName'] as String? ?? '',
      reporterRole: json['reporterRole'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      location: json['location'] as String? ?? '',
      priority: json['priority'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      imagePath: json['imagePath'] as String?,
      resolvedImagePath: json['resolvedImagePath'] as String?,
      isValidatedByTeacher: json['isValidatedByTeacher'] as bool? ?? false,
      assignedTo: json['assignedTo'] as String?,
      isOfflineQueued: json['isOfflineQueued'] as bool? ?? false,
      notes: [
        for (final item in noteItems)
          if (item is Map)
            ReportNoteModel.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterRole': reporterRole,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'priority': priority,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'imagePath': imagePath,
      'resolvedImagePath': resolvedImagePath,
      'isValidatedByTeacher': isValidatedByTeacher,
      'assignedTo': assignedTo,
      'isOfflineQueued': isOfflineQueued,
      'notes': notes.map((note) => note.toJson()).toList(),
    };
  }

  ReportModel copyWith({
    String? id,
    String? reporterId,
    String? reporterName,
    String? reporterRole,
    String? title,
    String? description,
    String? category,
    String? location,
    String? priority,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imagePath,
    String? resolvedImagePath,
    bool? isValidatedByTeacher,
    String? assignedTo,
    bool? isOfflineQueued,
    List<ReportNoteModel>? notes,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reporterRole: reporterRole ?? this.reporterRole,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imagePath: imagePath ?? this.imagePath,
      resolvedImagePath: resolvedImagePath ?? this.resolvedImagePath,
      isValidatedByTeacher: isValidatedByTeacher ?? this.isValidatedByTeacher,
      assignedTo: assignedTo ?? this.assignedTo,
      isOfflineQueued: isOfflineQueued ?? this.isOfflineQueued,
      notes: notes ?? this.notes,
    );
  }
}
