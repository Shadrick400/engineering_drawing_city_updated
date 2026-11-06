/// Represents a past paper (Test 1, Test 2, or Sessional Exam) for a given academic year.
class PastPaperModel {
  final String id;
  final String title;
  final String description;
  final String year; // e.g. "2023", "2024"
  final String type; // 'test1' | 'test2' | 'sessional'
  final String courseId;
  final String fileUrl; // PDF / Google Drive link
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  PastPaperModel({
    required this.id,
    required this.title,
    required this.description,
    required this.year,
    required this.type,
    required this.courseId,
    required this.fileUrl,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  String get typeLabel {
    switch (type) {
      case 'test1':
        return 'Test 1';
      case 'test2':
        return 'Test 2';
      case 'sessional':
        return 'Sessional Exam';
      default:
        return type;
    }
  }

  factory PastPaperModel.fromMap(String id, Map<String, dynamic> data) {
    return PastPaperModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      year: data['year'] ?? '',
      type: data['type'] ?? 'test1',
      courseId: data['courseId'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      isPublished: data['isPublished'] ?? true,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'year': year,
      'type': type,
      'courseId': courseId,
      'fileUrl': fileUrl,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PastPaperModel copyWith({
    String? id,
    String? title,
    String? description,
    String? year,
    String? type,
    String? courseId,
    String? fileUrl,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PastPaperModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      year: year ?? this.year,
      type: type ?? this.type,
      courseId: courseId ?? this.courseId,
      fileUrl: fileUrl ?? this.fileUrl,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
