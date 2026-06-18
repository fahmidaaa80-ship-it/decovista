import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final String? productId;
  const AddProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _materialController = TextEditingController();
  final _stockController = TextEditingController();

  String? _selectedCategory;
  bool _isFeatured = false;
  bool _isNew = false;
  bool _isProcessing = false;
  bool _isLoading = false;
  List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = [];
  List<String> _categories = [
    'Living Room',
    'Bedroom',
    'Kitchen',
    'Dining Room',
    'Office',
    'Bathroom',
    'Outdoor',
    'Study Room',
    'Decor',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await SupabaseService.getCategories();
      final names = cats.map((c) => c['name'] as String).toList();
      if (mounted && names.isNotEmpty) setState(() => _categories = names);
    } catch (_) {}
  }

  bool get _isEditing => widget.productId != null;

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.getProductById(widget.productId!);
      _nameController.text = data['name'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _priceController.text = (data['price'] ?? 0).toString();
      _discountPriceController.text = data['discount_price'] != null
          ? data['discount_price'].toString()
          : '';
      _materialController.text = data['material'] ?? '';
      _stockController.text = (data['stock'] ?? 0).toString();
      _selectedCategory = data['categories']?['name'] ?? data['categories']?.toString();
      _isFeatured = data['is_featured'] ?? false;
      _isNew = data['is_new'] ?? false;
      _existingImageUrls = List<String>.from(data['images'] ?? []);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load product: $e'), backgroundColor: AppColors.error),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _materialController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    setState(() {
      _selectedImages = images;
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one image'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      List<String> imageUrls = List.from(_existingImageUrls);
      if (_selectedImages.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading images...')),
        );
        final newUrls = await SupabaseService.uploadProductImages(
          images: _selectedImages,
          productName: _nameController.text.trim(),
        );
        imageUrls.addAll(newUrls);
      }

      if (_isEditing) {
        final cats = await SupabaseService.getCategories();
        final matched = cats.cast<Map<String, dynamic>>().firstWhere(
          (c) => c['name'] == _selectedCategory,
          orElse: () => <String, dynamic>{},
        );
        await SupabaseService.updateProduct(
          productId: widget.productId!,
          data: {
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'category_id': matched['id'],
            'price': double.parse(_priceController.text.trim()),
            'discount_price': _discountPriceController.text.trim().isNotEmpty
                ? double.parse(_discountPriceController.text.trim())
                : null,
            'material': _materialController.text.trim(),
            'stock': int.parse(_stockController.text.trim()),
            'is_featured': _isFeatured,
            'is_new': _isNew,
            'images': imageUrls,
          },
        );
      } else {
        await SupabaseService.addProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          categoryName: _selectedCategory!,
          price: double.parse(_priceController.text.trim()),
          discountPrice: _discountPriceController.text.trim().isNotEmpty
              ? double.parse(_discountPriceController.text.trim())
              : null,
          material: _materialController.text.trim(),
          stock: int.parse(_stockController.text.trim()),
          isFeatured: _isFeatured,
          isNew: _isNew,
          imageUrls: imageUrls,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Product updated successfully' : 'Product added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images
              const Text(
                'Product Images',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.greyLight,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _existingImageUrls.isEmpty && _selectedImages.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: AppColors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap to add images',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    itemCount: _existingImageUrls.length + _selectedImages.length,
                    itemBuilder: (context, index) {
                      if (index < _existingImageUrls.length) {
                        final url = _existingImageUrls[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 120,
                                    height: 120,
                                    color: AppColors.greyLight,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _existingImageUrls.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final imageIndex = index - _existingImageUrls.length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_selectedImages[imageIndex].path),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(imageIndex);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Product Name
              CustomTextField(
                label: 'Product Name',
                hint: 'Enter product name',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description
              CustomTextField(
                label: 'Description',
                hint: 'Enter product description',
                controller: _descriptionController,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Price and Discount Price
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Price',
                      hint: '0.00',
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Discount Price',
                      hint: '0.00',
                      controller: _discountPriceController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Material and Stock
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Material',
                      hint: 'e.g., Wood, Metal',
                      controller: _materialController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Stock',
                      hint: '0',
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Switches
              SwitchListTile(
                value: _isFeatured,
                onChanged: (value) {
                  setState(() {
                    _isFeatured = value;
                  });
                },
                title: const Text('Featured Product'),
                activeColor: AppColors.primary,
              ),

              SwitchListTile(
                value: _isNew,
                onChanged: (value) {
                  setState(() {
                    _isNew = value;
                  });
                },
                title: const Text('New Arrival'),
                activeColor: AppColors.primary,
              ),

              const SizedBox(height: 32),

              // Submit Button
              CustomButton(
                text: _isEditing ? 'Update Product' : 'Add Product',
                onPressed: _isProcessing ? null : _saveProduct,
                isLoading: _isProcessing,
                width: double.infinity,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}