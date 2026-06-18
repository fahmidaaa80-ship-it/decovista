import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/banner_model.dart';
import '../../../providers/banner_provider.dart';

class AdminBannersScreen extends ConsumerWidget {
  const AdminBannersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(adminBannersNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Banners'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(adminBannersNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: bannersAsync.when(
        data: (banners) {
          if (banners.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 64, color: AppColors.grey),
                  SizedBox(height: 16),
                  Text('No banners found',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: banners.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final banner = banners[index];
              return _BannerCard(
                banner: banner,
                onEdit: () => _showEditBannerDialog(context, ref, banner),
                onDelete: () => _confirmDelete(context, ref, banner),
              );
            },
          );
        },
        loading: () => const LoadingWidget(message: 'Loading banners...'),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBannerDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Banner'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, BannerModel banner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner'),
        content: Text('Are you sure you want to delete "${banner.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(adminBannersNotifierProvider.notifier).deleteBanner(banner.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showEditBannerDialog(BuildContext context, WidgetRef ref, BannerModel banner) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: banner.title);
    final subtitleController = TextEditingController(text: banner.subtitle);
    final imageUrlController = TextEditingController(text: banner.imageUrl);
    final primaryActionController = TextEditingController(text: banner.primaryAction);
    final secondaryActionController = TextEditingController(text: banner.secondaryAction);
    int sortOrder = banner.sortOrder;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Banner'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: subtitleController,
                  decoration: const InputDecoration(labelText: 'Subtitle'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: primaryActionController,
                  decoration: const InputDecoration(labelText: 'Primary Button Text'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: secondaryActionController,
                  decoration: const InputDecoration(labelText: 'Secondary Button Text'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Sort Order'),
                  keyboardType: TextInputType.number,
                  initialValue: sortOrder.toString(),
                  onChanged: (value) =>
                      sortOrder = int.tryParse(value) ?? 0,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Save',
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              ref.read(adminBannersNotifierProvider.notifier).updateBanner(
                banner.id,
                {
                  'title': titleController.text.trim(),
                  'subtitle': subtitleController.text.trim(),
                  'image_url': imageUrlController.text.trim(),
                  'primary_action': primaryActionController.text.trim(),
                  'secondary_action': secondaryActionController.text.trim(),
                  'sort_order': sortOrder,
                },
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAddBannerDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final imageUrlController = TextEditingController();
    final primaryActionController = TextEditingController(text: 'Shop Now');
    final secondaryActionController = TextEditingController(text: 'Explore');
    int sortOrder = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Banner'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Transform Your Space',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: subtitleController,
                  decoration: const InputDecoration(
                    labelText: 'Subtitle',
                    hintText: 'e.g. Discover beautiful furniture',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://images.unsplash.com/...',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: primaryActionController,
                  decoration: const InputDecoration(
                    labelText: 'Primary Button Text',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: secondaryActionController,
                  decoration: const InputDecoration(
                    labelText: 'Secondary Button Text',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Sort Order',
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      sortOrder = int.tryParse(value) ?? 0,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Add',
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              ref.read(adminBannersNotifierProvider.notifier).addBanner({
                'title': titleController.text.trim(),
                'subtitle': subtitleController.text.trim(),
                'image_url': imageUrlController.text.trim(),
                'primary_action': primaryActionController.text.trim(),
                'secondary_action': secondaryActionController.text.trim(),
                'sort_order': sortOrder,
                'is_active': true,
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BannerCard({required this.banner, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: banner.imageUrl,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.greyLight,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.greyLight,
                    child: const Icon(Icons.broken_image, size: 48),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  banner.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        banner.primaryAction,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        banner.secondaryAction,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.primary, size: 20),
                          ),
                          IconButton(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
