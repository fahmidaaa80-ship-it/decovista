import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';
import '../data/models/blog_post_model.dart';

final blogPostsProvider = FutureProvider<List<BlogPostModel>>((ref) async {
  try {
    final response = await SupabaseService.getBlogPosts(activeOnly: true);
    final posts = <BlogPostModel>[];
    for (final json in response) {
      try {
        posts.add(BlogPostModel.fromJson(json));
      } catch (e) {
        debugPrint('Skipping bad blog post row: $e');
      }
    }
    return posts;
  } catch (e) {
    debugPrint('blogPostsProvider error: $e');
    return [];
  }
});

final blogPostByIdProvider =
    FutureProvider.family<BlogPostModel?, String>((ref, postId) async {
  try {
    final response = await SupabaseService.getBlogPostById(postId);
    return BlogPostModel.fromJson(response);
  } catch (e) {
    debugPrint('blogPostByIdProvider error: $e');
    return null;
  }
});

class AdminBlogPostsNotifier extends AsyncNotifier<List<BlogPostModel>> {
  @override
  Future<List<BlogPostModel>> build() async {
    try {
      final response = await SupabaseService.getBlogPosts();
      final posts = <BlogPostModel>[];
      for (final json in response) {
        try {
          posts.add(BlogPostModel.fromJson(json));
        } catch (e) {
          debugPrint('Skipping bad blog post row: $e');
        }
      }
      return posts;
    } catch (e) {
      debugPrint('AdminBlogPostsNotifier.build error: $e');
      return [];
    }
  }

  Future<void> addPost(Map<String, dynamic> data) async {
    await SupabaseService.addBlogPost(data);
    ref.invalidateSelf();
  }

  Future<void> updatePost(String id, Map<String, dynamic> data) async {
    await SupabaseService.updateBlogPost(id, data);
    ref.invalidateSelf();
  }

  Future<void> deletePost(String id) async {
    await SupabaseService.deleteBlogPost(id);
    state = AsyncData(state.value?.where((p) => p.id != id).toList() ?? []);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final adminBlogPostsNotifierProvider =
    AsyncNotifierProvider<AdminBlogPostsNotifier, List<BlogPostModel>>(
  AdminBlogPostsNotifier.new,
);
