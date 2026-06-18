import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/supabase_service.dart';
import '../../../providers/design_package_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/auth_provider.dart';

class DesignDetailScreen extends ConsumerStatefulWidget {
  final String designId;

  const DesignDetailScreen({super.key, required this.designId});

  @override
  ConsumerState<DesignDetailScreen> createState() => _DesignDetailScreenState();
}

class _DesignDetailScreenState extends ConsumerState<DesignDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final packageAsync = ref.watch(packageByIdProvider(widget.designId));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: packageAsync.when(
        data: (package) {
          if (package == null) {
            return const Center(
              child: Text('Package not found'),
            );
          }

          final allImages = [
            if (package.previewImage != null) package.previewImage!,
            ...package.images,
          ];

          return CustomScrollView(
            slivers: [
              // App Bar with Images
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    tooltip: 'Save to My Designs',
                    onPressed: () async {
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please login to save designs')),
                        );
                        return;
                      }
                      try {
                        await SupabaseService.saveUserDesign(
                          userId: user.id,
                          packageId: package.id,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Design saved to My Designs'),
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
                  ),
                  IconButton(
                    onPressed: () {
                      // Share package
                    },
                    icon: const Icon(Icons.share_outlined),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Image Carousel
                      if (allImages.isNotEmpty)
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
                          items: allImages.map((imageUrl) {
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
                            if (package.isFeatured)
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
                                  'FEATURED',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (package.hasDiscount)
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
                                  '-${package.discountPercentage}% OFF',
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
                      if (allImages.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: allImages.asMap().entries.map((entry) {
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

              // Package Details
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Room Type
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                package.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                package.roomType.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Price
                        Row(
                          children: [
                            Text(
                              '৳${package.finalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            if (package.hasDiscount) ...[
                              const SizedBox(width: 12),
                              Text(
                                '৳${package.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: AppColors.textSecondary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Description
                        if (package.description != null) ...[
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
                            package.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Package Details
                        const Text(
                          'Package Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildDetailRow(
                          icon: Icons.straighten,
                          label: 'Room Size',
                          value: package.roomSize ?? 'Not specified',
                        ),

                        if (package.style != null)
                          _buildDetailRow(
                            icon: Icons.palette_outlined,
                            label: 'Style',
                            value: package.style!,
                          ),

                        if (package.estimatedBudget != null)
                          _buildDetailRow(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Estimated Budget',
                            value: '৳${package.estimatedBudget!.toStringAsFixed(2)}',
                          ),

                        _buildDetailRow(
                          icon: Icons.edit_outlined,
                          label: 'Customizable',
                          value: package.isCustomizable ? 'Yes' : 'No',
                        ),

                        const SizedBox(height: 24),

                        // Wall Color Suggestions
                        if (package.wallColorSuggestions.isNotEmpty) ...[
                          const Text(
                            'Wall Color Suggestions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: package.wallColorSuggestions.map((colorHex) {
                              return Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _parseColor(colorHex),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.greyLight,
                                    width: 1,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Included Items
                        const Text(
                          'What\'s Included',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.greyLight.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _IncludedItem(text: 'Complete furniture set'),
                              SizedBox(height: 8),
                              _IncludedItem(text: 'Design consultation'),
                              SizedBox(height: 8),
                              _IncludedItem(text: 'Installation guide'),
                              SizedBox(height: 8),
                              _IncludedItem(text: 'Free delivery'),
                              SizedBox(height: 8),
                              _IncludedItem(text: '1 year warranty'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100), // Space for bottom bar
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(message: 'Loading package...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load package',
          onRetry: () {
            ref.invalidate(packageByIdProvider(widget.designId));
          },
        ),
      ),

      // Bottom Bar
      bottomNavigationBar: packageAsync.maybeWhen(
        data: (package) {
          if (package == null) return null;

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
                  if (package.isCustomizable)
                    Expanded(
                      child: CustomButton(
                        text: 'Customize',
                        icon: Icons.edit_outlined,
                        onPressed: () {
                          context.push('/design/${package.id}/customize');
                        },
                        isOutlined: true,
                      ),
                    ),
                  if (package.isCustomizable) const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Add to Cart',
                      icon: Icons.shopping_cart_outlined,
                      onPressed: () async {
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
                            packageId: package.id,
                            quantity: 1,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Package added to cart'),
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncludedItem extends StatelessWidget {
  final String text;

  const _IncludedItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle,
          size: 20,
          color: AppColors.success,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// Helper method add করো class এর ভেতরে
Color _parseColor(String colorStr) {
  final s = colorStr.trim();
  // Hex format: "RRGGBB" বা "#RRGGBB"
  final hex = s.startsWith('#') ? s.substring(1) : s;
  final hexRegex = RegExp(r'^[0-9A-Fa-f]{6}$');
  if (hexRegex.hasMatch(hex)) {
    return Color(int.parse('FF$hex', radix: 16));
  }
  // Named colors fallback
  const namedColors = {
    'black':  Color(0xFF000000),
    'white':  Color(0xFFFFFFFF),
    'red':    Color(0xFFE53935),
    'blue':   Color(0xFF1E88E5),
    'green':  Color(0xFF43A047),
    'grey':   Color(0xFF9E9E9E),
    'gray':   Color(0xFF9E9E9E),
    'yellow': Color(0xFFFDD835),
    'orange': Color(0xFFFB8C00),
    'brown':  Color(0xFF6D4C41),
    'pink':   Color(0xFFE91E63),
    'purple': Color(0xFF8E24AA),
    'beige':  Color(0xFFF5F0DC),
    'cream':  Color(0xFFFFFDD0),
    'navy':   Color(0xFF003153),
    'teal':   Color(0xFF00897B),
  };
  return namedColors[s.toLowerCase()] ?? const Color(0xFF9E9E9E);
}