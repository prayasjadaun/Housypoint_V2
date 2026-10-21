import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/section_header.dart';

/// Sell / Rent out / Buy entry points — "0% brokerage" (V1 AddPropertySection).
class PostPropertySection extends StatelessWidget {
  const PostPropertySection({super.key, required this.onSelect});

  /// `sell`, `rent` or `buy`.
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Post your property',
          subtitle: 'Zero brokerage — reach verified buyers and tenants',
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _PostCard(
                      icon: Iconsax.key_copy,
                      title: 'Sell',
                      subtitle: 'Get the best price',
                      color: AppColors.primary,
                      onTap: () => onSelect('sell'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PostCard(
                      icon: Iconsax.home_hashtag_copy,
                      title: 'Rent out',
                      subtitle: 'Find good tenants',
                      color: AppColors.accentSky,
                      onTap: () => onSelect('rent'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _BuyBanner(onTap: () => onSelect('buy')),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.surface, Color.alphaBlend(color.withValues(alpha: 0.1), AppColors.surface)],
            ),
            border: Border.all(color: color.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon, size: 19, color: color),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '0% fee',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10.5,
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(title, style: AppTextStyles.title.copyWith(fontSize: 16)),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyBanner extends StatelessWidget {
  const _BuyBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl);
    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Iconsax.search_status_copy, size: 19, color: AppColors.goldDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Looking to buy?',
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Tell us what you need — we’ll find matching homes',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Icon(Iconsax.arrow_right_3_copy, size: 18, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
