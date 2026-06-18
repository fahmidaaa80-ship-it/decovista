import 'product_model.dart';
import 'design_package_model.dart';

class OrderItem {
  final String id;
  final String orderId;
  final String? productId;
  final String? packageId;
  final int quantity;
  final double price;
  final bool isPackage;
  final Map<String, dynamic>? customizations;
  final Product? product;
  final DesignPackage? package;

  OrderItem({
    required this.id,
    required this.orderId,
    this.productId,
    this.packageId,
    required this.quantity,
    required this.price,
    this.isPackage = false,
    this.customizations,
    this.product,
    this.package,
  });

  String get itemName {
    if (isPackage && package != null) return package!.name;
    if (product != null) return product!.name;
    if (productId != null) return 'Product #${productId!.substring(0, 8)}...';
    return 'Unknown Item';
  }

  String get itemImage {
    if (isPackage && package != null) return package!.previewImage ?? '';
    if (product != null && product!.images.isNotEmpty) return product!.images.first;
    return '';
  }

  double get totalPrice => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      productId: json['product_id'],
      packageId: json['package_id'],
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      isPackage: json['is_package'] ?? false,
      customizations: json['customizations'],
      product: json['products'] != null
          ? Product.fromJson(json['products'])
          : null,
      package: json['design_packages'] != null
          ? DesignPackage.fromJson(json['design_packages'])
          : null,
    );
  }
}
