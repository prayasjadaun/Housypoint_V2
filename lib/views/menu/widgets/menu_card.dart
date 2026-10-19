import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_text_styles.dart';

/// Menu grid card (Inlobo style): white → tint gradient, a large faded
/// Iconsax line icon in the corner and an "open" arrow badge.
class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl);
    final tint = Color.alphaBlend(color.withValues(alpha: 0.10), AppColors.surface);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          AppHaptics.success();
          onTap();
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.surface, tint],
            ),
            border: Border.all(color: color.withValues(alpha: 0.08)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 12,
                bottom: 10,
                child: Icon(icon, size: 52, color: color.withValues(alpha: 0.55)),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Icon(Iconsax.arrow_right_3_copy, size: 14, color: color),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 44, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      style: AppTextStyles.caption.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
