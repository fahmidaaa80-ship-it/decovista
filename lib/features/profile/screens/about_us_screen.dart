import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.design_services, size: 64, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Decovista',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Decovista is your trusted platform for home interior design and furniture. '
              'We connect you with curated design packages, quality furniture, and professional '
              'consultation services to transform your living spaces.',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 24),
            const Text(
              'Our Mission',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'To make professional interior design accessible and affordable for every home.',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 24),
            const Text(
              'Contact Us',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Email: support@decovista.com\nPhone: +1 (555) 123-4567',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
