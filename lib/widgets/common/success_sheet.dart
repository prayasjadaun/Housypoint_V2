import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../theme/app_assets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'app_button.dart';

/// Celebratory confirmation after a booking / submission.
Future<void> showSuccessSheet(
  BuildContext context, {
  required String title,
  required String message,
  String buttonLabel = 'Done',
}) {
  return showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.paddingOf(sheetContext).bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Lottie.asset(AppAssets.lottieConfetti, repeat: false),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 40, color: AppColors.primary),
                ),
              ],
            ),
          ),
          Text(title, style: AppTextStyles.heading.copyWith(fontSize: 20), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: buttonLabel, onPressed: () => Navigator.pop(sheetContext)),
        ],
      ),
    ),
  );
}
