import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/shell_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/glass_bottom_nav.dart';
import 'widgets/menu_card.dart';

/// Last bottom-nav tab — every feature that doesn't have its own tab.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    void comingSoon() => context.showSnackBar('Coming soon');

    final cards = [
      MenuCard(
        title: 'Home\nInspection',
        subtitle: 'Book a PDI for your flat',
        icon: Iconsax.shield_tick_copy,
        color: AppColors.primary,
        onTap: () => context.push(AppRoutes.inspection),
      ),
      MenuCard(
        title: 'Expert\nConsultation',
        subtitle: 'Legal, tax & property advice',
        icon: Iconsax.messages_2_copy,
        color: AppColors.accentAmber,
        onTap: () => context.push(AppRoutes.consultation),
      ),
      MenuCard(
        title: 'Compare\nProjects',
        subtitle: 'Side-by-side comparison',
        icon: Iconsax.chart_2_copy,
        color: AppColors.accentIndigo,
        onTap: comingSoon,
      ),
      MenuCard(
        title: 'Builders',
        subtitle: 'Top developers & projects',
        icon: Iconsax.buildings_2_copy,
        color: AppColors.accentSky,
        onTap: comingSoon,
      ),
      MenuCard(
        title: 'Home Loan',
        subtitle: 'Rates & EMI calculator',
        icon: Iconsax.money_recive_copy,
        color: AppColors.accentEmerald,
        onTap: comingSoon,
      ),
      MenuCard(
        title: 'My\nListings',
        subtitle: 'Properties you posted',
        icon: Iconsax.document_text_copy,
        color: AppColors.accentViolet,
        onTap: comingSoon,
      ),
      MenuCard(
        title: 'My\nBookings',
        subtitle: 'Inspections & consultations',
        icon: Iconsax.calendar_tick_copy,
        color: AppColors.accentBlue,
        onTap: comingSoon,
      ),
      MenuCard(
        title: 'Refer &\nEarn',
        subtitle: 'Invite friends, earn rewards',
        icon: Iconsax.gift_copy,
        color: AppColors.accentRose,
        onTap: () => context.read<ShellController>().go(ShellTab.refer),
      ),
      MenuCard(
        title: 'Support',
        subtitle: 'Call, WhatsApp or email us',
        icon: Iconsax.headphone_copy,
        color: AppColors.goldDark,
        onTap: comingSoon,
      ),
      MenuCard(
        title: 'Profile',
        subtitle: 'Account, support & settings',
        icon: Iconsax.user_octagon_copy,
        color: AppColors.accentEmerald,
        onTap: () => context.push(AppRoutes.profile),
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
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        ),
      ],
    );
  }
}
