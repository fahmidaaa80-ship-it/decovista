import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../core/services/supabase_service.dart';
import '../data/models/product_model.dart';

// Featured Products Provider
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  try {
    final response = await SupabaseService.getProducts(
      isFeatured: true,
      limit: 10,
    );

    return response.map((json) => Product.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

// New Products Provider
final newProductsProvider = FutureProvider<List<Product>>((ref) async {
  try {
    final response = await SupabaseService.getProducts(
      isNew: true,
      limit: 10,
    );

    return response.map((json) => Product.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

// All Products Provider
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  try {
    final response = await SupabaseService.getProducts(limit: 50);

    return response.map((json) => Product.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

// Products by Category Name Provider
final productsByCategoryProvider = FutureProvider.family<List<Product>, String>((ref, categoryName) async {
  try {
    final response = await SupabaseService.getProductsByCategoryName(categoryName);
    return response.map((json) => Product.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

// Product by ID Provider
final productByIdProvider = FutureProvider.family<Product?, String>((ref, productId) async {
  try {
    final response = await SupabaseService.getProductById(productId);
    return Product.fromJson(response);
  } catch (e) {
    return null;
  }
});

// Product Search Provider
class ProductSearchNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  ProductSearchNotifier() : super(const AsyncValue.data([]));

  Future<void> searchProducts(String query, {String? category}) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final response = await SupabaseService.searchProducts(query, category: category);
      final products = response.map((json) => Product.fromJson(json)).toList();
      state = AsyncValue.data(products);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final productSearchProvider = StateNotifierProvider<ProductSearchNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductSearchNotifier();
});