import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../core/services/supabase_service.dart';
import '../data/models/cart_item_model.dart';
import 'auth_provider.dart';

class CartNotifier extends StateNotifier<AsyncValue<List<CartItem>>> {
  final Ref ref;

  CartNotifier(this.ref) : super(const AsyncValue.loading()) {
    // ✅ auth state change হলে cart reload
    ref.listen(currentUserProvider, (previous, next) {
      loadCart();
    });
    loadCart();
  }

  Future<void> loadCart() async {
    final user = ref.read(currentUserProvider);

    if (user == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading(); // ✅ reload এ loading দেখাবে

    try {
      final response = await SupabaseService.getCart(user.id);
      final cartItems = response
          .map((json) => CartItem.fromJson(json))
          .toList();
      state = AsyncValue.data(cartItems);
    } catch (e, stack) {
      debugPrint('Cart error: $e'); // ✅ exact error console এ দেখাবে
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addToCart({
    String? productId,
    String? packageId,
    required int quantity,
    Map<String, dynamic>? customizations,
  }) async {
    final user = ref.read(currentUserProvider);

    if (user == null) return;

    try {
      await SupabaseService.addToCart(
        userId: user.id,
        productId: productId,
        packageId: packageId,
        quantity: quantity,
        customizations: customizations,
      );

      await loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuantity(String cartId, int quantity) async {
    try {
      await SupabaseService.updateCartItem(
        cartId: cartId,
        quantity: quantity,
      );

      await loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeItem(String cartId) async {
    try {
      await SupabaseService.removeFromCart(cartId);
      await loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearCart() async {
    final user = ref.read(currentUserProvider);

    if (user == null) return;

    try {
      await SupabaseService.clearCart(user.id);
      state = const AsyncValue.data([]);
    } catch (e) {
      rethrow;
    }
  }

  int get cartCount {
    return state.maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );
  }

  double get totalAmount {
    return state.maybeWhen(
      data: (items) => items.fold(0.0, (sum, item) => sum + item.totalPrice),
      orElse: () => 0.0,
    );
  }
}

final cartProvider =
StateNotifierProvider<CartNotifier, AsyncValue<List<CartItem>>>((ref) {
  return CartNotifier(ref);
});

// Cart Count Provider
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider.notifier).cartCount;
});

// Total Amount Provider
final cartTotalProvider = Provider<double>((ref) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.maybeWhen(
    data: (items) => items.fold(0.0, (sum, item) => sum + item.totalPrice),
    orElse: () => 0.0,
  );
});