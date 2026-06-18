import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../core/services/supabase_service.dart';
import 'auth_provider.dart';

class WishlistNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final Ref ref;

  WishlistNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadWishlist();
  }

  Future<void> loadWishlist() async {
    final user = ref.read(currentUserProvider);

    if (user == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final response = await SupabaseService.getWishlist(user.id);
      final productIds = response
          .map((item) => item['product_id'] as String)
          .toList();
      state = AsyncValue.data(productIds);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleWishlist(String productId) async {
    final user = ref.read(currentUserProvider);

    if (user == null) return;

    final isInWishlist = state.maybeWhen(
      data: (items) => items.contains(productId),
      orElse: () => false,
    );

    try {
      if (isInWishlist) {
        await SupabaseService.removeFromWishlist(
          userId: user.id,
          productId: productId,
        );
      } else {
        await SupabaseService.addToWishlist(
          userId: user.id,
          productId: productId,
        );
      }

      await loadWishlist();
    } catch (e) {
      rethrow;
    }
  }

  bool isInWishlist(String productId) {
    return state.maybeWhen(
      data: (items) => items.contains(productId),
      orElse: () => false,
    );
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, AsyncValue<List<String>>>((ref) {
  return WishlistNotifier(ref);
});