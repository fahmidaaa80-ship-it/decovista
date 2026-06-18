class CompletedProjectModel {
  final String id;
  final String title;
  final String beforeImage;
  final String afterImage;
  final String category;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  CompletedProjectModel({
    required this.id,
    required this.title,
    required this.beforeImage,
    required this.afterImage,
    required this.category,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory CompletedProjectModel.fromJson(Map<String, dynamic> json) {
    return CompletedProjectModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      beforeImage: json['before_image'] as String? ?? '',
      afterImage: json['after_image'] as String? ?? '',
      category: json['category'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'before_image': beforeImage,
      'after_image': afterImage,
      'category': category,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}
