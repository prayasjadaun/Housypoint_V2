import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/glass_bottom_nav.dart';
import 'widgets/menu_card.dart';

/// Last bottom-nav tab — every feature that doesn't have its own tab.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    void go(String route) => context.push(route);

    final sections = <(String, List<MenuCard>)>[
      (
        'Services',
        [
          MenuCard(title: 'Home\nInspection', subtitle: 'Book a PDI for your flat', icon: Iconsax.shield_tick_copy, color: AppColors.primary, onTap: () => go(AppRoutes.inspection)),
          MenuCard(title: 'Expert\nConsultation', subtitle: 'Legal, tax & property advice', icon: Iconsax.messages_2_copy, color: AppColors.accentAmber, onTap: () => go(AppRoutes.consultation)),
          MenuCard(title: 'Home Loan', subtitle: 'EMI calculator & banks', icon: Iconsax.money_recive_copy, color: AppColors.accentEmerald, onTap: () => go(AppRoutes.homeLoan)),
          MenuCard(title: 'Compare\nProjects', subtitle: 'Side-by-side comparison', icon: Iconsax.chart_2_copy, color: AppColors.accentIndigo, onTap: () => go(AppRoutes.compare)),
        ],
      ),
      (
        'Explore',
        [
          MenuCard(title: 'Builders', subtitle: 'Top developers & projects', icon: Iconsax.buildings_2_copy, color: AppColors.accentSky, onTap: () => go(AppRoutes.builders)),
          MenuCard(title: 'Search', subtitle: 'Projects, builders, areas', icon: Iconsax.search_normal_1_copy, color: AppColors.accentViolet, onTap: () => go(AppRoutes.search)),
        ],
      ),
      (
        'Post',
        [
          MenuCard(title: 'Sell\nProperty', subtitle: 'Zero brokerage', icon: Iconsax.key_copy, color: AppColors.primary, onTap: () => go(AppRoutes.sell)),
          MenuCard(title: 'Rent Out\nProperty', subtitle: 'Find good tenants', icon: Iconsax.home_hashtag_copy, color: AppColors.accentSky, onTap: () => go(AppRoutes.rentOut)),
          MenuCard(title: 'Buy a\nProperty', subtitle: 'Share your requirement', icon: Iconsax.search_status_copy, color: AppColors.goldDark, onTap: () => go(AppRoutes.buy)),
          MenuCard(title: 'My\nListings', subtitle: 'Properties you posted', icon: Iconsax.document_text_copy, color: AppColors.accentViolet, onTap: () => go(AppRoutes.myListings)),
        ],
      ),
      (
        'My account',
        [
          MenuCard(title: 'Profile', subtitle: 'Account, support & settings', icon: Iconsax.user_copy, color: AppColors.accentBlue, onTap: () => go(AppRoutes.profile)),
        ],
      ),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        padding.top + AppSpacing.md,
        AppSpacing.md,
        GlassBottomNav.totalHeight(context) + AppSpacing.lg,
      ),
      children: [
        for (final (title, cards) in sections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text(
              title.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            children: cards,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}
