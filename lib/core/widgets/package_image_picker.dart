import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Single preview image picker
// ─────────────────────────────────────────────────────────────────────────────

class PackageImagePicker extends StatelessWidget {
  final String? existingUrl;
  final File? selectedFile;
  final void Function(File) onPicked;
  final VoidCallback onRemoveExisting;

  const PackageImagePicker({
    super.key,
    required this.existingUrl,
    required this.selectedFile,
    required this.onPicked,
    required this.onRemoveExisting,
  });

  Future<void> _pick(BuildContext context) async {
    final picker = ImagePicker();
    final picked =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) onPicked(File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = selectedFile != null || existingUrl != null;

    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.greyLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? AppColors.primary : AppColors.grey,
            width: hasImage ? 2 : 1,
          ),
        ),
        child: hasImage ? _PreviewImage(
          file: selectedFile,
          url: existingUrl,
          onRemove: () {
            if (selectedFile != null) {
              // handled by parent reset
            } else {
              onRemoveExisting();
            }
          },
        ) : _PickerPlaceholder(),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  final File? file;
  final String? url;
  final VoidCallback onRemove;

  const _PreviewImage({
    required this.file,
    required this.url,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: file != null
              ? Image.file(file!, fit: BoxFit.cover)
              : CachedNetworkImage(
            imageUrl: url!,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
            const Center(child: CircularProgressIndicator()),
            errorWidget: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 48),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child:
              const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: const Text(
              'Tap to change',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 48, color: AppColors.grey),
        SizedBox(height: 8),
        Text('Preview Image যোগ করুন',
            style: TextStyle(color: AppColors.textSecondary)),
        SizedBox(height: 4),
        Text('Tap to select',
            style: TextStyle(color: AppColors.grey, fontSize: 12)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Multi-image picker (gallery / extra images)
// ─────────────────────────────────────────────────────────────────────────────

class PackageMultiImagePicker extends StatelessWidget {
  final List<String> existingUrls;
  final List<File> newFiles;
  final void Function(File) onAddFile;
  final void Function(String) onRemoveExisting;
  final void Function(File) onRemoveNew;

  const PackageMultiImagePicker({
    super.key,
    required this.existingUrls,
    required this.newFiles,
    required this.onAddFile,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  Future<void> _pickMultiple() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    for (final img in picked) {
      onAddFile(File(img.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Existing images
            ...existingUrls.map((url) => _Thumb(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) =>
                const Icon(Icons.broken_image),
              ),
              onRemove: () => onRemoveExisting(url),
            )),
            // New local files
            ...newFiles.map((file) => _Thumb(
              child: Image.file(file, fit: BoxFit.cover),
              onRemove: () => onRemoveNew(file),
            )),
            // Add button
            GestureDetector(
              onTap: _pickMultiple,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.grey),
                ),
                child: const Icon(Icons.add_photo_alternate_outlined,
                    color: AppColors.grey),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;

  const _Thumb({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: child,
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}