import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../providers/design_package_provider.dart';
import '../widgets/design_package_card.dart';

class DesignsListScreen extends ConsumerStatefulWidget {
  final String? roomType;

  const DesignsListScreen({super.key, this.roomType});

  @override
  ConsumerState<DesignsListScreen> createState() => _DesignsListScreenState();
}

class _DesignsListScreenState extends ConsumerState<DesignsListScreen> {
  String _selectedRoomType = 'all';

  final List<RoomTypeFilter> _roomTypes = [
    RoomTypeFilter(label: 'All', value: 'all'),
    RoomTypeFilter(label: 'Bedroom', value: 'bedroom'),
    RoomTypeFilter(label: 'Living Room', value: 'living_room'),
    RoomTypeFilter(label: 'Dining Room', value: 'dining_room'),
    RoomTypeFilter(label: 'Kitchen', value: 'kitchen'),
    RoomTypeFilter(label: 'Bathroom', value: 'bathroom'),
    RoomTypeFilter(label: 'Office', value: 'office'),
    RoomTypeFilter(label: 'Kids Room', value: 'kids_room'),
    RoomTypeFilter(label: 'Balcony', value: 'balcony'),
    RoomTypeFilter(label: 'Study Room', value: 'study_room'),
    RoomTypeFilter(label: 'Gaming Room', value: 'gaming_room'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.roomType != null) {
      _selectedRoomType = widget.roomType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final packagesAsync = _selectedRoomType == 'all'
        ? ref.watch(allPackagesProvider)
        : ref.watch(packagesByRoomTypeProvider(_selectedRoomType));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Packages'),
      ),
      body: Column(
        children: [
          // Room Type Filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _roomTypes.length,
              itemBuilder: (context, index) {
                final roomType = _roomTypes[index];
                final isSelected = _selectedRoomType == roomType.value;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(roomType.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRoomType = roomType.value;
                      });
                    },
                    backgroundColor: AppColors.greyLight,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),

          // Packages Grid
          Expanded(
            child: packagesAsync.when(
              data: (packages) {
                if (packages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.design_services_outlined,
                          size: 80,
                          color: AppColors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No design packages available',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(6),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    return DesignPackageCard(package: packages[index]);
                  },
                );
              },
              loading: () => const LoadingWidget(message: 'Loading packages...'),
              error: (error, stack) => CustomErrorWidget(
                message: 'Failed to load packages',
                onRetry: () {
                  ref.invalidate(allPackagesProvider);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoomTypeFilter {
  final String label;
  final String value;

  RoomTypeFilter({required this.label, required this.value});
}