import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../providers/design_package_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/auth_provider.dart';

class CustomizeDesignScreen extends ConsumerStatefulWidget {
  final String designId;

  const CustomizeDesignScreen({super.key, required this.designId});

  @override
  ConsumerState<CustomizeDesignScreen> createState() => _CustomizeDesignScreenState();
}

class _CustomizeDesignScreenState extends ConsumerState<CustomizeDesignScreen> {
  String? _selectedWallColor;
  String _selectedStyle = 'Modern';
  double _budget = 5000;
  final Map<String, bool> _includedItems = {};

  final List<String> _styles = [
    'Modern',
    'Minimalist',
    'Traditional',
    'Contemporary',
    'Industrial',
    'Scandinavian',
  ];

  @override
  Widget build(BuildContext context) {
    final packageAsync = ref.watch(packageByIdProvider(widget.designId));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Design'),
      ),
      body: packageAsync.when(
        data: (package) {
          if (package == null) {
            return const Center(child: Text('Package not found'));
          }

          // Initialize included items
          if (_includedItems.isEmpty) {
            // Here you would load actual package items from the database
            _includedItems['Bed'] = true;
            _includedItems['Wardrobe'] = true;
            _includedItems['Side Table'] = true;
            _includedItems['Curtains'] = false;
            _includedItems['Lighting'] = true;
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview Image
                CachedNetworkImage(
                  imageUrl: package.previewImage ?? '',
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.greyLight,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Package Name
                      Text(
                        package.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Wall Color Selection
                      if (package.wallColorSuggestions.isNotEmpty) ...[
                        const Text(
                          'Choose Wall Color',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: package.wallColorSuggestions.map((colorHex) {
                            final isSelected = _selectedWallColor == colorHex;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedWallColor = colorHex;
                                });
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _parseColor(colorHex),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.greyLight,
                                    width: isSelected ? 3 : 1,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Style Selection
                      const Text(
                        'Choose Style',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _styles.map((style) {
                          final isSelected = _selectedStyle == style;
                          return ChoiceChip(
                            label: Text(style),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStyle = style;
                              });
                            },
                            backgroundColor: AppColors.greyLight,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Budget Slider
                      const Text(
                        'Adjust Budget',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Slider(
                                  value: _budget,
                                  min: 1000,
                                  max: 20000,
                                  divisions: 38,
                                  label: '৳${_budget.toStringAsFixed(0)}',
                                  activeColor: AppColors.primary,
                                  onChanged: (value) {
                                    setState(() {
                                      _budget = value;
                                    });
                                  },
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '৳1,000',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '৳${_budget.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      '৳20,000',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Items Selection
                      const Text(
                        'Customize Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select items you want to include in your package',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.greyLight.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: _includedItems.entries.map((entry) {
                            return CheckboxListTile(
                              value: entry.value,
                              onChanged: (value) {
                                setState(() {
                                  _includedItems[entry.key] = value ?? false;
                                });
                              },
                              title: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              activeColor: AppColors.primary,
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customization Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryRow('Style', _selectedStyle),
                            if (_selectedWallColor != null)
                              _buildSummaryRow('Wall Color', 'Selected'),
                            _buildSummaryRow('Budget', '৳${_budget.toStringAsFixed(0)}'),
                            _buildSummaryRow(
                              'Items',
                              '${_includedItems.values.where((v) => v).length} selected',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100), // Space for bottom bar
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),

      // Bottom Bar
      bottomNavigationBar: packageAsync.maybeWhen(
        data: (package) {
          if (package == null) return null;

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: CustomButton(
                text: 'Add Customized Package to Cart',
                onPressed: () async {
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please login to add items to cart'),
                      ),
                    );
                    return;
                  }

                  try {
                    final customizations = {
                      'style': _selectedStyle,
                      'wall_color': _selectedWallColor,
                      'budget': _budget,
                      'included_items': _includedItems,
                    };

                    await ref.read(cartProvider.notifier).addToCart(
                      packageId: package.id,
                      quantity: 1,
                      customizations: customizations,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Customized package added to cart'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      context.pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                width: double.infinity,
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// customize_design_screen.dart - class এর ভেতরে add করো

Color _parseColor(String colorStr) {
  final s = colorStr.trim();
  final hex = s.startsWith('#') ? s.substring(1) : s;
  final hexRegex = RegExp(r'^[0-9A-Fa-f]{6}$');
  if (hexRegex.hasMatch(hex)) {
    return Color(int.parse('FF$hex', radix: 16));
  }
  const namedColors = {
    'black':  Color(0xFF000000),
    'white':  Color(0xFFFFFFFF),
    'red':    Color(0xFFE53935),
    'blue':   Color(0xFF1E88E5),
    'green':  Color(0xFF43A047),
    'grey':   Color(0xFF9E9E9E),
    'gray':   Color(0xFF9E9E9E),
    'yellow': Color(0xFFFDD835),
    'orange': Color(0xFFFB8C00),
    'brown':  Color(0xFF6D4C41),
    'pink':   Color(0xFFE91E63),
    'purple': Color(0xFF8E24AA),
    'beige':  Color(0xFFF5F0DC),
    'cream':  Color(0xFFFFFDD0),
    'navy':   Color(0xFF003153),
    'teal':   Color(0xFF00897B),
  };
  return namedColors[s.toLowerCase()] ?? const Color(0xFF9E9E9E);
}