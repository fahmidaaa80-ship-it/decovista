import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/banner_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/offer_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/completed_project_provider.dart';
import '../../../providers/blog_post_provider.dart';
import '../../shop/screens/shop_screen.dart';
import '../../prebuilt_designs/screens/designs_list_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../widgets/hero_section.dart';
import '../widgets/offer_section.dart';
import '../widgets/featured_products.dart';
import '../widgets/room_categories.dart';
import '../widgets/customer_reviews.dart';
import '../widgets/completed_projects.dart';
import '../widgets/blog_section.dart';
import '../widgets/consultation_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeTabScreen(),
    const ShopScreen(),
    const DesignsListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.design_services_outlined),
            activeIcon: Icon(Icons.design_services),
            label: 'Designs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTabScreen extends ConsumerWidget {
  const _HomeTabScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Decovista'),
        actions: [
          // Cart
          Stack(
            children: [
              IconButton(
                onPressed: () => context.push('/cart'),
                icon: const Icon(Icons.shopping_cart_outlined),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Consumer(
                  builder: (context, ref, child) {
                    final count = ref.watch(cartCountProvider);
                    if (count == 0) return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        count > 9 ? '9+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(bannersProvider);
          ref.invalidate(offersProvider);
          ref.invalidate(featuredProductsProvider);
          ref.invalidate(completedProjectsProvider);
          ref.invalidate(blogPostsProvider);
        },
        child: const SingleChildScrollView(
          child: Column(
            children: [
              // Hero Section with promotional banner
              HeroSection(),

              SizedBox(height: 24),

              // Offers & Discounts
              OfferSection(),

              SizedBox(height: 24),

              // Featured Products
              FeaturedProducts(),

              SizedBox(height: 24),

              // Room Design Categories
              RoomCategories(),

              SizedBox(height: 24),

              // Customer Reviews
              CustomerReviews(),

              SizedBox(height: 24),

              // Completed Projects
              CompletedProjects(),

              SizedBox(height: 24),

              // Blog Section
              BlogSection(),

              SizedBox(height: 24),

              // Consultation Section
              ConsultationSection(),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}