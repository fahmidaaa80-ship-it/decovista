import 'dart:io';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

import '../data/models/design_package_model.dart';

// ─────────────────────────────────────────────────────────────────────────────

class AddPackageState {
  final bool isLoading;
  final String? error;

  const AddPackageState({this.isLoading = false, this.error});
}

// ─────────────────────────────────────────────────────────────────────────────

class AddPackageNotifier extends StateNotifier<AddPackageState> {
  AddPackageNotifier() : super(const AddPackageState());

  final _client = Supabase.instance.client;

  // ── Fetch existing package (edit mode) ────────────────────────────────────

  Future<DesignPackage?> fetchPackage(String packageId) async {
    try {
      final data = await _client
          .from('design_packages')
          .select('*')
          .eq('id', packageId)
          .single();
      return DesignPackage.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // ── Save (insert or update) ───────────────────────────────────────────────

  Future<void> savePackage({
    required String? packageId, // null = insert
    required String name,
    required String description,
    required String roomType,
    required String? style,
    required double price,
    required double? discountPrice,
    required double? estimatedBudget,
    required String? roomSize,
    required bool isCustomizable,
    required bool isFeatured,
    required List<String> wallColorSuggestions,
    required File? previewImageFile,
    required String? existingPreviewUrl,
    required List<File> extraImageFiles,
    required List<String> existingExtraUrls,
  }) async {
    state = const AddPackageState(isLoading: true);

    try {
      // 1. Upload preview image (if new file selected)
      String? previewUrl = existingPreviewUrl;
      if (previewImageFile != null) {
        previewUrl = await _uploadImage(
          file: previewImageFile,
          folder: 'preview',
          oldUrl: existingPreviewUrl,
        );
      }

      // 2. Upload extra images (new files only)
      final allExtraUrls = List<String>.from(existingExtraUrls);
      for (final file in extraImageFiles) {
        final url = await _uploadImage(file: file, folder: 'gallery');
        allExtraUrls.add(url);
      }

      // 3. Build payload
      final now = DateTime.now().toIso8601String();
      final payload = {
        'name': name,
        'description': description.isEmpty ? null : description,
        'room_type': roomType,
        'style': style,
        'price': price,
        'discount_price': discountPrice,
        'preview_image': previewUrl,
        'images': allExtraUrls,
        'estimated_budget': estimatedBudget,
        'room_size': roomSize,
        'wall_color_suggestions': wallColorSuggestions,
        'is_customizable': isCustomizable,
        'is_featured': isFeatured,
        'updated_at': now,
      };

      // 4. Insert or update
      if (packageId == null) {
        payload['created_at'] = now;
        payload['rating'] = 0.0;
        payload['review_count'] = 0;
        await _client.from('design_packages').insert(payload);
      } else {
        await _client
            .from('design_packages')
            .update(payload)
            .eq('id', packageId);
      }

      state = const AddPackageState();
    } catch (e) {
      state = AddPackageState(error: e.toString());
      rethrow;
    }
  }

  // ── Image upload helper ───────────────────────────────────────────────────

  Future<String> _uploadImage({
    required File file,
    required String folder,
    String? oldUrl,
  }) async {
    // Optional: delete old image from storage
    if (oldUrl != null && oldUrl.isNotEmpty) {
      try {
        final oldPath = _storagePathFromUrl(oldUrl);
        if (oldPath != null) {
          await _client.storage
              .from('design-packages')
              .remove([oldPath]);
        }
      } catch (_) {
        // ignore if delete fails
      }
    }

    final ext = p.extension(file.path); // .jpg / .png / .webp
    final fileName =
        '${folder}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final storagePath = '$folder/$fileName';

    await _client.storage.from('design-packages').upload(
      storagePath,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    return _client.storage
        .from('design-packages')
        .getPublicUrl(storagePath);
  }

  // Extracts storage path from a full Supabase public URL
  String? _storagePathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // path looks like: /storage/v1/object/public/design-packages/preview/xxx.jpg
      final segments = uri.pathSegments;
      final bucketIndex =
      segments.indexWhere((s) => s == 'design-packages');
      if (bucketIndex == -1) return null;
      return segments.sublist(bucketIndex + 1).join('/');
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

final addPackageProvider =
StateNotifierProvider<AddPackageNotifier, AddPackageState>(
      (ref) => AddPackageNotifier(),
);