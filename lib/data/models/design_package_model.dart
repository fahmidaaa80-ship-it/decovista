class DesignPackage {
  final String id;
  final String name;
  final String? description;
  final String roomType;
  final String? style;
  final double price;
  final double? discountPrice;
  final String? previewImage;
  final List<String> images;
  final double? estimatedBudget;
  final String? roomSize;
  final List<String> wallColorSuggestions;
  final bool isCustomizable;
  final bool isFeatured;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  DesignPackage({
    required this.id,
    required this.name,
    this.description,
    required this.roomType,
    this.style,
    required this.price,
    this.discountPrice,
    this.previewImage,
    this.images = const [],
    this.estimatedBudget,
    this.roomSize,
    this.wallColorSuggestions = const [],
    this.isCustomizable = true,
    this.isFeatured = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  double get finalPrice => discountPrice ?? price;

  int get discountPercentage {
    if (discountPrice == null) return 0;
    return (((price - discountPrice!) / price) * 100).round();
  }

  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  factory DesignPackage.fromJson(Map<String, dynamic> json) {
    return DesignPackage(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      roomType: json['room_type'] ?? '',
      style: json['style'],
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discount_price'] != null
          ? (json['discount_price'] as num).toDouble()
          : null,
      previewImage: json['preview_image'],
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
      estimatedBudget: json['estimated_budget'] != null
          ? (json['estimated_budget'] as num).toDouble()
          : null,
      roomSize: json['room_size'],
      wallColorSuggestions: json['wall_color_suggestions'] != null
          ? List<String>.from(json['wall_color_suggestions'])
          : [],
      isCustomizable: json['is_customizable'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'room_type': roomType,
      'style': style,
      'price': price,
      'discount_price': discountPrice,
      'preview_image': previewImage,
      'images': images,
      'estimated_budget': estimatedBudget,
      'room_size': roomSize,
      'wall_color_suggestions': wallColorSuggestions,
      'is_customizable': isCustomizable,
      'is_featured': isFeatured,
      'rating': rating,
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}