import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _navigateBasedOnUserType() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }
      final userData = await Supabase.instance.client
          .from('users')
          .select('user_type')
          .eq('id', user.id)
          .maybeSingle();
      final userType = userData?['user_type']?.toString().toLowerCase() ?? 'customer';
      if (!mounted) return;
      if (userType == 'admin') {
        context.go('/admin');
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleSocialSignIn(String provider) async {
    try {
      if (provider == 'google') {
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
      } else {
        await ref.read(authControllerProvider.notifier).signInWithFacebook();
      }
      if (mounted) await _navigateBasedOnUserType();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$provider sign in failed'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier).signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    final authState = ref.read(authControllerProvider);

    await authState.when(
      data: (_) async {
        if (!mounted) return;

        try {
          // ✅ 'role' এর বদলে 'user_type' সিলেক্ট করুন
          final userData = await Supabase.instance.client
              .from('users')
              .select('user_type')
              .eq('id', SupabaseService.currentUser!.id)
              .maybeSingle();

          // ✅ UserModel ব্যবহার না করে সরাসরি value নিন
          final userType = userData?['user_type']?.toString().toLowerCase() ?? 'customer';

          print('🔍 UserType: $userType');

          if (!mounted) return;

          if (userType == 'admin') {
            context.go('/admin');
          } else if (userType == 'designer') {
            context.go('/home'); // designer এর জন্য আলাদা route থাকলে দিন
          } else {
            context.go('/home');
          }

        } catch (e) {
          print('❌ Error fetching user type: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Something went wrong: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
      error: (error, _) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      loading: () {},
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    bool sending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your registered email to receive a password reset link',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Email',
                    hint: 'Enter your email',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: sending ? null : () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: sending
                              ? null
                              : () async {
                                  final email = emailController.text.trim();
                                  if (email.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter your email'), backgroundColor: AppColors.error),
                                    );
                                    return;
                                  }
                                  setDialogState(() => sending = true);
                                  try {
                                    await SupabaseService.sendPasswordResetEmail(email);
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Password reset link sent! Check your email.'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => sending = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                                    );
                                  }
                                },
                          child: sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Send Reset Link'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Back Button
                IconButton(
                  onPressed: () => context.go('/onboarding'),
                  icon: const Icon(Icons.arrow_back_ios),
                  padding: EdgeInsets.zero,
                ),

                const SizedBox(height: 24),

                // Title
                const Text(
                  'Sign into\nyour account!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Welcome back! Please enter your details',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 40),

                // Email Field
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Password Field
                CustomTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                        const Text(
                          'Remember Me',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => _showForgotPasswordDialog(),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Sign In Button
                CustomButton(
                  text: 'Sign In',
                  onPressed: isLoading ? null : _handleLogin,
                  isLoading: isLoading,
                  width: double.infinity,
                ),

                const SizedBox(height: 24),

                // Don't have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have any account? ",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // const SizedBox(height: 40),

                // // Divider
                // Row(
                //   children: const [
                //     Expanded(child: Divider()),
                //     Padding(
                //       padding: EdgeInsets.symmetric(horizontal: 16),
                //       child: Text(
                //         'Or continue with',
                //         style: TextStyle(
                //           fontSize: 12,
                //           color: AppColors.textSecondary,
                //         ),
                //       ),
                //     ),
                //     Expanded(child: Divider()),
                //   ],
                // ),

                // const SizedBox(height: 24),

                // // Social Login Buttons
                // Row(
                //   children: [
                //     Expanded(
                //       child: _SocialButton(
                //         icon: Icons.g_mobiledata,
                //         label: 'Google',
                //         onPressed: () => _handleSocialSignIn('google'),
                //       ),
                //     ),
                //     const SizedBox(width: 16),
                //     Expanded(
                //       child: _SocialButton(
                //         icon: Icons.facebook,
                //         label: 'Facebook',
                //         onPressed: () => _handleSocialSignIn('facebook'),
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}