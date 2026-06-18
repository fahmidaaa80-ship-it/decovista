import 'product_model.dart';
import 'design_package_model.dart';

class CartItem {
  final String id;
  final String userId;
  final String? productId;
  final String? packageId;
  final int quantity;
  final bool isPackage;
  final Map<String, dynamic>? customizations;
  final Product? product;
  final DesignPackage? package;
  final DateTime createdAt;
  final DateTime updatedAt;

  CartItem({
    required this.id,
    required this.userId,
    this.productId,
    this.packageId,
    required this.quantity,
    this.isPackage = false,
    this.customizations,
    this.product,
    this.package,
    required this.createdAt,
    required this.updatedAt,
  });

  double get itemPrice {
    if (isPackage && package != null) {
      return package!.finalPrice;
    } else if (product != null) {
      return product!.finalPrice;
    }
    return 0.0;
  }

  double get totalPrice => itemPrice * quantity;

  String get itemName {
    if (isPackage && package != null) {
      return package!.name;
    } else if (product != null) {
      return product!.name;
    }
    return '';
  }

  String get itemImage {
    if (isPackage && package != null) {
      return package!.previewImage ?? '';
    } else if (product != null && product!.images.isNotEmpty) {
      return product!.images.first;
    }
    return '';
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      productId: json['product_id'],
      packageId: json['package_id'],
      quantity: json['quantity'] ?? 1,
      isPackage: json['is_package'] ?? false,
      customizations: json['customizations'],
      product: json['products'] != null
          ? Product.fromJson(json['products'])
          : null,
      package: json['design_packages'] != null
          ? DesignPackage.fromJson(json['design_packages'])
          : null,
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
      'user_id': userId,
      'product_id': productId,
      'package_id': packageId,
      'quantity': quantity,
      'is_package': isPackage,
      'customizations': customizations,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CartItem copyWith({
    String? id,
    String? userId,
    String? productId,
    String? packageId,
    int? quantity,
    bool? isPackage,
    Map<String, dynamic>? customizations,
    Product? product,
    DesignPackage? package,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      packageId: packageId ?? this.packageId,
      quantity: quantity ?? this.quantity,
      isPackage: isPackage ?? this.isPackage,
      customizations: customizations ?? this.customizations,
      product: product ?? this.product,
      package: package ?? this.package,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}