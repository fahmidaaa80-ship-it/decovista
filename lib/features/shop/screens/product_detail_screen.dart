import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/review_section.dart';
import '../widgets/related_products.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;
  int _quantity = 1;
  String? _selectedColor;

  // ✅ হেক্স স্ট্রিং থেকে নিরাপদে কালার অবজেক্ট তৈরি করার মেথড
  Color _parseColor(String hexString) {
    try {
      final buffer = StringBuffer();
      // যদি # থাকে তা বাদ দিয়ে ক্লিন করে নেওয়া
      String cleanHex = hexString.replaceFirst('#', '').trim().toUpperCase();

      if (cleanHex.length == 6) {
        buffer.write('FF'); // Alpha channel (Opacity 100%)
        buffer.write(cleanHex);
      } else if (cleanHex.length == 8) {
        buffer.write(cleanHex);
      } else {
        return Colors.transparent; // ভুল ফরম্যাট হলে ট্রান্সপারেন্ট কালার রিটার্ন করবে
      }

      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.transparent; // কোনো কারণে ফেইল করলে ক্র্যাশ না করে ডিফল্ট কালার দেবে
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.productId));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Center(
              child: Text('Product not found'),
            );
          }

          final wishlistState = ref.watch(wishlistProvider);
          final isInWishlist = wishlistState.maybeWhen(
            data: (items) => items.contains(product.id),
            orElse: () => false,
          );

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                actions: [
                  IconButton(
                    onPressed: () {
                      // Share product
                    },
                    icon: const Icon(Icons.share_outlined),
                  ),
                  IconButton(
                    onPressed: () {
                      if (user != null) {
                        ref.read(wishlistProvider.notifier)
                            .toggleWishlist(product.id);
                      }
                    },
                    icon: Icon(
                      isInWishlist ? Icons.favorite : Icons.favorite_border,
                      color: isInWishlist ? AppColors.error : null,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Image Carousel
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 400,
                          viewportFraction: 1.0,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                        ),
                        items: product.images.map((imageUrl) {
                          return CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Container(
                              color: AppColors.greyLight,
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.greyLight,
                              child: const Icon(Icons.error),
                            ),
                          );
                        }).toList(),
                      ),

                      // Badges
                      Positioned(
                        top: 60,
                        left: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.isNew)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.info,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (product.hasDiscount)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '-${product.discountPercentage}% OFF',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Image Indicator
                      if (product.images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: product.images.asMap().entries.map((entry) {
                              return Container(
                                width: _currentImageIndex == entry.key ? 24.0 : 8.0,
                                height: 8.0,
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: _currentImageIndex == entry.key
                                      ? AppColors.primary
                                      : Colors.white.withOpacity(0.5),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Product Details
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name and Rating
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Rating
                            if (product.rating > 0)
                              Row(
                                children: [
                                  RatingBarIndicator(
                                    rating: product.rating,
                                    itemBuilder: (context, index) => const Icon(
                                      Icons.star,
                                      color: AppColors.rating,
                                    ),
                                    itemCount: 5,
                                    itemSize: 20.0,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${product.rating.toStringAsFixed(1)} (${product.reviewCount} reviews)',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 16),

                            // Price
                            Row(
                              children: [
                                Text(
                                  '৳${product.finalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                if (product.hasDiscount) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    '৳${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: AppColors.textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Stock Status
                            Row(
                              children: [
                                Icon(
                                  product.isInStock
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 20,
                                  color: product.isInStock
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  product.isInStock
                                      ? 'In Stock (${product.stock} available)'
                                      : 'Out of Stock',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: product.isInStock
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Color Selection
                            if (product.colors.isNotEmpty) ...[
                              const Text(
                                'Color',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                children: product.colors.map((colorHex) {
                                  final isSelected = _selectedColor == colorHex;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedColor = colorHex;
                                      });
                                    },
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        // 🛠️ এখানে পরিবর্তন করা হয়েছে
                                        color: _parseColor(colorHex),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.greyLight,
                                          width: isSelected ? 3 : 1,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Quantity
                            const Text(
                              'Quantity',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildQuantityButton(
                                  icon: Icons.remove,
                                  onTap: () {
                                    if (_quantity > 1) {
                                      setState(() {
                                        _quantity--;
                                      });
                                    }
                                  },
                                ),
                                Container(
                                  width: 60,
                                  height: 48,
                                  alignment: Alignment.center,
                                  child: Text(
                                    _quantity.toString(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                _buildQuantityButton(
                                  icon: Icons.add,
                                  onTap: () {
                                    if (_quantity < product.stock) {
                                      setState(() {
                                        _quantity++;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 24),

                            // Description
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              product.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Material
                            Row(
                              children: [
                                const Icon(
                                  Icons.layers_outlined,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Material: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  product.material,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // Reviews Section
                      ReviewSection(productId: product.id),

                      const SizedBox(height: 24),

                      // Related Products
                      RelatedProducts(categoryId: product.categoryId ?? ''),

                      const SizedBox(height: 100), // Space for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(message: 'Loading product...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load product',
          onRetry: () {
            ref.invalidate(productByIdProvider(widget.productId));
          },
        ),
      ),

      // Bottom Bar
      bottomNavigationBar: productAsync.maybeWhen(
        data: (product) {
          if (product == null) return null;

          return Container(
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
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Add to Cart',
                      icon: Icons.shopping_cart_outlined,
                      onPressed: product.isInStock
                          ? () async {
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please login to add items to cart'),
                            ),
                          );
                          return;
                        }

                        try {
                          await ref.read(cartProvider.notifier).addToCart(
                            productId: product.id,
                            quantity: _quantity,
                            customizations: _selectedColor != null
                                ? {'color': _selectedColor}
                                : null,
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
                      }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Buy Now',
                      onPressed: product.isInStock
                          ? () {
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please login to continue'),
                            ),
                          );
                          return;
                        }
                        // ✅ cart এ add না করে সরাসরি data pass
                        context.push('/checkout', extra: {
                          'buyNow': true,
                          'productId': product.id,
                          'quantity': _quantity,
                          'price': product.finalPrice,
                          'name': product.name,
                          'image': product.images.isNotEmpty
                              ? product.images.first
                              : '',
                          'customizations': _selectedColor != null
                              ? {'color': _selectedColor}
                              : null,
                        });
                      }
                          : null,
                      backgroundColor: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => null,
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.greyLight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
        ),
      ),
    );
  }
}