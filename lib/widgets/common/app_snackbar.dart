import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

enum AppSnackBarType { success, error, info }

/// The app's snackbar look — a floating dark pill with a status icon.
class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
  }) {
    final (color, icon) = switch (type) {
      AppSnackBarType.success => (AppColors.success, Iconsax.tick_circle_copy),
      AppSnackBarType.error => (AppColors.error, Iconsax.warning_2_copy),
      AppSnackBarType.info => (AppColors.gold, Iconsax.info_circle_copy),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.all(AppSpacing.md),
          duration: const Duration(seconds: 3),
          // Floating snackbar Scaffold ke bottomNavigationBar se upar hi
          // baithta hai, par iOS 26 ka native tab bar us slot me nahi hota —
          // wo sirf MediaQuery ki bottom padding me aata hai. Scaffold yeh
          // padding tabhi chhodta hai jab bottomNavigationBar na ho, isliye
          // ise jodne se snackbar har case me bar / home indicator ke upar rehta hai.
          content: Builder(
            builder: (ctx) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(ctx).bottom,
              ),
              child: _pill(message, color, icon),
            ),
          ),
        ),
      );
  }

  static Widget _pill(String message, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14,
    ),
    decoration: BoxDecoration(
      color: AppColors.ink.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(AppRadius.md),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
