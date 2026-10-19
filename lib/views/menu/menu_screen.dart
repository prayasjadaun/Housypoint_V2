import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/glass_bottom_nav.dart';
import 'widgets/menu_card.dart';

/// 6th bottom-nav tab — every feature that doesn't have its own tab.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key, required this.onTabChangeRequest});

  /// Switches the shell's bottom-nav tab (e.g. Refer, Profile).
  final ValueChanged<int> onTabChangeRequest;

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
        onTap: comingSoon,
      ),
      MenuCard(
        title: 'Expert\nConsultation',
        subtitle: 'Talk to a property expert',
        icon: Iconsax.messages_2_copy,
        color: AppColors.accentAmber,
        onTap: comingSoon,
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
        onTap: () => onTabChangeRequest(3),
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
        subtitle: 'Account & settings',
        icon: Iconsax.user_octagon_copy,
        color: AppColors.accentEmerald,
        onTap: () => onTabChangeRequest(4),
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
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        ),
        const SizedBox(height: AppSpacing.md),
        const _LogoutTile(),
      ],
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile();

  Future<void> _confirm(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need your mobile number and an OTP to log back in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      await context.read<AuthController>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _confirm(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Iconsax.logout_copy, color: AppColors.error, size: 22),
              const SizedBox(width: 12),
              Text(
                'Log out',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
