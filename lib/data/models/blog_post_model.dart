import 'content_section.dart';

class BlogPostModel {
  final String id;
  final String title;
  final String excerpt;
  final String content;
  final String image;
  final List<String> images;
  final List<ContentSection> contentBlocks;
  final String category;
  final String readTime;
  final bool isActive;
  final DateTime createdAt;

  BlogPostModel({
    required this.id,
    required this.title,
    required this.excerpt,
    this.content = '',
    required this.image,
    this.images = const [],
    this.contentBlocks = const [],
    required this.category,
    required this.readTime,
    this.isActive = true,
    required this.createdAt,
  });

  factory BlogPostModel.fromJson(Map<String, dynamic> json) {
    return BlogPostModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      content: json['content'] as String? ?? '',
      image: json['image'] as String? ?? '',
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : [],
      contentBlocks: json['content_blocks'] != null
          ? (json['content_blocks'] as List)
              .map((e) => ContentSection.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      category: json['category'] as String? ?? '',
      readTime: json['read_time'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'excerpt': excerpt,
      'content': content,
      'image': image,
      'images': images,
      'content_blocks': contentBlocks.map((e) => e.toJson()).toList(),
      'category': category,
      'read_time': readTime,
      'is_active': isActive,
    };
  }
}
