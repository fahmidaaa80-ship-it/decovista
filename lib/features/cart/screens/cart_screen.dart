import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/auth_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final cartAsync = ref.watch(cartProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Shopping Cart'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: AppColors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please login to view your cart',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Login',
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          cartAsync.maybeWhen(
            data: (items) {
              if (items.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Cart'),
                      content: const Text(
                        'Are you sure you want to remove all items from your cart?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(cartProvider.notifier).clearCart();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Clear All'),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: cartAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: AppColors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add some products to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Start Shopping',
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _CartItemCard(
                      item: items[index],
                      onRemove: () {
                        ref.read(cartProvider.notifier)
                            .removeItem(items[index].id);
                      },
                      onQuantityChanged: (quantity) {
                        ref.read(cartProvider.notifier)
                            .updateQuantity(items[index].id, quantity);
                      },
                    );
                  },
                ),
              ),

              // Cart Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        'Subtotal',
                        '৳${ref.watch(cartTotalProvider).toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Shipping',
                        'Free',
                        valueColor: AppColors.success,
                      ),
                      const Divider(height: 24),
                      _buildSummaryRow(
                        'Total',
                        '৳${ref.watch(cartTotalProvider).toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Proceed to Checkout',
                        onPressed: () => context.push('/checkout'),
                        width: double.infinity,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(message: 'Loading cart...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load cart',
          onRetry: () {
            ref.read(cartProvider.notifier).loadCart();
          },
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String label,
      String value, {
        bool isTotal = false,
        Color? valueColor,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? (isTotal ? AppColors.primary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onRemove;
  final Function(int) onQuantityChanged;

  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.itemImage,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.greyLight,
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.greyLight,
                child: const Icon(Icons.error),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                Text(
                  '৳${item.itemPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 4),

                // Quantity Controls
                Row(
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove,
                      onTap: () {
                        if (item.quantity > 1) {
                          onQuantityChanged(item.quantity - 1);
                        }
                      },
                    ),
                    Container(
                      width: 36,
                      alignment: Alignment.center,
                      child: Text(
                        item.quantity.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.add,
                      onTap: () {
                        onQuantityChanged(item.quantity + 1);
                      },
                    ),

                    const Spacer(),

                    // Total Price
                    Text(
                      '৳${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Remove Button
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Remove Item'),
                  content: const Text(
                    'Are you sure you want to remove this item from your cart?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        onRemove();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Remove',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.greyLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.primary,
        ),
      ),
    );
  }
}