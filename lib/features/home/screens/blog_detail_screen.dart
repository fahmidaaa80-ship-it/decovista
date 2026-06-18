import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../data/models/blog_post_model.dart';
import '../../../providers/blog_post_provider.dart';

class BlogDetailScreen extends ConsumerWidget {
  final String blogId;

  const BlogDetailScreen({super.key, required this.blogId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(blogPostByIdProvider(blogId));

    return Scaffold(
      body: postAsync.when(
        data: (post) {
          if (post == null) {
            return const Center(child: Text('Blog post not found'));
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: CachedNetworkImage(
                    imageUrl: post.image,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.greyLight),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.greyLight,
                      child: const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            post.category,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.readTime,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (post.content.isNotEmpty || post.contentBlocks.isNotEmpty)
                      ..._buildContent(post),
                    if (post.content.isEmpty && post.contentBlocks.isEmpty)
                      Text(
                        post.excerpt,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(BlogPostModel post) {
    final blocks = post.contentBlocks;
    final widgets = <Widget>[];

    if (blocks.isEmpty && post.content.isNotEmpty) {
      widgets.add(Text(
        post.content,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ));
      return widgets;
    }

    for (final block in blocks) {
      switch (block.type) {
        case 'heading':
          widgets.add(Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              block.text ?? '',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ));

        case 'paragraph':
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              block.text ?? '',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ));

        case 'bullet_list':
          if (block.items != null && block.items!.isNotEmpty) {
            widgets.add(Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: block.items!.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ));
          }

        case 'image':
          if (block.imageSrc != null && block.imageSrc!.isNotEmpty) {
            widgets.add(Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: block.imageSrc!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 200,
                        color: AppColors.greyLight,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 200,
                        color: AppColors.greyLight,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  if (block.imageCaption != null && block.imageCaption!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        block.imageCaption!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ));
          }
      }
    }

    if (post.images.isNotEmpty) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(const Text(
        'Gallery',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ));
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: post.images.where((url) => url.isNotEmpty).map((url) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    width: 180,
                    height: 120,
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
              );
            }).toList(),
          ),
        ),
      );
    }

    return widgets;
  }
}
