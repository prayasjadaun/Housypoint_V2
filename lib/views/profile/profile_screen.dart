import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../config/app_config.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/shell_controller.dart';
import '../../core/utils/launcher.dart';
import '../../core/utils/share_helper.dart';
import '../../models/auth/user_model.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/glass_bottom_nav.dart';
import '../../widgets/common/page_scaffold.dart';
import '../../widgets/common/settings_tile.dart';
import '../home/widgets/shell_bottom_nav.dart';
import 'widgets/logout_tile.dart';

/// Profile page (opened from Menu) — account card, account/support/legal settings, logout.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _deleteAccount(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Delete account?', style: AppTextStyles.title),
        content: Text('You will be taken to our website to permanently delete your account and data. This can’t be undone.', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (yes == true) Launcher.url(ApiConfig.deleteAccountUrl);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final top = PageScaffold.topInset(context);

    return PageScaffold(
      title: 'Profile',
      extendBody: true,
      bottomBar: ShellBottomNav(
        selected: ShellTab.menu,
        onTap: (tab) {
          context.read<ShellController>().go(tab);
          context.pop();
        },
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.md, top + AppSpacing.md, AppSpacing.md, GlassBottomNav.totalHeight(context) + AppSpacing.lg),
        children: [
          if (user != null)
            GestureDetector(
              onTap: () => context.push(AppRoutes.editProfile),
              child: _AccountCard(user: user),
            ),
          const SizedBox(height: AppSpacing.lg),
          SettingsGroup(
            title: 'My account',
            children: [
              SettingsTile(icon: Iconsax.user_edit_copy, title: 'Edit profile', subtitle: 'Name, email and address', onTap: () => context.push(AppRoutes.editProfile)),
              SettingsTile(icon: Iconsax.document_text_copy, title: 'My listings', subtitle: 'Properties you posted', color: AppColors.accentViolet, onTap: () => context.push(AppRoutes.myListings)),
              SettingsTile(
                icon: Iconsax.calendar_tick_copy,
                title: 'My inspections',
                subtitle: 'Home inspection bookings',
                color: AppColors.accentBlue,
                onTap: () => context.push(AppRoutes.myInspections),
              ),
              SettingsTile(
                icon: Iconsax.message_text_copy,
                title: 'My consultations',
                subtitle: 'Expert calls you booked',
                color: AppColors.accentAmber,
                onTap: () => context.push(AppRoutes.myConsultations),
              ),
              SettingsTile(
                icon: Iconsax.heart_copy,
                title: 'Saved properties',
                subtitle: 'Your wishlist and enquiries',
                color: AppColors.accentRose,
                onTap: () {
                  // Saved is a shell tab — leave this page, then switch tabs.
                  context.read<ShellController>().go(ShellTab.saved);
                  context.pop();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsGroup(
            title: 'Preferences',
            children: [
              SettingsTile(
                icon: Iconsax.setting_2_copy,
                title: 'Your preferences',
                subtitle: 'Appearance and app behaviour',
                color: AppColors.accentIndigo,
                onTap: () => context.push(AppRoutes.preferences),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsGroup(
            title: 'Support',
            children: [
              SettingsTile(icon: Iconsax.headphone_copy, title: 'Help & support', subtitle: 'Call, WhatsApp or email us', color: AppColors.accentBlue, onTap: () => context.push(AppRoutes.support)),
              SettingsTile(icon: Iconsax.star_1_copy, title: 'Rate Housy Point', subtitle: 'Tell us how we’re doing', color: AppColors.accentAmber, onTap: () => Launcher.url(AppConfig.playStoreUrl)),
              SettingsTile(
                icon: Iconsax.share_copy,
                title: 'Share the app',
                color: AppColors.accentEmerald,
                onTap: () => ShareHelper.share('Find verified homes, book inspections and more on Housy Point: ${AppConfig.playStoreUrl}'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsGroup(
            title: 'Legal',
            children: [
              SettingsTile(icon: Iconsax.shield_tick_copy, title: 'Privacy policy', color: AppColors.textSecondary, onTap: () => Launcher.url(ApiConfig.privacyPolicyUrl)),
              SettingsTile(icon: Iconsax.document_copy, title: 'Terms & conditions', color: AppColors.textSecondary, onTap: () => Launcher.url(ApiConfig.termsUrl)),
              SettingsTile(icon: Iconsax.trash_copy, title: 'Delete account', danger: true, onTap: () => _deleteAccount(context)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const LogoutTile(),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text('Housy Point · v${AppConfig.appVersion.split('+').first}', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});

  final UserModel user;

  String get _initials {
    final parts = [user.firstName, user.lastName].where((p) => p.isNotEmpty);
    final letters = parts.map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? 'HP' : letters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.primaryDark]),
            ),
            child: Text(_initials, style: AppTextStyles.title.copyWith(color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName.isEmpty ? 'Housy Point user' : user.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
                const SizedBox(height: 4),
                _InfoRow(icon: Iconsax.call_copy, text: '+${user.phone}'),
                if (user.email.isNotEmpty) ...[const SizedBox(height: 2), _InfoRow(icon: Iconsax.sms_copy, text: user.email)],
              ],
            ),
          ),
          Icon(Iconsax.edit_2_copy, size: 18, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
        ),
      ],
    );
  }
}
