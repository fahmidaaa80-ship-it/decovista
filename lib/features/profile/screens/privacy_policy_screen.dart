import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last updated: June 2026',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _section(
              'Information We Collect',
              'We collect information you provide directly, such as your name, email address, phone number, '
                  'and shipping address when you create an account or place an order. We also automatically '
                  'collect certain information about your device and browsing behavior.',
            ),
            _section(
              'How We Use Your Information',
              'We use your information to process orders, provide consultation services, improve our products, '
                  'and send relevant updates about your purchases and account activity.',
            ),
            _section(
              'Data Sharing',
              'We do not sell your personal information. We may share data with trusted service providers '
                  'who help us operate our platform, process payments, and deliver orders.',
            ),
            _section(
              'Security',
              'We implement industry-standard security measures to protect your data. However, no method '
                  'of transmission over the Internet is 100%% secure.',
            ),
            _section(
              'Contact',
              'If you have questions about this privacy policy, contact us at support@decovista.com.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }
}
