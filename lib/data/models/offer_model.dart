import 'package:flutter/material.dart';

Color _parseHex(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

class OfferModel {
  final String id;
  final String title;
  final String discount;
  final String description;
  final String categoryName;
  final Color backgroundColor;
  final Color textColor;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  OfferModel({
    required this.id,
    required this.title,
    required this.discount,
    required this.description,
    required this.categoryName,
    this.backgroundColor = const Color(0xFFFFE5E5),
    this.textColor = const Color(0xFFD32F2F),
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      discount: json['discount'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? '',
      backgroundColor: _parseHex(json['background_color'] as String? ?? '#FFE5E5'),
      textColor: _parseHex(json['text_color'] as String? ?? '#D32F2F'),
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'discount': discount,
      'description': description,
      'category_name': categoryName,
      'background_color': '#${backgroundColor.value.toRadixString(16).substring(2).toUpperCase()}',
      'text_color': '#${textColor.value.toRadixString(16).substring(2).toUpperCase()}',
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}
