import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/filter_bottom_sheet.dart';

class ShopScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  final bool featuredOnly;
  final bool hideSearch;

  const ShopScreen({super.key, this.initialCategory, this.featuredOnly = false, this.hideSearch = false});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedCategory;
  String _sortBy = 'Newest';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(ShopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != null && widget.initialCategory != oldWidget.initialCategory) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _executeSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(productSearchProvider.notifier).searchProducts(
        query,
        category: _selectedCategory != 'All' ? _selectedCategory : null,
      );
    }
  }

  void _onSearchChanged() {
    _executeSearch();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterBottomSheet(
        selectedCategory: _selectedCategory,
        sortBy: _sortBy,
        onApply: (category, sort) {
          setState(() {
            _selectedCategory = category;
            _sortBy = sort;
          });
          if (_searchController.text.isNotEmpty) {
            _executeSearch();
          }
        },
      ),
    );
  }

  List _filterAndSortProducts(List products) {
    var filtered = products;

    if (_selectedCategory != 'All') {
      filtered = filtered.where((p) {
        final catName = p.categoryName;
        return catName != null && catName.toLowerCase() == _selectedCategory.toLowerCase();
      }).toList();
    }

    final sorted = List.from(filtered);
    switch (_sortBy) {
      case 'Price: Low to High':
        sorted.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
        break;
      case 'Price: High to Low':
        sorted.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
        break;
      case 'Rating':
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Popular':
        sorted.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      default:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = widget.initialCategory != null
        ? ref.watch(productsByCategoryProvider(widget.initialCategory!))
        : ref.watch(widget.featuredOnly ? featuredProductsProvider : allProductsProvider);
    ref.watch(productSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.featuredOnly
              ? 'Featured Products'
              : widget.initialCategory != null
                  ? _selectedCategory
                  : 'Shop',
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile/wishlist'),
            icon: const Icon(Icons.favorite_border),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!widget.featuredOnly && !widget.hideSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _searchController,
                      hint: 'Search products...',
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => _onSearchChanged(),
                      onFieldSubmitted: (_) => _executeSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _showFilterBottomSheet,
                      icon: const Icon(Icons.tune, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: !widget.hideSearch && _searchController.text.isNotEmpty && !widget.featuredOnly
                ? _buildSearchResults()
                : _buildAllProducts(productsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final searchResults = ref.watch(productSearchProvider);

    return searchResults.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: AppColors.grey),
                SizedBox(height: 16),
                Text('No products found',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return _buildProductsGrid(products);
      },
      loading: () => const LoadingWidget(),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to search products',
        onRetry: () {
          ref.read(productSearchProvider.notifier).searchProducts(
            _searchController.text,
            category: _selectedCategory != 'All' ? _selectedCategory : null,
          );
        },
      ),
    );
  }

  Widget _buildAllProducts(AsyncValue productsAsync) {
    return productsAsync.when(
      data: (products) {
        final filtered = _filterAndSortProducts(products);

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.grey),
                const SizedBox(height: 16),
                Text(
                  _selectedCategory != 'All'
                      ? 'No products in "$_selectedCategory"'
                      : 'No products available',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return _buildProductsGrid(filtered);
      },
      loading: () => const LoadingWidget(message: 'Loading products...'),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to load products',
        onRetry: () => ref.invalidate(widget.featuredOnly ? featuredProductsProvider : allProductsProvider),
      ),
    );
  }

  Widget _buildProductsGrid(List products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: products[index]);
      },
    );
  }
}
