class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String primaryAction;
  final String secondaryAction;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.primaryAction = 'Shop Now',
    this.secondaryAction = 'Explore',
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      primaryAction: json['primary_action'] as String? ?? 'Shop Now',
      secondaryAction: json['secondary_action'] as String? ?? 'Explore',
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'primary_action': primaryAction,
      'secondary_action': secondaryAction,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}
