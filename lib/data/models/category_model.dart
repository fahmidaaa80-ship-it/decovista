class Category {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? parentId;
  final bool isActive;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.parentId,
    this.isActive = true,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'],
      parentId: json['parent_id'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'parent_id': parentId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}