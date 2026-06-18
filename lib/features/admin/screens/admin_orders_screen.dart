import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../data/models/order_item_model.dart';
import '../../../data/models/order_model.dart';
import '../../../providers/admin_provider.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  final String? initialStatusFilter;

  const AdminOrdersScreen({super.key, this.initialStatusFilter});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatusFilter ?? 'all';
  }

  static const _statusOptions = [
    'all',
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(adminOrdersNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter chips
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _statusOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = _statusOptions[index];
                final isSelected = _statusFilter == status;
                return ChoiceChip(
                  label: Text(
                    status == 'all' ? 'All' : _capitalize(status),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: _statusColor(status),
                  backgroundColor: AppColors.greyLight,
                  onSelected: (_) =>
                      setState(() => _statusFilter = status),
                );
              },
            ),
          ),

          // Orders list
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                final filtered = _statusFilter == 'all'
                    ? orders
                    : orders
                    .where((o) => o.orderStatus == _statusFilter)
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 64, color: AppColors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _statusFilter == 'all'
                              ? 'No orders yet'
                              : 'No $_statusFilter orders',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _OrderCard(order: filtered[index]),
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, _) =>
                  Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'processing':
        return AppColors.info;
      case 'shipped':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }
}

class _OrderCard extends ConsumerWidget {
  final Order order;

  const _OrderCard({required this.order});

  static const _nextStatusMap = {
    'pending': 'processing',
    'processing': 'shipped',
    'shipped': 'delivered',
  };

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'processing':
        return AppColors.info;
      case 'shipped':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'processing':
        return Icons.refresh;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextStatus = _nextStatusMap[order.orderStatus];
    final statusColor = _statusColor(order.orderStatus);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top accent bar ──
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),

          // ── Header section ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _statusIcon(order.orderStatus),
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.orderNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        order.user?['full_name'] ??
                            order.shippingAddress['full_name'] ??
                            'N/A',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '৳${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusBadge(status: order.orderStatus),
                  ],
                ),
              ],
            ),
          ),

          // ── Separator ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(height: 1, color: AppColors.greyLight.withOpacity(0.6)),
          ),

          // ── Contact & shipping row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Email & phone
                if (order.user != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _InfoRow(
                      leading: const Icon(Icons.email_outlined, size: 15, color: AppColors.textSecondary),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            order.user!['email'] ?? '',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.phone_outlined, size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            order.user!['phone'] ?? 'N/A',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Shipping address
                _InfoRow(
                  leading: const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                  trailing: Text(
                    [
                      order.shippingAddress['address'],
                      order.shippingAddress['city'],
                    ].whereType<String>().join(', '),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 6),

                // Payment method & date
                _InfoRow(
                  leading: const Icon(Icons.payment_outlined, size: 15, color: AppColors.textSecondary),
                  trailing: Text(
                    '${order.paymentMethod.toUpperCase()}  ·  ${_formatDate(order.createdAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // ── Order items section ──
          if (order.items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(height: 1, color: AppColors.greyLight.withOpacity(0.6)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Items (${order.items.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: order.items.map((item) => _OrderItemTile(item: item)).toList(),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(height: 1, color: AppColors.greyLight.withOpacity(0.6)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 15, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Text(
                    'No product data available for this order',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Action buttons ──
          if (nextStatus != null || order.orderStatus == 'pending') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(height: 1, color: AppColors.greyLight.withOpacity(0.6)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  if (nextStatus != null)
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(context, ref, nextStatus),
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: Text(
                            'Mark ${_capitalize(nextStatus)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (order.orderStatus == 'pending') ...[
                    if (nextStatus != null) const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(context, ref, 'cancelled'),
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text(
                            'Cancel Order',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _updateStatus(
      BuildContext context, WidgetRef ref, String newStatus) async {
    try {
      await ref
          .read(adminOrdersNotifierProvider.notifier)
          .updateOrderStatus(order.id, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${_capitalize(newStatus)} করা হয়েছে'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _InfoRow extends StatelessWidget {
  final Widget leading;
  final Widget trailing;

  const _InfoRow({required this.leading, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        leading,
        const SizedBox(width: 6),
        Expanded(child: trailing),
      ],
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final OrderItem item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.itemImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.itemImage,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.greyLight,
                      width: 52,
                      height: 52,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.greyLight,
                      width: 52,
                      height: 52,
                      child: const Icon(Icons.image, size: 22),
                    ),
                  )
                : Container(
                    color: AppColors.greyLight,
                    width: 52,
                    height: 52,
                    child: const Icon(Icons.image, size: 22),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Tag(label: 'Qty: ${item.quantity}'),
                    const SizedBox(width: 6),
                    _Tag(label: '৳${item.price.toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '৳${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.greyLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'pending':
        color = AppColors.warning;
        icon = Icons.schedule;
        break;
      case 'processing':
        color = AppColors.info;
        icon = Icons.refresh;
        break;
      case 'shipped':
        color = AppColors.primary;
        icon = Icons.local_shipping;
        break;
      case 'delivered':
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        color = AppColors.error;
        icon = Icons.cancel;
        break;
      default:
        color = AppColors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}