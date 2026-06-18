import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../data/models/banner_model.dart';
import '../../../providers/banner_provider.dart';

class HeroSection extends ConsumerStatefulWidget {
  const HeroSection({super.key});

  @override
  ConsumerState<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends ConsumerState<HeroSection> {
  int _current = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);
    const carouselHeight = 300.0;

    return bannersAsync.when(
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            CarouselSlider(
              carouselController: _controller,
              options: CarouselOptions(
                height: carouselHeight,
                viewportFraction: 1.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                onPageChanged: (index, reason) {
                  setState(() {
                    _current = index;
                  });
                },
              ),
              items: banners.map((banner) {
                return Builder(
                  builder: (BuildContext context) {
                    return _BannerItem(banner: banner);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: banners.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => _controller.animateToPage(entry.key),
                  child: Container(
                    width: _current == entry.key ? 24.0 : 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _current == entry.key
                          ? AppColors.primary
                          : AppColors.greyLight,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => SizedBox(
        height: carouselHeight,
        child: const Center(child: LoadingWidget()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _BannerItem extends StatelessWidget {
  final BannerModel banner;

  const _BannerItem({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.network(
            banner.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.greyLight,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.4),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: 0,
          bottom: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                banner.title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                banner.subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                width: 150,
                text: banner.primaryAction,
                onPressed: () {
                  final text = banner.primaryAction.toLowerCase();
                  if (text.contains('view package')) {
                    context.push('/designs');
                  } else {
                    context.push('/shop');
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
