import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PackageColorChips extends StatelessWidget {
  final List<String> colors;
  final void Function(String) onAdd;
  final void Function(String) onRemove;

  const PackageColorChips({
    super.key,
    required this.colors,
    required this.onAdd,
    required this.onRemove,
  });

  void _showAddDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wall Color যোগ করুন'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Warm White, Sage Green',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isNotEmpty) onAdd(val);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...colors.map(
              (color) => Chip(
            label: Text(color),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => onRemove(color),
            backgroundColor: AppColors.primary.withOpacity(0.1),
            labelStyle: const TextStyle(color: AppColors.primary),
            side: const BorderSide(color: AppColors.primary, width: 0.5),
          ),
        ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 16, color: AppColors.primary),
          label: const Text('Add Color',
              style: TextStyle(color: AppColors.primary)),
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: AppColors.primary),
          onPressed: () => _showAddDialog(context),
        ),
      ],
    );
  }
}