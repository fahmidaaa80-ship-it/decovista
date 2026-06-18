import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../data/models/offer_model.dart';
import '../../../providers/offer_provider.dart';

class OfferSection extends ConsumerWidget {
  const OfferSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersProvider);

    return offersAsync.when(
      data: (offers) {
        if (offers.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Special Offers',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _OfferCardWidget(offer: offers[index]),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: LoadingWidget()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _OfferCardWidget extends StatelessWidget {
  final OfferModel offer;

  const _OfferCardWidget({required this.offer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/shop', extra: {'category': offer.categoryName, 'hideSearch': true});
      },
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: offer.backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    offer.title,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: offer.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: offer.textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Shop Now',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: offer.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              offer.discount,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: offer.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
