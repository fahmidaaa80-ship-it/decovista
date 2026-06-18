import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../data/models/design_package_model.dart';
import '../data/models/order_model.dart';
import '../data/models/product_model.dart';

// ─────────────────────────────────────────
// ADMIN STATS
// ─────────────────────────────────────────

class AdminStats {
  final int totalProducts;
  final int totalOrders;
  final int totalUsers;
  final int pendingOrders;
  final double totalRevenue;

  const AdminStats({
    required this.totalProducts,
    required this.totalOrders,
    required this.totalUsers,
    required this.pendingOrders,
    required this.totalRevenue,
  });
}

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final client = Supabase.instance.client;

  final products = await client.from('products').select('id');
  final orders = await client
      .from('orders')
      .select('id, total_amount, order_status');
  final users = await client.from('users').select('id'); // ✅ 'profiles' → 'users'

  final totalRevenue = (orders as List).fold<double>(
    0,
        (sum, order) => sum + ((order['total_amount'] as num?)?.toDouble() ?? 0),
  );

  final pendingOrders =
      orders.where((e) => e['order_status'] == 'pending').length;

  return AdminStats(
    totalProducts: (products as List).length,
    totalOrders: orders.length,
    totalUsers: (users as List).length,
    pendingOrders: pendingOrders,
    totalRevenue: totalRevenue,
  );
});

// ─────────────────────────────────────────
// PRODUCTS
// ─────────────────────────────────────────

final adminProductsProvider = FutureProvider<List<Product>>((ref) async {
  final response = await Supabase.instance.client
      .from('products')
      .select('*')
      .order('created_at', ascending: false)
      .limit(100);

  return (response as List).map((json) => Product.fromJson(json)).toList();
});

class AdminProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final response = await Supabase.instance.client
        .from('products')
        .select('*')
        .order('created_at', ascending: false)
        .limit(100);

    return (response as List).map((json) => Product.fromJson(json)).toList();
  }

  Future<void> deleteProduct(String productId) async {
    await Supabase.instance.client
        .from('products')
        .delete()
        .eq('id', productId);

    state = AsyncData(
      state.value?.where((p) => p.id != productId).toList() ?? [],
    );
  }

  Future<void> toggleProductStatus(String productId, bool currentStatus) async {
    await Supabase.instance.client
        .from('products')
        .update({'is_active': !currentStatus})
        .eq('id', productId);

    state = AsyncData(
      state.value?.map((p) {
        if (p.id == productId) return p.copyWith(isActive: !currentStatus);
        return p;
      }).toList() ?? [],
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final adminProductsNotifierProvider =
AsyncNotifierProvider<AdminProductsNotifier, List<Product>>(
  AdminProductsNotifier.new,
);

// ─────────────────────────────────────────
// USERS
// ─────────────────────────────────────────

final adminUsersProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client
      .from('users') // ✅ 'profiles' → 'users'
      .select('*')
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response as List);
});

class AdminUsersNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final response = await Supabase.instance.client
        .from('users') // ✅ 'profiles' → 'users'
        .select('*')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> toggleUserStatus(String userId, bool currentStatus) async {
    await Supabase.instance.client
        .from('users') // ✅ 'profiles' → 'users'
        .update({'is_active': !currentStatus})
        .eq('id', userId);

    state = AsyncData(
      state.value?.map((u) {
        if (u['id'] == userId) {
          return {...u, 'is_active': !currentStatus};
        }
        return u;
      }).toList() ?? [],
    );
  }

  Future<void> deleteUser(String userId) async {
    // Soft delete — just deactivate
    await Supabase.instance.client
        .from('users') // ✅ 'profiles' → 'users'
        .update({'is_active': false})
        .eq('id', userId);

    state = AsyncData(
      state.value?.where((u) => u['id'] != userId).toList() ?? [],
    );
  }
}

final adminUsersNotifierProvider =
AsyncNotifierProvider<AdminUsersNotifier, List<Map<String, dynamic>>>(
  AdminUsersNotifier.new,
);

// ─────────────────────────────────────────
// ORDERS
// ─────────────────────────────────────────

Future<List<Order>> _fetchOrdersWithPackages() async {
  final response = await Supabase.instance.client
      .from('orders')
      .select('*, users(*), order_items(*, products(*))')
      .order('created_at', ascending: false);

  final orders = List<Map<String, dynamic>>.from(response as List);

  final packageIds = <String>{};
  for (final order in orders) {
    final items = order['order_items'] as List<dynamic>? ?? [];
    for (final item in items) {
      if (item is Map<String, dynamic> && item['package_id'] != null) {
        packageIds.add(item['package_id'] as String);
      }
    }
  }

  if (packageIds.isNotEmpty) {
    final packagesResponse = await Supabase.instance.client
        .from('design_packages')
        .select('*')
        .inFilter('id', packageIds.toList());

    final packagesMap = {
      for (final p in packagesResponse as List<dynamic>)
        (p as Map<String, dynamic>)['id'] as String: p
    };

    for (final order in orders) {
      final items = order['order_items'] as List<dynamic>? ?? [];
      for (final item in items) {
        if (item is Map<String, dynamic> &&
            item['package_id'] != null &&
            packagesMap.containsKey(item['package_id'])) {
          item['design_packages'] = packagesMap[item['package_id']];
        }
      }
    }
  }

  return orders.map((json) => Order.fromJson(json)).toList();
}

final adminOrdersProvider = FutureProvider<List<Order>>((ref) async {
  return _fetchOrdersWithPackages();
});

class AdminOrdersNotifier extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() async {
    return _fetchOrdersWithPackages();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await Supabase.instance.client
        .from('orders')
        .update({
      'order_status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', orderId);

    state = AsyncData(
      state.value?.map((o) {
        if (o.id == orderId) {
          final json = o.toJson();
          json['order_status'] = newStatus;
          return Order.fromJson(json);
        }
        return o;
      }).toList() ?? [],
    );
  }

  Future<void> deleteOrder(String orderId) async {
    await Supabase.instance.client
        .from('orders')
        .delete()
        .eq('id', orderId);

    state = AsyncData(
      state.value?.where((o) => o.id != orderId).toList() ?? [],
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final adminOrdersNotifierProvider =
AsyncNotifierProvider<AdminOrdersNotifier, List<Order>>(
  AdminOrdersNotifier.new,
);

// ─────────────────────────────────────────
// DESIGN PACKAGES
// ─────────────────────────────────────────

final adminPackagesProvider = FutureProvider<List<DesignPackage>>((ref) async {
  final response = await SupabaseService.getDesignPackages();
  return response.map((json) => DesignPackage.fromJson(json)).toList();
});

class AdminPackagesNotifier extends AsyncNotifier<List<DesignPackage>> {
  @override
  Future<List<DesignPackage>> build() async {
    final response = await SupabaseService.getDesignPackages();
    return response.map((json) => DesignPackage.fromJson(json)).toList();
  }

  Future<void> deletePackage(String packageId) async {
    await Supabase.instance.client
        .from('design_packages')
        .delete()
        .eq('id', packageId);

    state = AsyncData(
      state.value?.where((p) => p.id != packageId).toList() ?? [],
    );
  }

  Future<void> toggleFeatured(String packageId, bool currentStatus) async {
    await Supabase.instance.client
        .from('design_packages')
        .update({'is_featured': !currentStatus})
        .eq('id', packageId);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final adminPackagesNotifierProvider =
AsyncNotifierProvider<AdminPackagesNotifier, List<DesignPackage>>(
  AdminPackagesNotifier.new,
);