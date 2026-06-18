import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/services/supabase_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../data/models/product_model.dart';

final wishlistProductsProvider = FutureProvider<List<Product>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  // Watch wishlistProvider so this re-fetches when IDs change
  final wishlistAsync = ref.watch(wishlistProvider);
  final wishlistIds = wishlistAsync.maybeWhen(
    data: (ids) => ids,
    orElse: () => <String>[],
  );
  if (wishlistIds.isEmpty) return [];

  try {
    final response = await SupabaseService.getWishlist(user.id);
    return response
        .map((item) => Product.fromJson(item['products']))
        .toList();
  } catch (e) {
    return [];
  }
});

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          wishlistAsync.maybeWhen(
            data: (products) {
              if (products.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Wishlist'),
                      content: const Text(
                        'Are you sure you want to remove all items from your wishlist?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final user = ref.read(currentUserProvider);
                            if (user != null) {
                              await SupabaseService.clearWishlist(user.id);
                            }
                            ref.invalidate(wishlistProductsProvider);
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
      body: wishlistAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: AppColors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your wishlist is empty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Save items you love for later',
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
              ref.invalidate(wishlistProductsProvider);
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _WishlistCard(product: products[index]);
              },
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading wishlist...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load wishlist',
          onRetry: () {
            ref.invalidate(wishlistProductsProvider);
          },
        ),
      ),
    );
  }
}

class _WishlistCard extends ConsumerWidget {
  final Product product;

  const _WishlistCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        context.push('/product/${product.id}');
      },
      child: Container(
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
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: product.images.isNotEmpty
                        ? product.images.first
                        : '',
                    height: 110,
                    width: double.infinity,
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

                // Remove Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(wishlistProvider.notifier)
                          .toggleWishlist(product.id);
                      ref.invalidate(wishlistProductsProvider);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Price
                    Row(
                      children: [
                        Text(
                          '৳${product.finalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 8),
                          Text(
                            '৳${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Add to Cart Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await ref.read(cartProvider.notifier).addToCart(
                              productId: product.id,
                              quantity: 1,
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to cart'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                        child: const Text('Add to Cart'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}