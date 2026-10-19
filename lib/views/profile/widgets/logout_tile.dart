import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/referral_controller.dart';
import '../../../controllers/saved_controller.dart';
import '../../../controllers/shell_controller.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// "Log out" row with a confirmation dialog.
class LogoutTile extends StatelessWidget {
  const LogoutTile({super.key});

  Future<void> _confirm(BuildContext context) async {
    AppHaptics.tap();
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Text('Log out?', style: AppTextStyles.title),
        content: Text(
          'You will need your mobile number and an OTP to log back in.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
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
      context.read<SavedController>().clear();
      context.read<ReferralController>().clear();
      context.read<ShellController>().reset();
      await context.read<AuthController>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => _confirm(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                ),
                child: const Icon(
                  Iconsax.logout_copy,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Log out',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Iconsax.arrow_right_3_copy,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
