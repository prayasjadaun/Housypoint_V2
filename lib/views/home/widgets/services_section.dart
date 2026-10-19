import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/section_header.dart';

/// "Our expertise" — the four consultation services from V1.
class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key, required this.onSelect});

  /// Called with the service key: inspection, loan, legal, tax.
  final ValueChanged<String> onSelect;

  static const _services = [
    ('inspection', 'Home\nInspection', Iconsax.shield_tick_copy, AppColors.primary),
    ('loan', 'Home\nLoan', Iconsax.money_recive_copy, AppColors.accentEmerald),
    ('legal', 'Legal\nAdvice', Iconsax.judge_copy, AppColors.accentIndigo),
    ('tax', 'Tax\nPlanning', Iconsax.receipt_2_copy, AppColors.accentAmber),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Our expertise',
          subtitle: 'Talk to an expert before you decide',
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              for (var i = 0; i < _services.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: _ServiceTile(data: _services[i], onTap: onSelect)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.data, required this.onTap});

  final (String, String, IconData, Color) data;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final (key, label, icon, color) = data;
    final radius = BorderRadius.circular(AppRadius.lg);

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          AppHaptics.tap();
          onTap(key);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 21, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
