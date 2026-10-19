import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'app_refresh_indicator.dart';

/// Heading used at the top of every step.
class StepHeading extends StatelessWidget {
  const StepHeading({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading.copyWith(fontSize: 21)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Tappable field that opens a picker (looks like a text field).
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final String? value;
  final String placeholder;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final has = value != null && value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        Material(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: loading ? null : onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: has ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border, width: 1.2),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: has ? AppColors.primary : AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      has ? value! : placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 15,
                        fontWeight: has ? FontWeight.w500 : FontWeight.w400,
                        color: has ? AppColors.textPrimary : AppColors.textTertiary,
                      ),
                    ),
                  ),
                  if (loading)
                    const AppSpinner(size: 16)
                  else
                    const Icon(Iconsax.arrow_down_1_copy, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Checkbox + label row, e.g. "My builder isn’t listed".
class CheckRow extends StatelessWidget {
  const CheckRow({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 22,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
            ),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

