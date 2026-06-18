import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/blog_post_model.dart';
import '../../../data/models/content_section.dart';
import '../../../providers/blog_post_provider.dart';

class AdminBlogPostEditorScreen extends ConsumerStatefulWidget {
  final BlogPostModel post;

  const AdminBlogPostEditorScreen({super.key, required this.post});

  @override
  ConsumerState<AdminBlogPostEditorScreen> createState() => _AdminBlogPostEditorScreenState();
}

class _AdminBlogPostEditorScreenState extends ConsumerState<AdminBlogPostEditorScreen> {
  late List<ContentSection> _blocks;
  late List<TextEditingController> _imageControllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _blocks = widget.post.contentBlocks
        .map((b) => ContentSection(
              type: b.type,
              text: b.text,
              items: b.items != null ? List<String>.from(b.items!) : null,
              imageSrc: b.imageSrc,
              imageCaption: b.imageCaption,
            ))
        .toList();
    _imageControllers = widget.post.images
        .map((url) => TextEditingController(text: url))
        .toList();
    if (_imageControllers.isEmpty) {
      _imageControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final c in _imageControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addImageField() {
    setState(() => _imageControllers.add(TextEditingController()));
  }

  void _removeImageField(int index) {
    setState(() {
      _imageControllers[index].dispose();
      _imageControllers.removeAt(index);
    });
  }

  void _addBlock([String type = 'paragraph']) {
    setState(() {
      _blocks.add(ContentSection(type: type));
    });
  }

  void _removeBlock(int index) {
    setState(() => _blocks.removeAt(index));
  }

  void _moveBlock(int index, int direction) {
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _blocks.length) return;
    setState(() {
      final temp = _blocks[index];
      _blocks[index] = _blocks[newIndex];
      _blocks[newIndex] = temp;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final images = _imageControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await ref.read(adminBlogPostsNotifierProvider.notifier).updatePost(
            widget.post.id,
            {
              'images': images,
              'content_blocks':
                  _blocks.where((b) => b.type.isNotEmpty).map((b) => b.toJson()).toList(),
            },
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Blog details updated'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Blog Details'),
        actions: [
          _saving
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  tooltip: 'Save',
                ),
        ],
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Gallery Images ──
                  const Text(
                    'Gallery Images',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_imageControllers.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _imageControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Image URL ${i + 1}',
                                hintText: 'https://...',
                                isDense: true,
                                border: const OutlineInputBorder(),
                                suffixIcon: _imageControllers[i].text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.image, size: 20),
                                        onPressed: () => setState(() {}),
                                      )
                                    : null,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_imageControllers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: AppColors.error),
                              onPressed: () => _removeImageField(i),
                            ),
                        ],
                      ),
                    );
                  }),
                  CustomButton(
                    text: 'Add Image',
                    icon: Icons.add_photo_alternate_outlined,
                    onPressed: _addImageField,
                    isOutlined: true,
                  ),

                  const SizedBox(height: 24),

                  // ── Content Blocks ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Content Blocks',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                        tooltip: 'Add block',
                        onSelected: _addBlock,
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'heading', child: Text('Heading')),
                          PopupMenuItem(value: 'paragraph', child: Text('Paragraph')),
                          PopupMenuItem(value: 'bullet_list', child: Text('Bullet List')),
                          PopupMenuItem(value: 'image', child: Text('Image')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_blocks.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No content blocks yet. Tap + to add one.',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),

                  ...List.generate(_blocks.length, (i) {
                    final block = _blocks[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Block header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    block.type.replaceAll('_', ' ').toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (i > 0)
                                  IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                                    onPressed: () => _moveBlock(i, -1),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                if (i < _blocks.length - 1)
                                  IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                    onPressed: () => _moveBlock(i, 1),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18,
                                      color: AppColors.error),
                                  onPressed: () => _removeBlock(i),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Block content
                            _buildBlockEditor(i, block),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildBlockEditor(int index, ContentSection block) {
    switch (block.type) {
      case 'heading':
        return TextFormField(
          initialValue: block.text ?? '',
          decoration: const InputDecoration(
            labelText: 'Heading Text',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) => _blocks[index] = ContentSection(
            type: 'heading',
            text: v,
          ),
        );

      case 'paragraph':
        return TextFormField(
          initialValue: block.text ?? '',
          decoration: const InputDecoration(
            labelText: 'Paragraph',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 4,
          onChanged: (v) => _blocks[index] = ContentSection(
            type: 'paragraph',
            text: v,
          ),
        );

      case 'bullet_list':
        final items = _blocks[index].items ?? [''];
        return Column(
          children: [
            ...List.generate(items.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 18)),
                    Expanded(
                      child: TextFormField(
                        initialValue: items[i],
                        decoration: InputDecoration(
                          hintText: 'Item ${i + 1}',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) {
                          final updated = List<String>.from(items);
                          updated[i] = v;
                          _blocks[index] = ContentSection(
                            type: 'bullet_list',
                            items: updated,
                          );
                        },
                      ),
                    ),
                    if (items.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            size: 18, color: AppColors.error),
                        onPressed: () {
                          final current = _blocks[index].items ?? [''];
                          final updated = List<String>.from(current);
                          updated.removeAt(i);
                          _blocks[index] = ContentSection(
                            type: 'bullet_list',
                            items: updated.isEmpty ? [''] : updated,
                          );
                          setState(() {});
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () {
                  final current = _blocks[index].items ?? [''];
                  _blocks[index] = ContentSection(
                    type: 'bullet_list',
                    items: [...current, ''],
                  );
                  setState(() {});
                },
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 18),
                    const SizedBox(width: 4),
                    Text('Add item',
                        style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
            ),
          ],
        );

      case 'image':
        return Column(
          children: [
            if (block.imageSrc != null && block.imageSrc!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: block.imageSrc!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 150,
                    color: AppColors.greyLight,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 150,
                    color: AppColors.greyLight,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: block.imageSrc ?? '',
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                _blocks[index] = ContentSection(
                  type: 'image',
                  imageSrc: v,
                  imageCaption: block.imageCaption,
                );
                setState(() {});
              },
            ),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: block.imageCaption ?? '',
              decoration: const InputDecoration(
                labelText: 'Caption (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                _blocks[index] = ContentSection(
                  type: 'image',
                  imageSrc: block.imageSrc,
                  imageCaption: v,
                );
              },
            ),
          ],
        );

      default:
        return const Text('Unknown block type');
    }
  }
}
