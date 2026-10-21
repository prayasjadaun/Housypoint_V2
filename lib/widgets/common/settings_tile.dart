import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/utils/app_haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

/// White rounded card holding [SettingsTile]s with hairline dividers.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Text(
              title!.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, indent: 64, color: AppColors.border),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Icon box + title/subtitle + chevron row.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color = AppColors.primary,
    this.danger = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color color;
  final bool danger;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tint = danger ? AppColors.error : color;
    return InkWell(
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm + 2),
              ),
              child: Icon(icon, size: 19, color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: danger ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) Text(subtitle!, style: AppTextStyles.caption),
                ],
              ),
            ),
            trailing ??
                Icon(Iconsax.arrow_right_3_copy, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
