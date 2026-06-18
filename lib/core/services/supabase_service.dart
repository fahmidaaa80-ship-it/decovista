import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Auth Methods
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    // Create user profile
    if (response.user != null) {
      await _client.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'full_name': fullName,
      });
    }

    return response;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'decovista://login-callback/',
    );
  }

  static Future<void> signInWithFacebook() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: 'decovista://login-callback/',
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static User? get currentUser => _client.auth.currentUser;

  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Products Methods
  static Future<List<Map<String, dynamic>>> getProducts({
    String? category,
    bool? isFeatured,
    bool? isNew,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _client
        .from('products')
        .select('*, categories(*)')
        .eq('is_active', true);

    if (category != null) {
      query = query.eq('category_id', category);
    }

    if (isFeatured != null) {
      query = query.eq('is_featured', isFeatured);
    }

    if (isNew != null) {
      query = query.eq('is_new', isNew);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getProductsByCategoryName(String categoryName) async {
    final categoryResponse = await _client
        .from('categories')
        .select('id')
        .ilike('name', categoryName);

    final categories = List<Map<String, dynamic>>.from(categoryResponse);
    if (categories.isEmpty) return [];

    final ids = categories.map((c) => c['id'] as String).toList();

    final response = await _client
        .from('products')
        .select('*, categories(*)')
        .eq('is_active', true)
        .inFilter('category_id', ids)
        .order('created_at', ascending: false)
        .limit(100);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> getProductById(String id) async {
    final response = await _client
        .from('products')
        .select('*, categories(*)')
        .eq('id', id)
        .single();

    return response;
  }

  static Future<List<Map<String, dynamic>>> searchProducts(String query, {String? category}) async {
    var req = _client
        .from('products')
        .select('*, categories(*)')
        .eq('is_active', true);

    if (category != null && category != 'All') {
      req = req.filter('categories.name', 'ilike', category);
    }

    final response = await req
        .or('name.ilike.%$query%,description.ilike.%$query%,material.ilike.%$query%')
        .order('created_at', ascending: false)
        .limit(20);

    return List<Map<String, dynamic>>.from(response);
  }

  // Categories Methods
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .eq('is_active', true);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> ensureCategoriesExist() async {
    final existing = await getCategories();
    if (existing.isNotEmpty) return;
    final defaults = [
      {'name': 'Living Room', 'description': 'Living room furniture and decor', 'is_active': true},
      {'name': 'Bedroom', 'description': 'Bedroom furniture and decor', 'is_active': true},
      {'name': 'Kitchen', 'description': 'Kitchen furniture and accessories', 'is_active': true},
      {'name': 'Dining Room', 'description': 'Dining room furniture', 'is_active': true},
      {'name': 'Office', 'description': 'Office furniture and decor', 'is_active': true},
      {'name': 'Bathroom', 'description': 'Bathroom accessories and storage', 'is_active': true},
      {'name': 'Outdoor', 'description': 'Outdoor and garden furniture', 'is_active': true},
      {'name': 'Study Room', 'description': 'Study and home office furniture', 'is_active': true},
      {'name': 'Decor', 'description': 'Home decoration items', 'is_active': true},
    ];
    for (final cat in defaults) {
      try {
        await _client.from('categories').insert(cat);
      } catch (_) {}
    }
  }

  // Design Packages Methods
  static Future<List<Map<String, dynamic>>> getDesignPackages({
    String? roomType,
    bool? isFeatured,
  }) async {
    var query = _client.from('design_packages').select();

    if (roomType != null) {
      query = query.eq('room_type', roomType);
    }

    if (isFeatured != null) {
      query = query.eq('is_featured', isFeatured);
    }

    final response = await query.order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // static Future<Map<String, dynamic>> getPackageById(String id) async {
  //   final response = await _client
  //       .from('design_packages')
  //       .select('*, package_items(*, products(*))')
  //       .eq('id', id)
  //       .single();
  //
  //   return response;
  // }

  // Cart Methods
  static Future<void> addToCart({
    required String userId,
    String? productId,
    String? packageId,
    required int quantity,
    Map<String, dynamic>? customizations,
  }) async {
    await _client.from('cart').insert({
      'user_id': userId,
      'product_id': productId,
      'package_id': packageId,
      'quantity': quantity,
      'is_package': packageId != null,
      'customizations': customizations,
    });
  }
  //
  // static Future<List<Map<String, dynamic>>> getCart(String userId) async {
  //   final response = await _client
  //       .from('cart')
  //       .select('*, products(*), design_packages(*)')
  //       .eq('user_id', userId);
  //
  //   return List<Map<String, dynamic>>.from(response);
  // }

  static Future<void> updateCartItem({
    required String cartId,
    required int quantity,
  }) async {
    await _client
        .from('cart')
        .update({'quantity': quantity})
        .eq('id', cartId);
  }

  static Future<void> removeFromCart(String cartId) async {
    await _client.from('cart').delete().eq('id', cartId);
  }

  static Future<void> clearCart(String userId) async {
    await _client.from('cart').delete().eq('user_id', userId);
  }

  // Wishlist Methods
  static Future<void> addToWishlist({
    required String userId,
    required String productId,
  }) async {
    await _client.from('wishlist').insert({
      'user_id': userId,
      'product_id': productId,
    });
  }
  static Future<List<Map<String, dynamic>>> getOrders(String userId) async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*, products(*))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final orders = List<Map<String, dynamic>>.from(response);

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
      final packagesResponse = await _client
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

    return orders;
  }
  static Future<void> removeFromWishlist({
    required String userId,
    required String productId,
  }) async {
    await _client
        .from('wishlist')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }

  static Future<List<Map<String, dynamic>>> getWishlist(String userId) async {
    final response = await _client
        .from('wishlist')
        .select('*, products(*)')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }

  // Orders Methods
  static Future<Map<String, dynamic>> createOrder({
    required String userId,
    required double totalAmount,
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    // Generate order number
    final orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch}';

    // Create order
    final orderResponse = await _client.from('orders').insert({
      'order_number': orderNumber,
      'user_id': userId,
      'total_amount': totalAmount,
      'shipping_address': shippingAddress,
      'payment_method': paymentMethod,
      'order_status': 'pending',
      'payment_status': 'pending',
    }).select().single();

    // Create order items
    final orderItems = items.map((item) => {
      'order_id': orderResponse['id'],
      'product_id': item['product_id'],
      'package_id': item['package_id'],
      'quantity': item['quantity'],
      'price': item['price'],
      'is_package': item['is_package'],
      'customizations': item['customizations'],
    }).toList();

    await _client.from('order_items').insert(orderItems);

    return orderResponse;
  }
  //
  // static Future<List<Map<String, dynamic>>> getOrders(String userId) async {
  //   final response = await _client
  //       .from('orders')
  //       .select('*, order_items(*, products(*), design_packages(*))')
  //       .eq('user_id', userId)
  //       .order('created_at', ascending: false);
  //
  //   return List<Map<String, dynamic>>.from(response);
  // }

  static Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*, products(*))')
        .eq('id', orderId)
        .single();

    final order = Map<String, dynamic>.from(response);
    final items = order['order_items'] as List<dynamic>? ?? [];

    final packageIds = <String>{};
    for (final item in items) {
      if (item is Map<String, dynamic> && item['package_id'] != null) {
        packageIds.add(item['package_id'] as String);
      }
    }

    if (packageIds.isNotEmpty) {
      final packagesResponse = await _client
          .from('design_packages')
          .select('*')
          .inFilter('id', packageIds.toList());

      final packagesMap = {
        for (final p in packagesResponse as List<dynamic>)
          (p as Map<String, dynamic>)['id'] as String: p
      };

      for (final item in items) {
        if (item is Map<String, dynamic> &&
            item['package_id'] != null &&
            packagesMap.containsKey(item['package_id'])) {
          item['design_packages'] = packagesMap[item['package_id']];
        }
      }
    }

    return order;
  }
  // Bookings Methods
  // static Future<void> createBooking({
  //   required String userId,
  //   required String designerId,
  //   required DateTime bookingDate,
  //   required String bookingTime,
  //   required String meetingType,
  //   String? meetingLink,
  //   double? paymentAmount,
  //   String? notes,
  // }) async {
  //   await _client.from('bookings').insert({
  //     'user_id': userId,
  //     'designer_id': designerId,
  //     'booking_date': bookingDate.toIso8601String(),
  //     'booking_time': bookingTime,
  //     'meeting_type': meetingType,
  //     'meeting_link': meetingLink,
  //     'payment_amount': paymentAmount,
  //     'notes': notes,
  //   });
  // }

  static Future<void> createBooking({
    required String userId,
    String? designerId, // ✅ nullable করো
    required DateTime bookingDate,
    required String bookingTime,
    required String meetingType,
    String? meetingLink,
    double? paymentAmount,
    String? notes,
  }) async {
    await _client.from('bookings').insert({
      'user_id': userId,
      if (designerId != null) 'designer_id': designerId, // ✅ null হলে পাঠাবে না
      'booking_date': bookingDate.toIso8601String(),
      'booking_time': bookingTime,
      'meeting_type': meetingType,
      if (meetingLink != null) 'meeting_link': meetingLink,
      if (paymentAmount != null) 'payment_amount': paymentAmount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  // static Future<List<Map<String, dynamic>>> getBookings(String userId) async {
  //   final response = await _client
  //       .from('bookings')
  //       .select('*, users!designer_id(*)')
  //       .eq('user_id', userId)
  //       .order('booking_date', ascending: false);
  //
  //   return List<Map<String, dynamic>>.from(response);
  // }

  // Reviews Methods
  static Future<void> addReview({
    required String userId,
    String? productId,
    String? packageId,
    required int rating,
    String? title,
    String? comment,
    List<String>? images,
  }) async {
    await _client.from('reviews').insert({
      'user_id': userId,
      'product_id': productId,
      'package_id': packageId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'images': images,
    });
  }
  static Future<List<Map<String, dynamic>>> getCart(String userId) async {
    final cartResponse = await _client
        .from('cart')
        .select('*, products(*), design_packages(*)')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(cartResponse);
  }

  static Future<List<Map<String, dynamic>>> getProductReviews(String productId) async {
    final response = await _client
        .from('reviews')
        .select('*, users(*)')
        .eq('product_id', productId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getReviews() async {
    final response = await _client
        .from('reviews')
        .select('*, users(full_name, avatar_url, profile_img)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> addHomeReview({
    required String userId,
    required String comment,
  }) async {
    await _client.from('reviews').insert({
      'user_id': userId,
      'rating': 5,
      'comment': comment,
    });
  }

  static Future<List<Map<String, dynamic>>> getBookings(String userId) async {
    final response = await _client
        .from('bookings')
        .select('*') // ✅ simple query
        .eq('user_id', userId)
        .order('booking_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }



  // Image upload - XFile direct use করো
  static Future<List<String>> uploadProductImages({
    required List<XFile> images,
    required String productName,
  }) async {
    final List<String> urls = [];
    final cleanName = productName.replaceAll(' ', '_').toLowerCase();

    for (int i = 0; i < images.length; i++) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'products/${cleanName}_${timestamp}_$i.jpg';

      final file = File(images[i].path);
      await _client.storage.from('product-images').upload(path, file);

      final url = _client.storage
          .from('product-images')
          .getPublicUrl(path);
      urls.add(url);
    }

    return urls;
  }

// Product add - category name থেকে ID বের করে save করে
  static Future<Map<String, dynamic>> addProduct({
    required String name,
    required String description,
    required String categoryName,
    required double price,
    double? discountPrice,
    required String material,
    required int stock,
    required bool isFeatured,
    required bool isNew,
    required List<String> imageUrls,
  }) async {
    // Category ID বের করো
    final categoryResponse = await _client
        .from('categories')
        .select('id')
        .eq('name', categoryName)
        .maybeSingle();

    final response = await _client.from('products').insert({
      'name': name,
      'description': description,
      'category_id': categoryResponse?['id'],
      'price': price,
      'discount_price': discountPrice,
      'material': material,
      'stock': stock,
      'is_featured': isFeatured,
      'is_new': isNew,
      'images': imageUrls,
      'is_active': true,
      'rating': 0.0,
      'review_count': 0,
      'colors': [],
    }).select().single();

    return response;
  }

  // ===== PRODUCTS =====
  static Future<void> deleteProduct(String productId) async {
    await _client.from('products').delete().eq('id', productId);
  }

  static Future<void> toggleProductStatus({
    required String productId,
    required bool isActive,
  }) async {
    await _client
        .from('products')
        .update({'is_active': isActive})
        .eq('id', productId);
  }

  static Future<void> updateProduct({
    required String productId,
    required Map<String, dynamic> data,
  }) async {
    await _client
        .from('products')
        .update(data)
        .eq('id', productId);
  }

// ===== ORDERS =====
  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _client
        .from('orders')
        .update({'order_status': status})
        .eq('id', orderId);
  }

  static Future<Map<String, dynamic>> getPackageById(String id) async {
    final response = await _client
        .from('design_packages')
        .select('*')        // join বাদ দাও
        .eq('id', id)
        .single();

    return response;
  }

// // ===== USERS =====
//   static Future<void> updateUserRole({
//     required String userId,
//     required String role,
//   }) async {
//     await _client
//         .from('users')
//         .update({'user_type': role})
//         .eq('id', userId);
//   }



  static Future<void> toggleUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    await _client
        .from('users')
        .update({'is_active': isActive})
        .eq('id', userId);
  }

  static Future<void> cancelBooking(String bookingId) async {
    await _client
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId);
  }

  static Future<void> cancelOrder(String orderId) async {
    await _client
        .from('orders')
        .update({'order_status': 'cancelled'})
        .eq('id', orderId);
  }

  static Future<void> clearWishlist(String userId) async {
    await _client
        .from('wishlist')
        .delete()
        .eq('user_id', userId);
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

// ===== USER DESIGNS =====
  static Future<void> saveUserDesign({
    required String userId,
    required String packageId,
    Map<String, dynamic>? customizations,
  }) async {
    await _client.from('user_designs').upsert({
      'user_id': userId,
      'package_id': packageId,
      'customizations': customizations,
    }, onConflict: 'user_id, package_id');
  }

  static Future<List<Map<String, dynamic>>> getUserDesigns(String userId) async {
    final response = await _client
        .from('user_designs')
        .select('*, design_packages(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response;
  }

  static Future<void> deleteUserDesign(String designId) async {
    await _client.from('user_designs').delete().eq('id', designId);
  }

// ===== PACKAGES =====
  static Future<void> deletePackage(String packageId) async {
    await _client.from('design_packages').delete().eq('id', packageId);
  }

  static Future<Map<String, dynamic>> addPackage({
    required String name,
    required String description,
    required String roomType,
    required String style,
    required double price,
    double? discountPrice,
    required bool isFeatured,
    required bool isCustomizable,
    required List<String> imageUrls,
    String? estimatedBudget,
    String? roomSize,
  }) async {
    final response = await _client.from('design_packages').insert({
      'name': name,
      'description': description,
      'room_type': roomType,
      'style': style,
      'price': price,
      'discount_price': discountPrice,
      'is_featured': isFeatured,
      'is_customizable': isCustomizable,
      'preview_image': imageUrls.isNotEmpty ? imageUrls.first : null,
      'images': imageUrls,
      'estimated_budget': estimatedBudget != null
          ? double.tryParse(estimatedBudget)
          : null,
      'room_size': roomSize,
      'rating': 0.0,
      'review_count': 0,
      'wall_color_suggestions': [],
    }).select().single();

    return response;
  }

  static Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    await _client
        .from('users')
        .update({'role': role})
        .eq('id', userId);
  }

  static Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _client.from('users').update(data).eq('id', userId);
  }



  // ===== BANNERS =====
  static Future<List<Map<String, dynamic>>> getBanners() async {
    final response = await _client
        .from('banners')
        .select('*')
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> addBanner(Map<String, dynamic> data) async {
    await _client.from('banners').insert(data);
  }

  static Future<void> updateBanner(String id, Map<String, dynamic> data) async {
    await _client.from('banners').update(data).eq('id', id);
  }

  static Future<void> deleteBanner(String id) async {
    await _client.from('banners').delete().eq('id', id);
  }

  // ===== OFFERS =====
  static Future<List<Map<String, dynamic>>> getAdminOffers() async {
    final response = await _client
        .from('offers')
        .select('*')
        .order('sort_order', ascending: true)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getOffers() async {
    final response = await _client
        .from('offers')
        .select('*')
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> addOffer(Map<String, dynamic> data) async {
    await _client.from('offers').insert(data);
  }

  static Future<void> updateOffer(String id, Map<String, dynamic> data) async {
    await _client.from('offers').update(data).eq('id', id);
  }

  static Future<void> deleteOffer(String id) async {
    await _client.from('offers').delete().eq('id', id);
  }

  // ===== COMPLETED PROJECTS =====
  static Future<List<Map<String, dynamic>>> getCompletedProjects({bool? activeOnly}) async {
    var query = _client.from('completed_projects').select();
    if (activeOnly == true) {
      query = query.eq('is_active', true);
    }
    final response = await query.order('sort_order', ascending: true).order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> addCompletedProject(Map<String, dynamic> data) async {
    await _client.from('completed_projects').insert(data);
  }

  static Future<void> updateCompletedProject(String id, Map<String, dynamic> data) async {
    await _client.from('completed_projects').update(data).eq('id', id);
  }

  static Future<void> deleteCompletedProject(String id) async {
    await _client.from('completed_projects').delete().eq('id', id);
  }

  // ===== BLOG POSTS =====
  static Future<List<Map<String, dynamic>>> getBlogPosts({bool? activeOnly}) async {
    var query = _client.from('blog_posts').select();
    if (activeOnly == true) {
      query = query.eq('is_active', true);
    }
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> getBlogPostById(String id) async {
    final response = await _client
        .from('blog_posts')
        .select()
        .eq('id', id)
        .single();
    return response;
  }

  static Future<void> addBlogPost(Map<String, dynamic> data) async {
    await _client.from('blog_posts').insert(data);
  }

  static Future<void> updateBlogPost(String id, Map<String, dynamic> data) async {
    await _client.from('blog_posts').update(data).eq('id', id);
  }

  static Future<void> deleteBlogPost(String id) async {
    await _client.from('blog_posts').delete().eq('id', id);
  }

  // File Upload (Storage)
  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required String filePath,
  }) async {
    await _client.storage.from(bucket).upload(path, File(filePath));

    final url = _client.storage.from(bucket).getPublicUrl(path);
    return url;
  }
}