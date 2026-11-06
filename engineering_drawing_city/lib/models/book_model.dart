/// Represents a reference book or study material available to students.
class BookModel {
  final String id;
  final String title;
  final String author;
  final String description;
  final String courseId; // which course it belongs to
  final String fileUrl; // PDF / Google Drive link
  final String coverUrl; // optional cover image
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.courseId,
    required this.fileUrl,
    this.coverUrl = '',
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookModel.fromMap(String id, Map<String, dynamic> data) {
    return BookModel(
      id: id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      description: data['description'] ?? '',
      courseId: data['courseId'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      coverUrl: data['coverUrl'] ?? '',
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
      'author': author,
      'description': description,
      'courseId': courseId,
      'fileUrl': fileUrl,
      'coverUrl': coverUrl,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? courseId,
    String? fileUrl,
    String? coverUrl,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      fileUrl: fileUrl ?? this.fileUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
