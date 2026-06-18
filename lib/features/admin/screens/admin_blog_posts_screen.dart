import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/blog_post_model.dart';
import '../../../providers/blog_post_provider.dart';
import 'admin_blog_post_editor_screen.dart';

class AdminBlogPostsScreen extends ConsumerWidget {
  const AdminBlogPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(adminBlogPostsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Blog Posts'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(adminBlogPostsNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 64, color: AppColors.grey),
                  SizedBox(height: 16),
                  Text('No blog posts found',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final post = posts[index];
              return _BlogPostCard(
                post: post,
                onEdit: () => _showFormDialog(context, ref, post),
                onDelete: () => _confirmDelete(context, ref, post),
                onEditDetails: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminBlogPostEditorScreen(post: post),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingWidget(message: 'Loading blog posts...'),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Post'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showFormDialog(BuildContext context, WidgetRef ref, BlogPostModel? existing) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: existing?.title ?? '');
    final excerptController = TextEditingController(text: existing?.excerpt ?? '');
    final contentController = TextEditingController(text: existing?.content ?? '');
    final imageController = TextEditingController(text: existing?.image ?? '');
    final categoryController = TextEditingController(text: existing?.category ?? '');
    final readTimeController = TextEditingController(text: existing?.readTime ?? '');
    bool saving = false;
    final isEditing = existing != null;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Blog Post' : 'Add Blog Post'),
          content: saving
              ? const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          if (existing != null)
                            SizedBox(
                              height: 100,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: existing.image,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: AppColors.greyLight,
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: AppColors.greyLight,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                            ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(labelText: 'Title'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: excerptController,
                          decoration: const InputDecoration(labelText: 'Excerpt / Description'),
                          maxLines: 3,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: contentController,
                          decoration: const InputDecoration(
                            labelText: 'Full Content',
                            hintText: 'Write the full blog post content here...',
                          ),
                          maxLines: 6,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: imageController,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                            hintText: 'https://...',
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: categoryController,
                                decoration: const InputDecoration(labelText: 'Category'),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: readTimeController,
                                decoration: const InputDecoration(
                                  labelText: 'Read Time',
                                  hintText: 'e.g. 5 min read',
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          actions: saving
              ? []
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  CustomButton(
                    text: isEditing ? 'Save' : 'Add',
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                          final data = {
                            'title': titleController.text.trim(),
                            'excerpt': excerptController.text.trim(),
                            'content': contentController.text.trim(),
                            'image': imageController.text.trim(),
                            'images': <String>[],
                            'content_blocks': <Map<String, dynamic>>[],
                            'category': categoryController.text.trim(),
                            'read_time': readTimeController.text.trim(),
                            'is_active': true,
                          };
                        if (isEditing) {
                          await ref.read(adminBlogPostsNotifierProvider.notifier)
                              .updatePost(existing!.id, data);
                        } else {
                          await ref.read(adminBlogPostsNotifierProvider.notifier)
                              .addPost(data);
                        }
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      } catch (e) {
                        setDialogState(() => saving = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text('Failed: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                  ),
                ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, BlogPostModel post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Blog Post'),
        content: Text('Delete "${post.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(adminBlogPostsNotifierProvider.notifier)
                    .deletePost(post.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Blog post deleted'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delete failed: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _BlogPostCard extends ConsumerWidget {
  final BlogPostModel post;
  final VoidCallback onEdit;
  final VoidCallback onEditDetails;
  final VoidCallback onDelete;

  const _BlogPostCard({
    required this.post,
    required this.onEdit,
    required this.onEditDetails,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: post.image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.greyLight,
                    child: const Icon(Icons.broken_image, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _CategoryChip(label: post.category),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          post.readTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'edit_details',
                    child: Text('Edit Details'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: AppColors.error)),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'edit_details') onEditDetails();
                  if (value == 'delete') onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
