import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/product_model.dart';
import 'product_card.dart';

class RelatedProducts extends ConsumerStatefulWidget {
  final String categoryId;

  const RelatedProducts({super.key, required this.categoryId});

  @override
  ConsumerState<RelatedProducts> createState() => _RelatedProductsState();
}

class _RelatedProductsState extends ConsumerState<RelatedProducts> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRelatedProducts();
  }

  Future<void> _loadRelatedProducts() async {
    if (widget.categoryId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await SupabaseService.getProducts(
        category: widget.categoryId,
        limit: 6,
      );
      setState(() {
        _products = response.map((json) => Product.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Related Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 180,
                  child: ProductCard(product: _products[index]),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}