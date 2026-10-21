import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/theme_controller.dart';
import '../../core/utils/app_haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/page_scaffold.dart';
import '../../widgets/common/settings_tile.dart';
import '../../widgets/common/theme_switch_overlay.dart';

/// App-wide preferences (opened from Profile). Currently just Appearance,
/// laid out as a settings group so more tiles can join it later.
class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  static String _themeName(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'System',
  };

  static IconData _themeIcon(ThemeMode mode) => switch (mode) {
    ThemeMode.light => Iconsax.sun_1_copy,
    ThemeMode.dark => Iconsax.moon_copy,
    ThemeMode.system => Iconsax.mobile_copy,
  };

  void _showAppearanceSheet(BuildContext pageContext) {
    final themeController = pageContext.read<ThemeController>();

    late final Future<void> sheetClosed;
    sheetClosed = showModalBottomSheet<void>(
      context: pageContext,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final current = themeController.mode;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Appearance', style: AppTextStyles.title),
                      const SizedBox(height: 2),
                      Text('Choose how Housy Point looks on this device', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                  child: SettingsGroup(
                    children: [
                      for (final mode in ThemeMode.values)
                        _ThemeOptionRow(
                          icon: _themeIcon(mode),
                          label: _themeName(mode),
                          selected: mode == current,
                          onTapUp: (details) async {
                            if (mode == current) return;
                            AppHaptics.tap();
                            final tapPosition = details.globalPosition;

                            // Wait for the sheet's exit animation to fully
                            // finish before snapshotting the page — the
                            // sheet future resolves on pop, while the sheet
                            // is still painted, which would bake it into the
                            // reveal overlay.
                            final routeAnimation = ModalRoute.of(sheetCtx)?.animation;
                            Navigator.of(sheetCtx).pop();

                            if (routeAnimation != null && routeAnimation.status != AnimationStatus.dismissed) {
                              final dismissed = Completer<void>();
                              void listener(AnimationStatus status) {
                                if (status == AnimationStatus.dismissed) {
                                  routeAnimation.removeStatusListener(listener);
                                  if (!dismissed.isCompleted) dismissed.complete();
                                }
                              }

                              routeAnimation.addStatusListener(listener);
                              await dismissed.future;
                            } else {
                              await sheetClosed;
                            }
                            if (!pageContext.mounted) return;

                            await ThemeSwitchOverlay.animate(
                              pageContext,
                              tapPosition: tapPosition,
                              onThemeChange: () => themeController.setThemeMode(mode),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeController>().mode;
    final top = PageScaffold.topInset(context);

    return PageScaffold(
      title: 'Preferences',
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.md, top + AppSpacing.md, AppSpacing.md, AppSpacing.lg),
        children: [
          SettingsGroup(
            title: 'Display',
            children: [
              SettingsTile(
                icon: _themeIcon(themeMode),
                title: 'Appearance',
                subtitle: 'Light, dark, or match system',
                onTap: () => _showAppearanceSheet(context),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _themeName(themeMode),
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Icon(Iconsax.arrow_right_3_copy, size: 18, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionRow extends StatelessWidget {
  const _ThemeOptionRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTapUp,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final ValueChanged<TapUpDetails> onTapUp;

  @override
  Widget build(BuildContext context) {
    final tint = selected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTapUp: onTapUp,
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: tint),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textTertiary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
