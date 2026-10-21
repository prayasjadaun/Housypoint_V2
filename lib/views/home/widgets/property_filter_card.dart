import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../controllers/home_controller.dart';
import '../../../controllers/listings_controller.dart';
import '../../../controllers/shell_controller.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../models/listing/listing_counts.dart';
import '../../../router/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/skeleton_box.dart';
import '../../../widgets/pickers/location_pickers.dart';
import 'size_options.dart';

/// The home "USP filter" (V1 layout, V2 styling): owner strip, city and
/// builder pickers, four deal tabs and listing counts per size.
class PropertyFilterCard extends StatelessWidget {
  const PropertyFilterCard({super.key});

  static const _tabs = [
    ('Resale', DealType.sale, PropertyCategory.residential),
    ('Rent', DealType.rent, PropertyCategory.residential),
    ('Commercial sale', DealType.sale, PropertyCategory.commercial),
    ('Commercial rent', DealType.rent, PropertyCategory.commercial),
  ];

  void _openListings(BuildContext context, HomeController home, String sizeKey) {
    context.read<ListingsController>().applyFilter(
      deal: home.deal,
      category: home.category,
      sizeKey: sizeKey,
      city: home.selectedCity,
      builder: home.selectedBuilder,
    );
    context.read<ShellController>().go(ShellTab.listings);
  }

  Future<void> _pickCity(BuildContext context, HomeController home) async {
    AppHaptics.selection();
    await home.ensureCities();
    if (!context.mounted) return;
    final result = await showCityPicker(context, cities: home.cities, selected: home.selectedCity);
    if (result.picked) home.selectCity(result.value);
  }

  Future<void> _pickBuilder(BuildContext context, HomeController home) async {
    AppHaptics.selection();
    final result = await showBuilderPicker(
      context,
      builders: home.builders,
      selected: home.selectedBuilder,
      cityLabel: home.cityLabel,
    );
    if (result.picked) home.selectBuilder(result.value);
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final radius = BorderRadius.circular(AppRadius.xl + 4);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _OwnerStrip(),
          // Pickers sit on a soft band, like V1
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _PickerCard(
                    icon: Iconsax.location_copy,
                    caption: 'City',
                    value: home.cityLabel,
                    onTap: () => _pickCity(context, home),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PickerCard(
                    icon: Iconsax.buildings_2_copy,
                    caption: 'Builder',
                    value: home.builderLabel,
                    onTap: () => _pickBuilder(context, home),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 14, AppSpacing.md, 10),
              itemCount: _tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (label, deal, category) = _tabs[i];
                return _TabPill(
                  label: label,
                  count: home.counts?.total(deal, category),
                  selected: home.deal == deal && home.category == category,
                  onTap: () {
                    home.setCategory(category);
                    home.setDeal(deal);
                  },
                );
              },
            ),
          ),
          Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md, color: AppColors.border),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _Counts(
              key: ValueKey(home.category),
              home: home,
              onTap: (key) => _openListings(context, home, key),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.finger_cricle_copy, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Tap a count to see listings', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Are you a property owner? Sell for free ›" across the card's top edge.
class _OwnerStrip extends StatelessWidget {
  const _OwnerStrip();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
        ),
        child: InkWell(
          onTap: () {
            AppHaptics.tap();
            context.push(AppRoutes.sell);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.house_2_copy, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      style: AppTextStyles.label.copyWith(color: Colors.white),
                      children: [
                        const TextSpan(text: 'Are you a property owner?  '),
                        TextSpan(
                          text: 'Sell for free',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Iconsax.arrow_right_3_copy, size: 16, color: AppColors.gold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White dropdown card (city / builder) on the grey band.
class _PickerCard extends StatelessWidget {
  const _PickerCard({required this.icon, required this.caption, required this.value, required this.onTap});

  final IconData icon;
  final String caption;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                  child: Icon(icon, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(caption, style: AppTextStyles.caption.copyWith(fontSize: 10.5, height: 1.2)),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700, height: 1.3),
                      ),
                    ],
                  ),
                ),
                Icon(Iconsax.arrow_down_1_copy, size: 14, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({required this.label, required this.count, required this.selected, required this.onTap});

  final String label;

  /// Null while loading.
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (selected) return;
        AppHaptics.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.2) : AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Size columns: label on top, tappable count badge below.
class _Counts extends StatelessWidget {
  const _Counts({super.key, required this.home, required this.onTap});

  final HomeController home;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (home.countsError != null && home.counts == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 14, AppSpacing.md, 6),
        child: Row(
          children: [
            const Icon(Iconsax.warning_2_copy, size: 18, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(child: Text(home.countsError!, style: AppTextStyles.caption)),
            TextButton(onPressed: home.loadCounts, child: const Text('Retry')),
          ],
        ),
      );
    }

    final residential = home.category == PropertyCategory.residential;
    final options = residential ? residentialTiles : commercialTiles;
    Widget cell(SizeOption o) => _SizeCell(
      option: o,
      residential: residential,
      count: home.counts?.count(home.deal, home.category, o.key),
      onTap: () => onTap(o.key),
    );

    // Six BHK sizes fit the width; nine commercial types scroll.
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: residential
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(children: [for (final o in options) Expanded(child: cell(o))]),
            )
          : SizedBox(
              height: 84,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [for (final o in options) SizedBox(width: 76, child: cell(o))],
              ),
            ),
    );
  }
}

class _SizeCell extends StatelessWidget {
  const _SizeCell({required this.option, required this.residential, required this.count, required this.onTap});

  final SizeOption option;
  final bool residential;

  /// Null while loading.
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final has = (count ?? 0) > 0;
    final parts = option.label.split(' ');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: has
          ? () {
              AppHaptics.tap();
              onTap();
            }
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (residential && parts.length == 2)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: parts[0], style: AppTextStyles.title.copyWith(fontSize: 16)),
                  TextSpan(text: ' ${parts[1]}', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                ],
              ),
            )
          else ...[
            if (!residential && option.icon != null) ...[
              Icon(option.icon, size: 18, color: has ? AppColors.primary : AppColors.textTertiary),
              const SizedBox(height: 3),
            ],
            Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600, height: 1.4),
            ),
          ],
          const SizedBox(height: 8),
          if (count == null)
            const SkeletonBox(width: 34, height: 26, radius: AppRadius.pill)
          else
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              constraints: const BoxConstraints(minWidth: 38),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: has ? AppColors.primarySoft : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: has ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: count!.toDouble()),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  '${value.round()}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: has ? AppColors.primaryDark : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
