class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final String? categoryId;
  final String? categoryName;
  final List<String> images;
  final String material;
  final int stock;
  final double rating;
  final int reviewCount;
  final List<String> colors;
  final bool isFeatured;
  final bool isNew;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    this.categoryId,
    this.categoryName,
    required this.images,
    required this.material,
    required this.stock,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.colors = const [],
    this.isFeatured = false,
    this.isNew = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  double get finalPrice => discountPrice ?? price;

  int get discountPercentage {
    if (discountPrice == null) return 0;
    return (((price - discountPrice!) / price) * 100).round();
  }

  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  bool get isInStock => stock > 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discount_price'] != null
          ? (json['discount_price'] as num).toDouble()
          : null,
      categoryId: json['category_id'],
      categoryName: json['categories'] != null ? json['categories']['name'] as String? : null,
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
      material: json['material'] ?? '',
      stock: json['stock'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      colors: json['colors'] != null
          ? List<String>.from(json['colors'])
          : [],
      isFeatured: json['is_featured'] ?? false,
      isNew: json['is_new'] ?? false,
      isActive: json['is_active'] ?? true,
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
      'price': price,
      'discount_price': discountPrice,
      'category_id': categoryId,
      'images': images,
      'material': material,
      'stock': stock,
      'rating': rating,
      'review_count': reviewCount,
      'colors': colors,
      'is_featured': isFeatured,
      'is_new': isNew,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? discountPrice,
    String? categoryId,
    String? categoryName,
    List<String>? images,
    String? material,
    int? stock,
    double? rating,
    int? reviewCount,
    List<String>? colors,
    bool? isFeatured,
    bool? isNew,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      images: images ?? this.images,
      material: material ?? this.material,
      stock: stock ?? this.stock,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      colors: colors ?? this.colors,
      isFeatured: isFeatured ?? this.isFeatured,
      isNew: isNew ?? this.isNew,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}