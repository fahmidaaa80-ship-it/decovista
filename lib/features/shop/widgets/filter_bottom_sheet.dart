import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/custom_button.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  final String selectedCategory;
  final String sortBy;
  final Function(String category, String sort) onApply;

  const FilterBottomSheet({
    super.key,
    required this.selectedCategory,
    required this.sortBy,
    required this.onApply,
  });

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late String _selectedCategory;
  late String _sortBy;
  List<String> _categories = ['All'];

  final List<String> _sortOptions = [
    'Newest',
    'Price: Low to High',
    'Price: High to Low',
    'Rating',
    'Popular',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _sortBy = widget.sortBy;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await SupabaseService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = ['All', ...cats.map((c) => c['name'] as String)];
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter & Sort',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Categories
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Sort By
          const Text(
            'Sort By',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          Column(
            children: _sortOptions.map((option) {
              return RadioListTile<String>(
                value: option,
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
                title: Text(
                  option,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Reset',
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'All';
                      _sortBy = 'Newest';
                    });
                  },
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Apply',
                  onPressed: () {
                    widget.onApply(_selectedCategory, _sortBy);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
