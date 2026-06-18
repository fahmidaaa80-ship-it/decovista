import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/user_design_model.dart';


// ── Provider ──────────────────────────────────────────────────────────────────

final myDesignsProvider = FutureProvider<List<UserDesign>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final data = await SupabaseService.getUserDesigns(user.id);
    return data.map((json) => UserDesign.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

// ── Screen ────────────────────────────────────────────────────────────────────

class MyDesignsScreen extends ConsumerWidget {
  const MyDesignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final designsAsync = ref.watch(myDesignsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Designs'),
      ),
      body: designsAsync.when(
        data: (designs) {
          if (designs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.design_services_outlined,
                    size: 80,
                    color: AppColors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No saved designs yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Browse design packages and save them here',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/designs'),
                    icon: const Icon(Icons.explore_outlined),
                    label: const Text('Browse Designs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: designs.length,
            itemBuilder: (context, index) {
              final design = designs[index];
              final package = design.package;

              if (package == null) return const SizedBox.shrink();

              return _DesignCard(
                design: design,
                package: package,
                onTap: () => context.push('/design/${design.packageId}'),
                onDelete: () async {
                  await SupabaseService.deleteUserDesign(design.id);
                  ref.invalidate(myDesignsProvider);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _DesignCard extends StatelessWidget {
  final UserDesign design;
  final Map<String, dynamic> package;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DesignCard({
    required this.design,
    required this.package,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final previewImage = package['preview_image'] as String?;
    final name = package['name'] as String? ?? 'Design Package';
    final roomType = (package['room_type'] as String? ?? '')
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    final style = package['style'] as String?;
    final budget = package['estimated_budget'] as num?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: previewImage != null
                  ? CachedNetworkImage(
                imageUrl: previewImage,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 180,
                  color: AppColors.greyLight,
                ),
              )
                  : Container(
                height: 180,
                color: AppColors.greyLight,
                child: const Icon(Icons.image_outlined,
                    size: 48, color: AppColors.grey),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + delete
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                        tooltip: 'Remove',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Tags row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (roomType.isNotEmpty) _tag(roomType, AppColors.primary),
                      if (style != null) _tag(style, AppColors.info),
                      if (budget != null)
                        _tag(
                          'Budget: ৳${(budget).toStringAsFixed(0)}',
                          AppColors.success,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}