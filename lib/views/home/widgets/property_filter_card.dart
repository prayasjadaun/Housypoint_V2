import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../controllers/home_controller.dart';
import '../../../controllers/listings_controller.dart';
import '../../../controllers/shell_controller.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../models/listing/listing_counts.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/segmented_toggle.dart';
import '../../../widgets/common/skeleton_box.dart';
import '../../../widgets/pickers/location_pickers.dart';
import 'size_options.dart';

/// The home "USP filter": where (city, builder), what (buy / rent /
/// commercial) and how many listings each size has — as a ranked list
/// with proportional bars.
class PropertyFilterCard extends StatelessWidget {
  const PropertyFilterCard({super.key});

  void _openListings(BuildContext context, HomeController home, {String? sizeKey}) {
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

  /// Buy / Rent / Commercial → (category, deal).
  int _tabOf(HomeController h) => h.category == PropertyCategory.commercial
      ? 2
      : (h.deal == DealType.rent ? 1 : 0);

  void _onTab(HomeController h, int i) {
    if (i == 2) {
      h.setCategory(PropertyCategory.commercial);
    } else {
      h.setCategory(PropertyCategory.residential);
      h.setDeal(i == 1 ? DealType.rent : DealType.sale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final counts = home.counts;
    final total = counts == null ? null : counts.totalSale + counts.totalRent;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 18, AppSpacing.md, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl + 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Explore properties', style: AppTextStyles.title),
          const SizedBox(height: 2),
          total == null
              ? const Align(alignment: Alignment.centerLeft, child: SkeletonBox(width: 120, height: 12))
              : Text(
                  '$total verified listings',
                  style: AppTextStyles.caption,
                ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: _FilterPill(
                  icon: Iconsax.location_copy,
                  label: home.cityLabel,
                  active: home.selectedCity != null,
                  onTap: () => _pickCity(context, home),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _FilterPill(
                  icon: Iconsax.buildings_2_copy,
                  label: home.builderLabel,
                  active: home.selectedBuilder != null,
                  onTap: () => _pickBuilder(context, home),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedToggle(
            labels: const ['Buy', 'Rent', 'Commercial'],
            selectedIndex: _tabOf(home),
            onChanged: (i) => _onTab(home, i),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: home.category == PropertyCategory.commercial
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Text('Looking to', style: AppTextStyles.caption),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 150,
                          child: SegmentedToggle(
                            labels: const ['Buy', 'Rent'],
                            height: 34,
                            selectedIndex: home.deal.index,
                            onChanged: (i) => home.setDeal(DealType.values[i]),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _SizeList(
              key: ValueKey('${home.category}-${home.deal}'),
              home: home,
              onTap: (key) => _openListings(context, home, sizeKey: key),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          TextButton(
            onPressed: home.currentTotal > 0 ? () => _openListings(context, home) : null,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const RoundedRectangleBorder(),
            ),
            child: Row(
              children: [
                Text(
                  home.counts == null ? 'View all properties' : 'View all ${home.currentTotal} properties',
                  style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                const Icon(Iconsax.arrow_right_3_copy, size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact outlined dropdown pill (city / builder).
class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.icon, required this.label, required this.active, required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textPrimary;
    return Material(
      color: active ? AppColors.primarySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: active ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: active ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Iconsax.arrow_down_1_copy, size: 13, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sizes ranked by listing count, each with a bar scaled to the largest.
class _SizeList extends StatelessWidget {
  const _SizeList({super.key, required this.home, required this.onTap});

  final HomeController home;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (home.countsError != null && home.counts == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
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

    final options = home.category == PropertyCategory.residential ? residentialTiles : commercialTiles;
    final counts = home.counts;

    if (counts == null) {
      return Column(
        children: [
          for (var i = 0; i < 4; i++)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SkeletonBox(width: 56, height: 12),
                  SizedBox(width: 14),
                  Expanded(child: SkeletonBox(width: double.infinity, height: 6)),
                  SizedBox(width: 14),
                  SkeletonBox(width: 28, height: 12),
                ],
              ),
            ),
        ],
      );
    }

    final rows = [
      for (final o in options) (o, counts.count(home.deal, home.category, o.key)),
    ].where((r) => r.$2 > 0).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Iconsax.search_status_copy, color: AppColors.textTertiary),
            const SizedBox(height: 6),
            Text('No listings here yet — try another city or tab.', style: AppTextStyles.caption),
          ],
        ),
      );
    }

    final max = rows.first.$2;
    return Column(
      children: [
        for (final (option, count) in rows)
          _SizeRow(
            option: option,
            count: count,
            share: count / max,
            onTap: () => onTap(option.key),
          ),
      ],
    );
  }
}

class _SizeRow extends StatelessWidget {
  const _SizeRow({required this.option, required this.count, required this.share, required this.onTap});

  final SizeOption option;
  final int count;

  /// 0–1, relative to the largest row.
  final double share;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Row(
                children: [
                  if (option.icon != null) ...[
                    Icon(option.icon, size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 6,
                  color: AppColors.background,
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: share.clamp(0.04, 1)),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '$count',
                textAlign: TextAlign.right,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Iconsax.arrow_right_3_copy, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
