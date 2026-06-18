import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';
import '../data/models/offer_model.dart';

final offersProvider = FutureProvider<List<OfferModel>>((ref) async {
  try {
    final response = await SupabaseService.getOffers();
    final offers = <OfferModel>[];
    for (final json in response) {
      try {
        offers.add(OfferModel.fromJson(json));
      } catch (e) {
        debugPrint('Skipping bad offer row: $e');
      }
    }
    return offers;
  } catch (e) {
    debugPrint('offersProvider error: $e');
    return [];
  }
});

class AdminOffersNotifier extends AsyncNotifier<List<OfferModel>> {
  @override
  Future<List<OfferModel>> build() async {
    try {
      final response = await SupabaseService.getAdminOffers();
      final offers = <OfferModel>[];
      for (final json in response) {
        try {
          offers.add(OfferModel.fromJson(json));
        } catch (e) {
          debugPrint('Skipping bad offer row: $e');
        }
      }
      return offers;
    } catch (e) {
      debugPrint('AdminOffersNotifier.build error: $e');
      return [];
    }
  }

  Future<void> addOffer(Map<String, dynamic> data) async {
    await SupabaseService.addOffer(data);
    ref.invalidateSelf();
  }

  Future<void> updateOffer(String id, Map<String, dynamic> data) async {
    await SupabaseService.updateOffer(id, data);
    ref.invalidateSelf();
  }

  Future<void> deleteOffer(String id) async {
    await SupabaseService.deleteOffer(id);
    state = AsyncData(state.value?.where((o) => o.id != id).toList() ?? []);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final adminOffersNotifierProvider =
    AsyncNotifierProvider<AdminOffersNotifier, List<OfferModel>>(
  AdminOffersNotifier.new,
);
