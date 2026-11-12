import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/shell_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../router/app_routes.dart';
import '../../theme/app_assets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/glass_bottom_nav.dart';
import 'widgets/home_footer.dart';
import 'widgets/inspection_plans.dart';
import 'widgets/promo_banners.dart';
import 'widgets/services_section.dart';

/// Home tab: animated skyline hero, then the home sections.
///
/// Ported from develop one feature at a time — sections whose feature isn't
/// on this branch yet (filter card, hot deals, new launches, post property,
/// trusted builders) are left out for now.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Vertical space between home sections.
  static const double _gap = 28;

  void _openService(String key) {
    // TODO: 'loan' => AppRoutes.homeLoan once Home Loan is ported.
    if (key == 'loan') return context.showSnackBar('Coming soon');
    context.push(switch (key) {
      'inspection' => AppRoutes.inspection,
      'tax' => AppRoutes.consultationFor('taxation'),
      _ => AppRoutes.consultationFor('legal'),
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<HomeController>().start(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = context.read<HomeController>();
    // Includes the glass app bar height (GlassAppBar.overlay adds it).
    final top = MediaQuery.paddingOf(context).top;
    // develop: top + 300, with the filter card overlapping the last 64px.
    final heroHeight = top + 236;

    return RefreshIndicatorWrapper(
      edgeOffset: top,
      onRefresh: home.refresh,
      child: ListView(
        padding: EdgeInsets.only(
          bottom: GlassBottomNav.totalHeight(context) + AppSpacing.lg,
        ),
        children: [
          SizedBox(height: heroHeight, child: _Hero(topInset: top)),
          const SizedBox(height: _gap),
          ServicesSection(onSelect: _openService),
          const SizedBox(height: _gap),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                ReferBanner(
                  onTap: () =>
                      context.read<ShellController>().go(ShellTab.refer),
                ),
                const SizedBox(height: 12),
                InspectionPlansBanner(
                  onBook: (planId) =>
                      context.push(AppRoutes.inspection, extra: planId),
                ),
                const SizedBox(height: 12),
                CompareBanner(onTap: () => context.push(AppRoutes.compare)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const HomeFooter(),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.topInset});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    final city = context.select<HomeController, String>((h) => h.cityLabel);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.6, -0.4),
          radius: 1.3,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Stack(
        children: [
          // Ground sits under the card's top edge, so the buildings
          // look like they stand behind it.
          // SkylineAnimation (widgets/skyline_animation.dart) is kept for
          // switching back.
          Positioned(
            left: 0,
            right: 0,
            bottom: 36,
            height: 170,
            // Full width; the sky at the top of the art is cropped.
            child: ClipRect(
              child: Lottie.asset(
                AppAssets.lottieBuilding,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              topInset + AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find your next home',
                  style: AppTextStyles.heading.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Iconsax.location_copy,
                      size: 14,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Verified properties in $city',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const _SearchBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted search pill in the hero — opens the search screen.
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.pill);
    // Blurs whatever the hero paints behind it (skyline art, gradient).
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.white.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: InkWell(
            borderRadius: radius,
            // TODO: context.push(AppRoutes.search) once Search is ported.
            onTap: () => context.showSnackBar('Coming soon'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.search_normal_1_copy,
                    size: 19,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search projects, builders, localities',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
