import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/package_color_chips.dart';
import '../../../core/widgets/package_image_picker.dart';
import '../../../providers/add_package_provider.dart';


class AddPackageScreen extends ConsumerStatefulWidget {
  /// null = add mode, non-null = edit mode
  final String? packageId;

  const AddPackageScreen({super.key, this.packageId});

  @override
  ConsumerState<AddPackageScreen> createState() => _AddPackageScreenState();
}

class _AddPackageScreenState extends ConsumerState<AddPackageScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Text controllers ──────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _roomSizeCtrl = TextEditingController();

  // ── Dropdown / toggle values ──────────────────────────────────────────────
  String _roomType = 'living_room';
  String? _style;
  bool _isCustomizable = true;
  bool _isFeatured = false;

  // ── Images ────────────────────────────────────────────────────────────────
  File? _previewImageFile;
  String? _previewImageUrl;
  final List<File> _extraImageFiles = [];
  final List<String> _extraImageUrls = [];

  // ── Wall colours ──────────────────────────────────────────────────────────
  final List<String> _wallColors = [];

  bool _isLoading = false;
  bool _editDataLoaded = false;

  // ─────────────────────────────────────────────────────────────────────────

  static const _roomTypes = [
    'living_room',
    'bedroom',
    'dining_room',
    'kitchen',
    'bathroom',
    'office',
    'kids_room',
    'balcony',
    'study_room',
    'gaming_room',
  ];

  static const _styles = [
    'Modern',
    'Contemporary',
    'Minimalist',
    'Traditional',
    'Industrial',
    'Scandinavian',
    'Bohemian',
    'Classic',
  ];

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.packageId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEditData());
    }
  }

  Future<void> _loadEditData() async {
    final notifier = ref.read(addPackageProvider.notifier);
    final package = await notifier.fetchPackage(widget.packageId!);
    if (package == null || !mounted) return;

    setState(() {
      _nameCtrl.text = package.name;
      _descCtrl.text = package.description ?? '';
      _priceCtrl.text = package.price.toStringAsFixed(0);
      _discountCtrl.text = package.discountPrice?.toStringAsFixed(0) ?? '';
      _budgetCtrl.text = package.estimatedBudget?.toStringAsFixed(0) ?? '';
      _roomSizeCtrl.text = package.roomSize ?? '';
      _roomType = package.roomType;
      _style = package.style;
      _isCustomizable = package.isCustomizable;
      _isFeatured = package.isFeatured;
      _previewImageUrl = package.previewImage;
      _extraImageUrls
        ..clear()
        ..addAll(package.images);
      _wallColors
        ..clear()
        ..addAll(package.wallColorSuggestions);
      _editDataLoaded = true;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _budgetCtrl.dispose();
    _roomSizeCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.packageId == null &&
        _previewImageFile == null &&
        _previewImageUrl == null) {
      _showSnack('Please add a preview image', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(addPackageProvider.notifier);

      await notifier.savePackage(
        packageId: widget.packageId,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        roomType: _roomType,
        style: _style,
        price: double.parse(_priceCtrl.text.trim()),
        discountPrice: _discountCtrl.text.trim().isEmpty
            ? null
            : double.parse(_discountCtrl.text.trim()),
        estimatedBudget: _budgetCtrl.text.trim().isEmpty
            ? null
            : double.parse(_budgetCtrl.text.trim()),
        roomSize: _roomSizeCtrl.text.trim().isEmpty
            ? null
            : _roomSizeCtrl.text.trim(),
        isCustomizable: _isCustomizable,
        isFeatured: _isFeatured,
        wallColorSuggestions: _wallColors,
        previewImageFile: _previewImageFile,
        existingPreviewUrl: _previewImageUrl,
        extraImageFiles: _extraImageFiles,
        existingExtraUrls: _extraImageUrls,
      );

      if (mounted) {
        _showSnack(
          widget.packageId == null
              ? 'Package added successfully ✓'
              : 'Package updated successfully ✓',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.packageId != null;

    if (isEdit && !_editDataLoaded) {
      return Scaffold(
        appBar: AppBar(title: Text(isEdit ? 'Edit Package' : 'Add Package')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Package' : 'Add Package'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_outlined),
              label: Text(isEdit ? 'Update' : 'Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Preview Image ─────────────────────────────────────────────
            _SectionHeader(title: 'Preview Image', required: !isEdit),
            PackageImagePicker(
              existingUrl: _previewImageUrl,
              selectedFile: _previewImageFile,
              onPicked: (file) => setState(() => _previewImageFile = file),
              onRemoveExisting: () => setState(() => _previewImageUrl = null),
            ),
            const SizedBox(height: 24),

            // ── Extra Images ──────────────────────────────────────────────
            const _SectionHeader(title: 'Additional Images (optional)'),
            PackageMultiImagePicker(
              existingUrls: _extraImageUrls,
              newFiles: _extraImageFiles,
              onAddFile: (file) => setState(() => _extraImageFiles.add(file)),
              onRemoveExisting: (url) =>
                  setState(() => _extraImageUrls.remove(url)),
              onRemoveNew: (file) =>
                  setState(() => _extraImageFiles.remove(file)),
            ),
            const SizedBox(height: 24),

            // ── Basic Info ────────────────────────────────────────────────
            const _SectionHeader(title: 'Basic Info'),
            const SizedBox(height: 12),
            _field(
              controller: _nameCtrl,
              label: 'Package Name',
              hint: 'e.g. Modern Living Room Pro',
              required: true,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _descCtrl,
              label: 'Description',
              hint: 'Write details about the package',
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // ── Room Details ──────────────────────────────────────────────
            const _SectionHeader(title: 'Room Details'),
            const SizedBox(height: 12),
            _dropdown(
              label: 'Room Type',
              value: _roomType,
              items: _roomTypes,
              onChanged: (v) => setState(() => _roomType = v!),
            ),
            const SizedBox(height: 12),
            _dropdownNullable(
              label: 'Style (optional)',
              value: _style,
              items: _styles,
              onChanged: (v) => setState(() => _style = v),
            ),
            const SizedBox(height: 12),
            _field(
              controller: _roomSizeCtrl,
              label: 'Room Size (optional)',
              hint: 'e.g. 10x12 ft',
            ),
            const SizedBox(height: 24),

            // ── Pricing ───────────────────────────────────────────────────
            const _SectionHeader(title: 'Pricing'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    controller: _priceCtrl,
                    label: 'Price (৳)',
                    hint: '5000',
                    required: true,
                    inputType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    controller: _discountCtrl,
                    label: 'Discount Price (৳)',
                    hint: '4200',
                    inputType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      if (double.tryParse(v) == null) return 'Enter a valid number';
                      final price = double.tryParse(_priceCtrl.text) ?? 0;
                      final discount = double.parse(v);
                      if (discount >= price) return 'Must be less than the original price';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(
              controller: _budgetCtrl,
              label: 'Estimated Implementation Budget (৳)',
              hint: '50000',
              inputType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // ── Wall Colours ──────────────────────────────────────────────
            const _SectionHeader(title: 'Wall Color Suggestions (optional)'),
            const SizedBox(height: 12),
            PackageColorChips(
              colors: _wallColors,
              onAdd: (color) => setState(() => _wallColors.add(color)),
              onRemove: (color) => setState(() => _wallColors.remove(color)),
            ),
            const SizedBox(height: 24),

            // ── Flags ─────────────────────────────────────────────────────
            const _SectionHeader(title: 'Settings'),
            const SizedBox(height: 8),
            _toggleTile(
              title: 'Customizable',
              subtitle: 'Customer can customize this package',
              value: _isCustomizable,
              onChanged: (v) => setState(() => _isCustomizable = v),
            ),
            _toggleTile(
              title: 'Featured',
              subtitle: 'Will be highlighted on the home screen',
              value: _isFeatured,
              onChanged: (v) => setState(() => _isFeatured = v),
            ),
            const SizedBox(height: 32),

            // ── Submit button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : Text(
                  isEdit ? 'Update Package' : 'Add Package',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty)
              ? 'Please enter $label'
              : null
              : null),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      items: items
          .map((e) => DropdownMenuItem(
          value: e, child: Text(_formatRoomType(e))))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _dropdownNullable({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('— None —')),
        ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textSecondary)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  String _formatRoomType(String raw) =>
      raw.split('_').map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool required;

  const _SectionHeader({required this.title, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$title *' : title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Divider(),
      ],
    );
  }
}