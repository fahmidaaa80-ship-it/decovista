import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../providers/product_provider.dart';
import '../../shop/widgets/product_card.dart';

class FeaturedProducts extends ConsumerWidget {
  const FeaturedProducts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(featuredProductsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Featured Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.push('/shop?featured=true');
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No featured products available'),
                ),
              );
            }

            return SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 180,
                      child: ProductCard(product: products[index]),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 280,
            child: LoadingWidget(),
          ),
          error: (error, stack) => SizedBox(
            height: 280,
            child: CustomErrorWidget(
              message: 'Failed to load products',
              onRetry: () {
                ref.invalidate(featuredProductsProvider);
              },
            ),
          ),
        ),
      ],
    );
  }
}