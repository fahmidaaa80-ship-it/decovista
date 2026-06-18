import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../providers/auth_provider.dart';

final homeReviewsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    return await SupabaseService.getReviews();
  } catch (e) {
    return [];
  }
});

class CustomerReviews extends ConsumerWidget {
  const CustomerReviews({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(homeReviewsProvider);
    final user = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'What Our Customers Say',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'No reviews yet. Be the first to share your experience!',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            return SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _ReviewCard(review: reviews[index]),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 180,
            child: LoadingWidget(),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        if (user != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomButton(
              width: 200,
              text: 'Write a Review',
              onPressed: () => _showReviewDialog(context, ref, user.id),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _showReviewDialog(BuildContext context, WidgetRef ref, String userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Write a Review'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Share your experience...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Submit',
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              try {
                await SupabaseService.addHomeReview(
                  userId: userId,
                  comment: text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(homeReviewsProvider);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Failed: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final users = review['users'] as Map<String, dynamic>?;
    final name = users?['full_name'] as String? ?? 'Anonymous';
    final profileImg = users?['profile_img'] as String?;
    final avatarUrl = users?['avatar_url'] as String?;
    final comment = review['comment'] as String? ?? '';

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.greyLight,
                backgroundImage: profileImg != null && profileImg.isNotEmpty
                    ? MemoryImage(base64Decode(profileImg))
                    : (avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null),
                child: (profileImg == null || profileImg.isEmpty) &&
                        (avatarUrl == null || avatarUrl.isEmpty)
                    ? const Icon(Icons.person, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              comment,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
