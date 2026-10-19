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
  });

  final String title;
  final String message;
  final IconData? icon;
  final String? lottie;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
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
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
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
