import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = ref.read(currentUserProvider);

    if (user != null) {
      try {
        // ✅ user_type চেক করুন
        final userData = await Supabase.instance.client
            .from('users')
            .select('user_type')
            .eq('id', user.id)
            .maybeSingle();

        final userType = userData?['user_type']?.toString().toLowerCase() ?? 'customer';

        print('🔍 Splash UserType: $userType');

        if (!mounted) return;

        // ✅ user_type অনুযায়ী route করুন
        if (userType == 'admin') {
          context.go('/admin');
        } else if (userType == 'designer') {
          context.go('/home'); // designer এর আলাদা route থাকলে দিন
        } else {
          context.go('/home');
        }

      } catch (e) {
        print('❌ Error: $e');
        if (mounted) {
          context.go('/home');
        }
      }
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chair_outlined,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Decovista',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Smart Interior Design & Furniture',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}