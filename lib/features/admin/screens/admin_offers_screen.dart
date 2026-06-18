import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/offer_model.dart';
import '../../../providers/offer_provider.dart';

class _ColorTheme {
  final String name;
  final Color background;
  final Color text;
  const _ColorTheme(this.name, this.background, this.text);
}

const _colorThemes = <_ColorTheme>[
  _ColorTheme('Summer Pink', Color(0xFFFFE5E5), Color(0xFFD32F2F)),
  _ColorTheme('Ocean Blue', Color(0xFFE3F2FD), Color(0xFF1976D2)),
  _ColorTheme('Royal Purple', Color(0xFFF3E5F5), Color(0xFF7B1FA2)),
  _ColorTheme('Forest Green', Color(0xFFE8F5E9), Color(0xFF388E3C)),
  _ColorTheme('Warm Orange', Color(0xFFFFF3E0), Color(0xFFE65100)),
  _ColorTheme('Teal', Color(0xFFE0F2F1), Color(0xFF00796B)),
  _ColorTheme('Amber', Color(0xFFFFFDE7), Color(0xFFF57F17)),
  _ColorTheme('Rose', Color(0xFFFCE4EC), Color(0xFFC2185B)),
];

class AdminOffersScreen extends ConsumerWidget {
  const AdminOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(adminOffersNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Offers'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(adminOffersNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: offersAsync.when(
        data: (offers) {
          if (offers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined, size: 64, color: AppColors.grey),
                  SizedBox(height: 16),
                  Text('No offers found',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final offer = offers[index];
              return _OfferCard(
                offer: offer,
                onEdit: () => _showEditOfferDialog(context, ref, offer),
                onDelete: () => _confirmDelete(context, ref, offer),
              );
            },
          );
        },
        loading: () => const LoadingWidget(message: 'Loading offers...'),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOfferDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Offer'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, OfferModel offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer'),
        content: Text('Are you sure you want to delete "${offer.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(adminOffersNotifierProvider.notifier).deleteOffer(offer.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAddOfferDialog(BuildContext context, WidgetRef ref) {
    _showOfferFormDialog(context, ref, null);
  }

  void _showEditOfferDialog(BuildContext context, WidgetRef ref, OfferModel offer) {
    _showOfferFormDialog(context, ref, offer);
  }

  void _showOfferFormDialog(BuildContext context, WidgetRef ref, OfferModel? existing) async {
    List<String> categoryNames;
    try {
      final categories = await SupabaseService.getCategories();
      categoryNames = categories.map((c) => c['name'] as String).toSet().toList();
    } catch (_) {
      categoryNames = ['Living Room', 'Bedroom', 'Kitchen', 'Dining Room', 'Office', 'Bathroom', 'Outdoor', 'Study Room', 'Decor'];
    }
    if (categoryNames.isEmpty) {
      categoryNames = ['Living Room', 'Bedroom', 'Kitchen', 'Dining Room', 'Office', 'Bathroom', 'Outdoor', 'Study Room', 'Decor'];
    }
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: existing?.title ?? '');
    final discountController = TextEditingController(text: existing?.discount ?? '');
    final descriptionController = TextEditingController(text: existing?.description ?? '');
    String? selectedCategory = existing?.categoryName ?? (categoryNames.isNotEmpty ? categoryNames.first : null);
    int sortOrder = existing?.sortOrder ?? 0;
    int selectedThemeIndex = 0;
    if (existing != null) {
      for (int i = 0; i < _colorThemes.length; i++) {
        if (_colorThemes[i].background.value == existing.backgroundColor.value &&
            _colorThemes[i].text.value == existing.textColor.value) {
          selectedThemeIndex = i;
          break;
        }
      }
    }
    bool saving = false;
    final isEditing = existing != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(isEditing ? 'Edit Offer' : 'Add Offer'),
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
                          TextFormField(
                            controller: titleController,
                            decoration: const InputDecoration(labelText: 'Title'),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: discountController,
                            decoration: const InputDecoration(labelText: 'Discount (e.g. 50% OFF)'),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: descriptionController,
                            decoration: const InputDecoration(labelText: 'Description'),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 8),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categoryNames.map((name) {
                              final isSelected = selectedCategory == name;
                              return ChoiceChip(
                                label: Text(name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setDialogState(() => selectedCategory = name);
                                  }
                                },
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),

                          // Color Theme Swatch
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Color Theme',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 44,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(_colorThemes.length, (index) {
                                  final theme = _colorThemes[index];
                                  final isSelected = selectedThemeIndex == index;
                                  return GestureDetector(
                                    onTap: () => setDialogState(() => selectedThemeIndex = index),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 44,
                                      height: 44,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: theme.background,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? theme.text : Colors.transparent,
                                          width: 3,
                                        ),
                                        boxShadow: isSelected
                                            ? [BoxShadow(color: theme.text.withOpacity(0.3), blurRadius: 6)]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Icon(Icons.local_offer, color: theme.text, size: 18),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Sort Order',
                              hintText: 'Lower = appears first',
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: sortOrder.toString(),
                            onChanged: (v) => sortOrder = int.tryParse(v) ?? 0,
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
                          final theme = _colorThemes[selectedThemeIndex];
                          final bgHex = '#${theme.background.value.toRadixString(16).substring(2).toUpperCase()}';
                          final txtHex = '#${theme.text.value.toRadixString(16).substring(2).toUpperCase()}';
                          final data = {
                            'title': titleController.text.trim(),
                            'discount': discountController.text.trim(),
                            'description': descriptionController.text.trim(),
                            'category_name': selectedCategory ?? '',
                            'background_color': bgHex,
                            'text_color': txtHex,
                            'sort_order': sortOrder,
                            'is_active': true,
                          };
                          if (isEditing) {
                            await ref.read(adminOffersNotifierProvider.notifier)
                                .updateOffer(existing!.id, data);
                          } else {
                            await ref.read(adminOffersNotifierProvider.notifier)
                                .addOffer(data);
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
    });
  }
}

class _OfferCard extends StatelessWidget {
  final OfferModel offer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OfferCard({required this.offer, required this.onEdit, required this.onDelete});

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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: offer.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: offer.textColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    offer.discount,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: offer.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${offer.description}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: offer.textColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        offer.categoryName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: offer.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
