class VideoModel {
  final String id;
  final String title;
  final String description;
  final String youtubeVideoId;
  final String thumbnailUrl;
  final String courseId;
  final int order;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeVideoId,
    required this.thumbnailUrl,
    required this.courseId,
    required this.order,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VideoModel.fromMap(String id, Map<String, dynamic> data) {
    return VideoModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      youtubeVideoId: data['youtubeVideoId'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      courseId: data['courseId'] ?? '',
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
      'youtubeVideoId': youtubeVideoId,
      'thumbnailUrl': thumbnailUrl,
      'courseId': courseId,
      'order': order,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}