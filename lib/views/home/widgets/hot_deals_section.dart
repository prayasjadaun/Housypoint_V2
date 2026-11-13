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
          labels: [
            for (final (key, label) in _tabs)
              switch (deals?.tab(key).length) {
                null => label,
                final n => '$label · $n',
              },
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

/// Deal tabs — package ka [AdaptiveSegmentedControl]. iOS 26+ par native
/// UISegmentedControl (Liquid Glass, sliding glass thumb — nav bar jaisa),
/// iOS <26 par CupertinoSlidingSegmentedControl, Android par SegmentedButton.
class _DealTabs extends StatelessWidget {
  const _DealTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const double _height = 36;

  // Native segments barabar width ke hote hain — sabse lambe label jitne.
  double _segmentWidth(BuildContext context) {
    var widest = 0.0;
    for (final l in labels) {
      final w = (TextPainter(
        text: TextSpan(
          text: l,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout()).width;
      if (w > widest) widest = w;
    }
    return widest + 28;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final dark = AppColors.isDark;
    final native = PlatformInfo.isIOS26OrHigher();

    return LayoutBuilder(
      builder: (context, c) {
        final available = c.maxWidth - AppSpacing.md * 2;
        final needed = _segmentWidth(context) * labels.length;
        final width = needed > available ? needed : available;

        final control = MediaQuery(
          // Nav bar ki tarah app ka light/dark follow karwao
          data: mq.copyWith(
            platformBrightness: dark ? Brightness.dark : Brightness.light,
          ),
          child: AdaptiveSegmentedControl(
            // Native control labels baad me update nahi karta — counts
            // aane par naya bane
            key: ValueKey(labels.join('|')),
            labels: labels,
            selectedIndex: selectedIndex,
            onValueChanged: onChanged,
            height: _height,
            // iOS 26: tint mat do — selectedSegmentTintColor thumb ko solid
            // bhar deta hai aur native white glass thumb chala jaata hai.
            color: native ? null : AppColors.primary,
            textColor: dark ? Colors.white : Colors.black,
            selectedTextColor: native ? AppColors.primary : Colors.white,
          ),
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: SizedBox(
            width: width,
            height: _height,
            child: native
                // Native UiKitView horizontal drag/pan khud pakad leta hai, to
                // scroll view tak gesture nahi pahunchta — row fixed lagti hai.
                // Native view ko touch se alag karo; tap Flutter me pakdo aur
                // selectedIndex bhejo — glass thumb natively slide karta hai.
                ? Stack(
                    children: [
                      Positioned.fill(child: IgnorePointer(child: control)),
                      Positioned.fill(
                        child: Row(
                          children: [
                            for (var i = 0; i < labels.length; i++)
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => onChanged(i),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                : control,
          ),
        );
      },
    );
  }
}
