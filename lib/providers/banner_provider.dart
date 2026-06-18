import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/supabase_service.dart';
import '../data/models/banner_model.dart';

final bannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  final response = await SupabaseService.getBanners();
  return response.map((json) => BannerModel.fromJson(json)).toList();
});

class AdminBannersNotifier extends AsyncNotifier<List<BannerModel>> {
  @override
  Future<List<BannerModel>> build() async {
    final response = await Supabase.instance.client
        .from('banners')
        .select('*')
        .order('sort_order', ascending: true);
    return (response as List)
        .map((json) => BannerModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> addBanner(Map<String, dynamic> data) async {
    await SupabaseService.addBanner(data);
    ref.invalidateSelf();
  }

  Future<void> updateBanner(String id, Map<String, dynamic> data) async {
    await SupabaseService.updateBanner(id, data);
    ref.invalidateSelf();
  }

  Future<void> deleteBanner(String id) async {
    await SupabaseService.deleteBanner(id);
    state = AsyncData(state.value?.where((b) => b.id != id).toList() ?? []);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final adminBannersNotifierProvider =
    AsyncNotifierProvider<AdminBannersNotifier, List<BannerModel>>(
  AdminBannersNotifier.new,
);
