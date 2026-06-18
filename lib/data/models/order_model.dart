import 'order_item_model.dart';

class Order {
  final String id;
  final String orderNumber;
  final String userId;
  final double totalAmount;
  final Map<String, dynamic> shippingAddress;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String? notes;
  final List<OrderItem> items;
  final Map<String, dynamic>? user;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.totalAmount,
    required this.shippingAddress,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.orderStatus = 'pending',
    this.notes,
    this.items = const [],
    this.user,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsData = json['order_items'] as List<dynamic>?;
    return Order(
      id: json['id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      userId: json['user_id'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      shippingAddress: json['shipping_address'] ?? {},
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? 'pending',
      orderStatus: json['order_status'] ?? 'pending',
      notes: json['notes'],
      items: itemsData != null
          ? itemsData.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      user: json['users'] as Map<String, dynamic>?,
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
      'order_number': orderNumber,
      'user_id': userId,
      'total_amount': totalAmount,
      'shipping_address': shippingAddress,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'order_status': orderStatus,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}