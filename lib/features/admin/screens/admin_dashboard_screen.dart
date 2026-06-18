import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../data/models/order_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminUserAsync = ref.watch(adminUserProvider);
    final statsAsync = ref.watch(adminStatsProvider);

    return adminUserAsync.when(
      data: (userData) {
        final userType = userData?['user_type']?.toString().toLowerCase() ?? '';

        if (userType != 'admin') {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Access Denied',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('You do not have admin privileges'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(adminStatsProvider);
                  ref.invalidate(adminUserProvider);
                },
              ),
            ],
          ),
          drawer: _buildAdminDrawer(context, userData),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminStatsProvider);
              ref.invalidate(adminUserProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${userData?['full_name'] ?? 'Admin'}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Here\'s what\'s happening with your store today',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats Cards
                  statsAsync.when(
                    data: (stats) => Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatsCard(
                                icon: Icons.shopping_bag_outlined,
                                title: 'Total Orders',
                                value: stats.totalOrders.toString(),
                                gradientColors: const [
                                  Color(0xFF2D5F5D),
                                  Color(0xFF4A8886),
                                ],
                                onTap: () => context.push('/admin/orders'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatsCard(
                                icon: Icons.people_outline,
                                title: 'Total Users',
                                value: stats.totalUsers.toString(),
                                gradientColors: const [
                                  Color(0xFF5C6BC0),
                                  Color(0xFF7986CB),
                                ],
                                onTap: () => context.push('/admin/users'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatsCard(
                                icon: Icons.inventory_2_outlined,
                                title: 'Products',
                                value: stats.totalProducts.toString(),
                                gradientColors: const [
                                  Color(0xFFAB47BC),
                                  Color(0xFFCE93D8),
                                ],
                                onTap: () => context.push('/admin/products'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatsCard(
                                icon: Icons.pending_actions_outlined,
                                title: 'Pending Orders',
                                value: stats.pendingOrders.toString(),
                                gradientColors: const [
                                  Color(0xFFFFA726),
                                  Color(0xFFFFB74D),
                                ],
                                onTap: () => context.push('/admin/orders'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF4CAF50),
                                Color(0xFF66BB6A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Total Revenue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '৳${stats.totalRevenue.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    loading: () => const LoadingWidget(),
                    error: (error, stack) => Center(
                      child: Text('Error loading stats: $error'),
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _QuickActionCard(
                        icon: Icons.add_box_outlined,
                        title: 'Add Product',
                        color: AppColors.primary,
                        onTap: () => context.push('/admin/products/add'),
                      ),
                      _QuickActionCard(
                        icon: Icons.design_services_outlined,
                        title: 'Add Design Package',
                        color: const Color(0xFFAB47BC),
                        onTap: () => context.push('/admin/packages/add'),
                      ),
                      _QuickActionCard(
                        icon: Icons.list_alt,
                        title: 'View Orders',
                        color: const Color(0xFF5C6BC0),
                        onTap: () => context.push('/admin/orders'),
                      ),
                      _QuickActionCard(
                        icon: Icons.calendar_today_outlined,
                        title: 'Manage Bookings',
                        color: const Color(0xFF26A69A),
                        onTap: () => context.push('/admin/bookings'),
                      ),
                      _QuickActionCard(
                        icon: Icons.image_outlined,
                        title: 'Manage Banners',
                        color: const Color(0xFFFFA726),
                        onTap: () => context.push('/admin/banners'),
                      ),
                      _QuickActionCard(
                        icon: Icons.local_offer_outlined,
                        title: 'Manage Offers',
                        color: const Color(0xFFEF5350),
                        onTap: () => context.push('/admin/offers'),
                      ),
                      _QuickActionCard(
                        icon: Icons.construction_outlined,
                        title: 'Completed Projects',
                        color: const Color(0xFF42A5F5),
                        onTap: () => context.push('/admin/completed-projects'),
                      ),
                      _QuickActionCard(
                        icon: Icons.article_outlined,
                        title: 'Blog Posts',
                        color: const Color(0xFF8D6E63),
                        onTap: () => context.push('/admin/blog-posts'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/admin/orders'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const _RecentOrdersList(),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: LoadingWidget(),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildAdminDrawer(BuildContext context, Map<String, dynamic>? userData) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                  AppColors.primaryLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userData?['email'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerSection('Main'),
                _drawerItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  isActive: true,
                  onTap: () => Navigator.pop(context),
                ),
                _drawerSection('Management'),
                _drawerItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Products',
                  iconColor: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/products');
                  },
                ),
                _drawerItem(
                  icon: Icons.design_services_outlined,
                  title: 'Design Packages',
                  iconColor: const Color(0xFFAB47BC),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/packages');
                  },
                ),
                _drawerItem(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Orders',
                  iconColor: const Color(0xFF5C6BC0),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/orders');
                  },
                ),
                _drawerItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Bookings',
                  iconColor: const Color(0xFF26A69A),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/bookings');
                  },
                ),
                const Divider(),
                _drawerSection('Content'),
                _drawerItem(
                  icon: Icons.people_outline,
                  title: 'Users',
                  iconColor: const Color(0xFFEF5350),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/users');
                  },
                ),
                _drawerItem(
                  icon: Icons.image_outlined,
                  title: 'Banners',
                  iconColor: const Color(0xFFFFA726),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/banners');
                  },
                ),
                _drawerItem(
                  icon: Icons.local_offer_outlined,
                  title: 'Offers',
                  iconColor: const Color(0xFF42A5F5),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/offers');
                  },
                ),
                _drawerItem(
                  icon: Icons.construction_outlined,
                  title: 'Completed Projects',
                  iconColor: const Color(0xFF66BB6A),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/completed-projects');
                  },
                ),
                _drawerItem(
                  icon: Icons.article_outlined,
                  title: 'Blog Posts',
                  iconColor: const Color(0xFF8D6E63),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/blog-posts');
                  },
                ),
                const Divider(),
                _drawerSection('Account'),
                _drawerItem(
                  icon: Icons.exit_to_app,
                  title: 'Back to App',
                  iconColor: AppColors.grey,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.08) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withOpacity(0.12)
                : (iconColor ?? AppColors.primary).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? AppColors.primary : (iconColor ?? AppColors.textPrimary),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const _StatsCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentOrdersList extends ConsumerWidget {
  const _RecentOrdersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersNotifierProvider);

    return ordersAsync.when(
      data: (orders) {
        final recentOrders = orders.take(5).toList();

        if (recentOrders.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No recent orders'),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentOrders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = recentOrders[index];
            return _RecentOrderCard(order: order);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}

class _RecentOrderCard extends StatelessWidget {
  final Order order;

  const _RecentOrderCard({required this.order});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'processing':
        return AppColors.info;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.orderStatus);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/admin/orders'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.orderNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.shippingAddress['full_name'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (order.items.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 32,
                          child: Row(
                            children: order.items.take(3).map((item) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: item.itemImage.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: item.itemImage,
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          width: 32, height: 32,
                                          color: AppColors.greyLight,
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          width: 32, height: 32,
                                          color: AppColors.greyLight,
                                          child: const Icon(Icons.image, size: 16),
                                        ),
                                      )
                                    : Container(
                                        width: 32, height: 32,
                                        color: AppColors.greyLight,
                                        child: const Icon(Icons.image, size: 16),
                                      ),
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '৳${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.orderStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
