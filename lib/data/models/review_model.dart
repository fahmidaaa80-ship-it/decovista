import 'package:decovista/data/models/user_model.dart';

class Review {
  final String id;
  final String userId;
  final String? productId;
  final String? packageId;
  final int rating;
  final String? title;
  final String? comment;
  final List<String> images;
  final bool isVerifiedPurchase;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? user;

  Review({
    required this.id,
    required this.userId,
    this.productId,
    this.packageId,
    required this.rating,
    this.title,
    this.comment,
    this.images = const [],
    this.isVerifiedPurchase = false,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      productId: json['product_id'],
      packageId: json['package_id'],
      rating: json['rating'] ?? 0,
      title: json['title'],
      comment: json['comment'],
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
      isVerifiedPurchase: json['is_verified_purchase'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      user: json['users'] != null
          ? UserModel.fromJson(json['users'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'package_id': packageId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'images': images,
      'is_verified_purchase': isVerifiedPurchase,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}