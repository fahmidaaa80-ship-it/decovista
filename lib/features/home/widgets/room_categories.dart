import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class RoomCategories extends StatelessWidget {
  const RoomCategories({super.key});

  final List<RoomCategory> _categories = const [
    RoomCategory(
      name: 'Bedroom',
      icon: Icons.bed_outlined,
      roomType: 'bedroom',
    ),
    RoomCategory(
      name: 'Living Room',
      icon: Icons.weekend_outlined,
      roomType: 'living_room',
    ),
    RoomCategory(
      name: 'Dining Room',
      icon: Icons.restaurant_outlined,
      roomType: 'dining_room',
    ),
    RoomCategory(
      name: 'Kitchen',
      icon: Icons.kitchen_outlined,
      roomType: 'kitchen',
    ),
    RoomCategory(
      name: 'Bathroom',
      icon: Icons.bathtub_outlined,
      roomType: 'bathroom',
    ),
    RoomCategory(
      name: 'Office',
      icon: Icons.business_center_outlined,
      roomType: 'office',
    ),
    RoomCategory(
      name: 'Kids Room',
      icon: Icons.child_care_outlined,
      roomType: 'kids_room',
    ),
    RoomCategory(
      name: 'Balcony',
      icon: Icons.deck_outlined,
      roomType: 'balcony',
    ),
    RoomCategory(
      name: 'Study Room',
      icon: Icons.menu_book_outlined,
      roomType: 'study_room',
    ),
    RoomCategory(
      name: 'Gaming Room',
      icon: Icons.sports_esports_outlined,
      roomType: 'gaming_room',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Room Design Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            return _CategoryCard(category: _categories[index]);
          },
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final RoomCategory category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/designs?roomType=${category.roomType}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomCategory {
  final String name;
  final IconData icon;
  final String roomType;

  const RoomCategory({
    required this.name,
    required this.icon,
    required this.roomType,
  });
}