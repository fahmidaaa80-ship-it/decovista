import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userProfile = ref.watch(userProfileProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 80, color: AppColors.grey),
              const SizedBox(height: 16),
              const Text('Please login to view your profile',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              CustomButton(text: 'Login', onPressed: () => context.go('/login')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: userProfile.when(
        data: (profile) {
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  backgroundImage: profile?.profileImg != null
                      ? MemoryImage(base64Decode(profile!.profileImg!))
                      : (profile?.avatarUrl != null
                          ? NetworkImage(profile!.avatarUrl!)
                          : null),
                  child: profile?.profileImg == null && profile?.avatarUrl == null
                      ? Text(
                          profile?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  profile?.fullName ?? 'User',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.email ?? '',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CustomButton(
                    text: 'Edit Profile',
                    onPressed: () => context.push('/profile/edit'),
                    isOutlined: true,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(height: 32),

                // Shopping
                _buildSection(
                  context,
                  title: 'Shopping',
                  items: [
                    _MenuItem(icon: Icons.shopping_bag_outlined, title: 'My Orders', onTap: () => context.push('/profile/orders')),
                    _MenuItem(icon: Icons.favorite_outline, title: 'Wishlist', onTap: () => context.push('/profile/wishlist')),
                    _MenuItem(icon: Icons.design_services_outlined, title: 'My Designs', onTap: () => context.push('/profile/my-designs')),
                  ],
                ),
                const SizedBox(height: 16),

                // Consultations
                _buildSection(
                  context,
                  title: 'Consultations',
                  items: [
                    _MenuItem(icon: Icons.calendar_today_outlined, title: 'My Bookings', onTap: () => context.push('/profile/bookings')),
                  ],
                ),
                const SizedBox(height: 16),

                // Account
                _buildSection(
                  context,
                  title: 'Account',
                  items: [
                    _MenuItem(icon: Icons.payment_outlined, title: 'Payment Methods', onTap: () => context.push('/profile/payment-methods')),
                  ],
                ),
                const SizedBox(height: 16),

                // Support
                _buildSection(
                  context,
                  title: 'Support',
                  items: [
                    _MenuItem(icon: Icons.help_outline, title: 'Help Center', onTap: () => context.push('/profile/help')),
                    _MenuItem(icon: Icons.info_outline, title: 'About Us', onTap: () => context.push('/profile/about')),
                    _MenuItem(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () => context.push('/profile/privacy')),
                  ],
                ),
                const SizedBox(height: 32),

                // Logout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CustomButton(
                    text: 'Logout',
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () async {
                                if (dialogContext.mounted) Navigator.pop(dialogContext);
                                await ref.read(authControllerProvider.notifier).signOut();
                              },
                              child: const Text('Logout', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                    },
                    backgroundColor: AppColors.error,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<_MenuItem> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon, color: AppColors.primary),
                    title: Text(item.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
                    onTap: item.onTap,
                  ),
                  if (index < items.length - 1) const Divider(height: 1, indent: 60),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuItem({required this.icon, required this.title, required this.onTap});
}
