class CourseModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String programme;
  final String year;
  final String semester;
  final int order;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.programme = '',
    this.year = '',
    this.semester = '',
    required this.order,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourseModel.fromMap(String id, Map<String, dynamic> data) {
    return CourseModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      programme: data['programme'] ?? '',
      year: data['year'] ?? '',
      semester: data['semester'] ?? '',
      order: data['order'] ?? 0,
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
      'imageUrl': imageUrl,
      'programme': programme,
      'year': year,
      'semester': semester,
      'order': order,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}