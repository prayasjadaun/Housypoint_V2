import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
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
    final deals = context.select<HomeController, DistressDeals?>(
      (h) => h.hotDeals,
    );
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
                child: const Icon(
                  Iconsax.flash_1_copy,
                  size: 18,
                  color: AppColors.accentRose,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hot deals', style: AppTextStyles.title),
                    Text(
                      'Priced below market — grab them fast',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DealTabs(
          tabs: [
            for (final (key, label) in _tabs)
              (label: label, count: deals?.tab(key).length),
          ],
          selectedIndex: _tabs.indexWhere((t) => t.$1 == _tab),
          onChanged: (i) {
            if (_tabs[i].$1 == _tab) return;
            AppHaptics.selection();
            setState(() => _tab = _tabs[i].$1);
          },
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 330,
          child: deals == null
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: 2,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, _) => const SkeletonBox(
                    width: 260,
                    height: 330,
                    radius: AppRadius.xl,
                  ),
                )
              : items.isEmpty
              ? Center(
                  child: Text(
                    'No deals in this category right now',
                    style: AppTextStyles.caption,
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
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
                          AppRoutes.listingPath(
                            l.id,
                            rental: l.isRental,
                            hotDeal: true,
                          ),
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

/// Deal tabs — alag-alag glass chips, horizontal scroll.
/// iOS 26+: package ka native Liquid Glass button ([AdaptiveButton.child]) —
/// unselected = clear glass, selected = brand-green prominent glass.
/// Baaki platforms: same look Flutter me (soft surface chip / green chip).
class _DealTabs extends StatelessWidget {
  const _DealTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<({String label, int? count})> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const double _chipHeight = 36;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final dark = AppColors.isDark;

    return MediaQuery(
      // Native glass app ka light/dark follow kare (nav bar jaisa)
      data: mq.copyWith(
        platformBrightness: dark ? Brightness.dark : Brightness.light,
      ),
      child: SizedBox(
        // Glass ki shadow/edge clip na ho
        height: _chipHeight + 8,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          itemCount: tabs.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) => _DealChip(
            label: tabs[i].label,
            count: tabs[i].count,
            selected: i == selectedIndex,
            onTap: () => onChanged(i),
          ),
        ),
      ),
    );
  }
}

class _DealChip extends StatelessWidget {
  const _DealChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textPrimary;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          textScaler: TextScaler.noScaling,
          style: AppTextStyles.caption.copyWith(
            color: fg,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            constraints: const BoxConstraints(minWidth: 20),
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.25)
                  : AppColors.textPrimary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              textScaler: TextScaler.noScaling,
              style: AppTextStyles.caption.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );

    if (PlatformInfo.isIOS26OrHigher()) {
      return Center(
        child: AdaptiveButton.child(
          onPressed: onTap,
          style: selected
              ? AdaptiveButtonStyle.prominentGlass
              : AdaptiveButtonStyle.glass,
          // Hamesha green do: null par native button .systemBlue rakh leta hai
          // aur select hone par wahi blue prominent glass ban jaata tha. Clear
          // glass me tint sirf text ka hota hai (text Flutter draw karta hai),
          // to unselected par koi rang nahi dikhta.
          color: AppColors.primary,
          size: AdaptiveButtonSize.medium,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          useSmoothRectangleBorder: false,
          child: content,
        ),
      );
    }

    // Same chip, package ke AdaptiveBlurView glass me. Rang sirf selected
    // par — translucent brand green glass; baaki clear frosted glass.
    final radius = BorderRadius.circular(_DealTabs._chipHeight / 2);
    return GestureDetector(
      onTap: onTap,
      // Shadow ClipRRect ke bahar, warna kat jaati hai
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AdaptiveBlurView(
          borderRadius: radius,
          blurStyle: BlurStyle.systemThinMaterial,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: _DealTabs._chipHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: selected
                    ? [
                        AppColors.primary.withValues(alpha: 0.78),
                        AppColors.primary.withValues(alpha: 0.92),
                      ]
                    : [
                        AppColors.primary.withValues(alpha: 0),
                        AppColors.primary.withValues(alpha: 0),
                      ],
              ),
              border: Border.all(
                width: 0.8,
                color: Colors.white.withValues(alpha: selected ? 0.35 : 0),
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
