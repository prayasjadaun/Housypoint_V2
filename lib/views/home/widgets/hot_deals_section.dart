import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../controllers/home_controller.dart';
import '../../../controllers/saved_controller.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../repositories/listing_repository.dart';
import '../../../router/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/skeleton_box.dart';
import '../../listings/widgets/property_card.dart';

/// "Hot deals" — below-market (distress) listings, four tabs like V1.
class HotDealsSection extends StatefulWidget {
  const HotDealsSection({super.key});

  @override
  State<HotDealsSection> createState() => _HotDealsSectionState();
}

class _HotDealsSectionState extends State<HotDealsSection> {
  static const _tabs = [
    ('resale', 'Resale'),
    ('rent', 'Rent'),
    ('resale_commercial', 'Commercial sale'),
    ('rent_commercial', 'Commercial rent'),
  ];

  String _tab = 'resale';

  @override
  Widget build(BuildContext context) {
    final deals = context.select<HomeController, DistressDeals?>((h) => h.hotDeals);
    final saved = context.watch<SavedController>();

    // Hide entirely once loaded with nothing to show.
    if (deals != null && deals.isEmpty) return const SizedBox.shrink();

    final items = deals?.tab(_tab) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.accentRose.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                ),
                child: const Icon(Iconsax.flash_1_copy, size: 18, color: AppColors.accentRose),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hot deals', style: AppTextStyles.title),
                    Text('Priced below market — grab them fast', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: _tabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final (key, label) = _tabs[i];
              final count = deals?.tab(key).length;
              final selected = key == _tab;
              return GestureDetector(
                onTap: () {
                  AppHaptics.selection();
                  setState(() => _tab = key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.textPrimary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: selected ? AppColors.textPrimary : AppColors.border),
                  ),
                  child: Text(
                    count == null ? label : '$label · $count',
                    style: AppTextStyles.caption.copyWith(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 330,
          child: deals == null
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: 2,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, _) =>
                      const SkeletonBox(width: 260, height: 330, radius: AppRadius.xl),
                )
              : items.isEmpty
              ? Center(
                  child: Text('No deals in this category right now', style: AppTextStyles.caption),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final l = items[i];
                    return SizedBox(
                      width: 260,
                      child: PropertyCard(
                        listing: l,
                        badge: 'Hot deal',
                        isSaved: saved.savedState(l),
                        onSave: () async {
                          final error = await saved.toggleSave(l);
                          if (error != null && context.mounted) {
                            context.showSnackBar(error, isError: true);
                          }
                        },
                        onTap: () => context.push(
                          AppRoutes.listingPath(l.id, rental: l.isRental, hotDeal: true),
                          extra: l,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
