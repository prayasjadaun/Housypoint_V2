import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Centered illustration + message (+ optional action) for empty or
/// failed lists. Pass [lottie] for an animation, otherwise [icon] is shown.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.lottie,
    this.actionLabel,
    this.onAction,
    this.goldStyle = false,
  });

  final String title;
  final String message;
  final IconData? icon;
  final String? lottie;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Ink text and a gold badge, for the black Refer tab.
  final bool goldStyle;

  @override
  Widget build(BuildContext context) {
    final accent = goldStyle ? AppColors.referGold : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lottie != null)
            Lottie.asset(lottie!, height: 150, repeat: true)
          else if (icon != null)
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: goldStyle ? AppColors.referDarkRaised : AppColors.primarySoft,
                shape: BoxShape.circle,
                border: goldStyle ? Border.all(color: AppColors.referRule) : null,
              ),
              child: Icon(icon, size: 32, color: accent),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTextStyles.title.copyWith(color: goldStyle ? AppColors.referInk : null),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: goldStyle ? AppColors.referMuted : AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
