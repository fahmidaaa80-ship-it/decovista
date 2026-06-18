import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/services/supabase_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/order_model.dart';

final ordersProvider = FutureProvider<List<Order>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final response = await SupabaseService.getOrders(user.id);
    return response.map((json) => Order.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: AppColors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your order history will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ordersProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _OrderCard(order: orders[index], ref: ref);
              },
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading orders...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load orders',
          onRetry: () {
            ref.invalidate(ordersProvider);
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final WidgetRef ref;

  const _OrderCard({required this.order, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(order.createdAt),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(order.orderStatus),
            ],
          ),

          const Divider(height: 24),

          // Order Details
          Row(
            children: [
              const Icon(
                Icons.payment_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                order.paymentMethod,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '৳${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Shipping Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getAddressString(order.shippingAddress),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showOrderDetails(context);
                  },
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 12),
              if (order.orderStatus == 'pending' ||
                  order.orderStatus == 'processing')
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showCancelDialog(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        label = 'Pending';
        break;
      case 'processing':
        bgColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        label = 'Processing';
        break;
      case 'designing':
        bgColor = AppColors.secondary.withOpacity(0.3);
        textColor = AppColors.primary;
        label = 'Designing';
        break;
      case 'shipping':
        bgColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        label = 'Shipping';
        break;
      case 'delivered':
        bgColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        label = 'Delivered';
        break;
      case 'cancelled':
        bgColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        label = 'Cancelled';
        break;
      default:
        bgColor = AppColors.greyLight;
        textColor = AppColors.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _getAddressString(Map<String, dynamic> address) {
    return '${address['address']}, ${address['city']}, ${address['zip_code']}';
  }

  void _showOrderDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _OrderDetailsSheet(
            order: order,
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SupabaseService.cancelOrder(order.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order cancelled'),
                  backgroundColor: AppColors.success,
                ),
              );
              ref.invalidate(ordersProvider);
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  final Order order;
  final ScrollController scrollController;

  const _OrderDetailsSheet({
    required this.order,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Order #${order.orderNumber}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Status Timeline
                  _buildStatusTimeline(),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Ordered Items
                  if (order.items.isNotEmpty) ...[
                    const Text(
                      'Ordered Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item.itemImage.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: item.itemImage,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: AppColors.greyLight,
                                      width: 56,
                                      height: 56,
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.greyLight,
                                      width: 56,
                                      height: 56,
                                      child: const Icon(Icons.image, size: 24),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.greyLight,
                                    width: 56,
                                    height: 56,
                                    child: const Icon(Icons.image, size: 24),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.itemName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Qty: ${item.quantity}  |  ৳${item.price.toStringAsFixed(2)} each',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '৳${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 16),
                  ],

                  // Shipping Information
                  const Text(
                    'Shipping Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Name', order.shippingAddress['full_name']),
                  _buildInfoRow('Phone', order.shippingAddress['phone']),
                  _buildInfoRow('Address', order.shippingAddress['address']),
                  _buildInfoRow('City', order.shippingAddress['city']),
                  _buildInfoRow('ZIP Code', order.shippingAddress['zip_code']),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Payment Information
                  const Text(
                    'Payment Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Method', order.paymentMethod),
                  _buildInfoRow('Status', order.paymentStatus),
                  _buildInfoRow(
                    'Total Amount',
                    '৳${order.totalAmount.toStringAsFixed(2)}',
                  ),

                  if (order.notes != null) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    const Text(
                      'Order Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      order.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final statuses = [
      {'status': 'pending', 'label': 'Order Placed'},
      {'status': 'processing', 'label': 'Processing'},
      {'status': 'shipping', 'label': 'Shipping'},
      {'status': 'delivered', 'label': 'Delivered'},
    ];

    final currentIndex = statuses.indexWhere(
          (s) => s['status'] == order.orderStatus,
    );

    return Column(
      children: List.generate(statuses.length, (index) {
        final isCompleted = index <= currentIndex;
        final isActive = index == currentIndex;

        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.primary : AppColors.greyLight,
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                      : null,
                ),
                if (index < statuses.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted ? AppColors.primary : AppColors.greyLight,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                statuses[index]['label']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}