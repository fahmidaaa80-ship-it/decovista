import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../features/admin/screens/add_package_screen.dart';
import '../../features/admin/screens/add_product_screen.dart';
import '../../features/admin/screens/admin_banners_screen.dart';
import '../../features/admin/screens/admin_blog_posts_screen.dart';
import '../../features/admin/screens/admin_bookings_screen.dart';
import '../../features/admin/screens/admin_completed_projects_screen.dart';
import '../../features/admin/screens/admin_offers_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_orders_screen.dart';
import '../../features/admin/screens/admin_packages_screen.dart';
import '../../features/admin/screens/admin_products_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/booking/screens/consultation_booking_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/blog_detail_screen.dart';
import '../../features/prebuilt_designs/screens/customize_design_screen.dart';
import '../../features/prebuilt_designs/screens/my_designs_screen.dart';
import '../../features/profile/screens/about_us_screen.dart';
import '../../features/profile/screens/bookings_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/help_center_screen.dart';
import '../../features/profile/screens/orders_screen.dart';
import '../../features/profile/screens/payment_methods_screen.dart';
import '../../features/profile/screens/privacy_policy_screen.dart';
import '../../features/profile/screens/wishlist_screen.dart';
import '../../features/shop/screens/shop_screen.dart';
import '../../features/shop/screens/product_detail_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/cart/screens/checkout_screen.dart';
import '../../features/prebuilt_designs/screens/designs_list_screen.dart';
import '../../features/prebuilt_designs/screens/design_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  String? cachedRole;

  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final user = SupabaseService.currentUser;
      final location = state.matchedLocation;

      const publicRoutes = ['/', '/onboarding', '/login', '/register'];
      final isPublic = publicRoutes.contains(location);
      final isAdminRoute = location.startsWith('/admin');

      // Login নেই + protected route → login এ পাঠাও
      if (user == null && !isPublic) return '/login';

      // Login/register page এ redirect করো না
      // login screen নিজেই role check করে navigate করবে
      if (user != null && (location == '/login' || location == '/register')) {
        return null;
      }

      // Admin route → role check
      if (isAdminRoute && user != null) {
        try {
          cachedRole ??= await Supabase.instance.client
              .from('users')
              .select('role')
              .eq('id', user.id)
              .single()
              .then((data) => data['role'] as String?);

          if (cachedRole != 'admin') return '/home';
        } catch (_) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/shop',
        name: 'shop',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final category = extra?['category'] as String? ?? state.uri.queryParameters['category'];
          final featured = extra?['featured'] as bool? ?? state.uri.queryParameters['featured'] == 'true';
          final hideSearch = extra?['hideSearch'] as bool? ?? false;
          return ShopScreen(initialCategory: category, featuredOnly: featured, hideSearch: hideSearch);
        },
      ),
      GoRoute(
        path: '/product/:id',
        name: 'product-detail',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ProductDetailScreen(productId: productId);
        },
      ),

      GoRoute(
        path: '/profile/my-designs',
        name: 'my-designs',
        builder: (context, state) => const MyDesignsScreen(),
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CheckoutScreen(buyNowData: extra);
        },
      ),
      GoRoute(
        path: '/profile/bookings',
        builder: (context, state) => const BookingsScreen(),
      ),
      GoRoute(
        path: '/designs',
        name: 'designs',
        builder: (context, state) {
          final roomType = state.uri.queryParameters['roomType'];
          return DesignsListScreen(roomType: roomType);
        },
      ),
      GoRoute(
        path: '/design/:id',
        name: 'design-detail',
        builder: (context, state) {
          final designId = state.pathParameters['id']!;
          return DesignDetailScreen(designId: designId);
        },
      ),
      GoRoute(
        path: '/blog/:id',
        name: 'blog-detail',
        builder: (context, state) {
          final blogId = state.pathParameters['id']!;
          return BlogDetailScreen(blogId: blogId);
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/orders',
        name: 'orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/profile/wishlist',
        name: 'wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/payment-methods',
        name: 'payment-methods',
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/profile/help',
        name: 'help-center',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/profile/about',
        name: 'about-us',
        builder: (context, state) => const AboutUsScreen(),
      ),
      GoRoute(
        path: '/profile/privacy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/booking',
        name: 'booking',
        builder: (context, state) => const ConsultationBookingScreen(),
      ),
      GoRoute(
        path: '/design/:id/customize',
        name: 'customize-design',
        builder: (context, state) {
          final designId = state.pathParameters['id']!;
          return CustomizeDesignScreen(designId: designId);
        },
      ),

      // ── Admin Routes ──
      GoRoute(
        path: '/admin',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        name: 'admin-products',
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: '/admin/products/add',
        name: 'add-product',
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: '/admin/products/edit/:id',
        name: 'edit-product',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return AddProductScreen(productId: productId);
        },
      ),
      GoRoute(
        path: '/admin/orders',
        name: 'admin-orders',
        builder: (context, state) => AdminOrdersScreen(
          initialStatusFilter: state.uri.queryParameters['status'],
        ),
      ),
      GoRoute(
        path: '/admin/packages',
        name: 'admin-packages',
        builder: (context, state) => const AdminPackagesScreen(),
      ),

      GoRoute(
        path: '/admin/packages/add',
        name: 'add-package-design',
        builder: (context, state) => const AddPackageScreen(),
      ),
      GoRoute(
        path: '/admin/packages/edit/:id',
        name: 'edit-package-design',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddPackageScreen(packageId: id);
        },
      ),

      GoRoute(
        path: '/admin/bookings',
        name: 'admin-bookings',
        builder: (context, state) => const AdminBookingsScreen(),
      ),

      GoRoute(
        path: '/admin/users',
        name: 'admin-users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/banners',
        name: 'admin-banners',
        builder: (context, state) => const AdminBannersScreen(),
      ),
      GoRoute(
        path: '/admin/offers',
        name: 'admin-offers',
        builder: (context, state) => const AdminOffersScreen(),
      ),
      GoRoute(
        path: '/admin/completed-projects',
        name: 'admin-completed-projects',
        builder: (context, state) => const AdminCompletedProjectsScreen(),
      ),
      GoRoute(
        path: '/admin/blog-posts',
        name: 'admin-blog-posts',
        builder: (context, state) => const AdminBlogPostsScreen(),
      ),
    ],
  );

  // Auth change হলে cache clear করো + router refresh
  SupabaseService.authStateChanges.listen((_) {
    cachedRole = null;
    router.refresh();
  });

  return router;
});