import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lottie/lottie.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../theme/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_text_styles.dart';

/// Refer & Earn — gold card with the gift animation.
class ReferBanner extends StatelessWidget {
  const ReferBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BannerShell(
      onTap: onTap,
      gradient: const [Color(0xFFFFF6E3), Color(0xFFF6DFA9)],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Eyebrow(text: 'REFER & EARN', color: AppColors.goldDark),
                const SizedBox(height: 6),
                Text(
                  'Invite friends,\nearn on every deal',
                  style: AppTextStyles.title.copyWith(height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rewards when they buy, sell or book an inspection.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.65)),
                ),
                const SizedBox(height: 12),
                const _CtaPill(label: 'Start earning', color: AppColors.textPrimary),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            height: 110,
            child: Lottie.asset(AppAssets.lottieGift, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}

/// Home inspection (PDI) — dark green card.
class InspectionBanner extends StatelessWidget {
  const InspectionBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  static const _points = ['Civil & finishing', 'Plumbing & electrical', 'Detailed report'];

  @override
  Widget build(BuildContext context) {
    return _BannerShell(
      onTap: onTap,
      gradient: const [AppColors.primary, AppColors.primaryDark],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Eyebrow(text: 'HOME INSPECTION', color: AppColors.gold),
                const SizedBox(height: 6),
                Text(
                  'We check what\nbuilders miss',
                  style: AppTextStyles.title.copyWith(color: Colors.white, height: 1.3),
                ),
                const SizedBox(height: 10),
                for (final p in _points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Iconsax.tick_circle_copy, size: 14, color: AppColors.gold),
                        const SizedBox(width: 6),
                        Text(
                          p,
                          style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                const _CtaPill(label: 'Book inspection', color: AppColors.gold, textColor: AppColors.textPrimary),
              ],
            ),
          ),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: const Icon(Iconsax.shield_tick_copy, size: 44, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Compare projects — two project tiles with a VS badge.
class CompareBanner extends StatelessWidget {
  const CompareBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BannerShell(
      onTap: onTap,
      gradient: const [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow(text: 'PROJECT COMPARISON', color: AppColors.accentIndigo),
          const SizedBox(height: 6),
          Text('Compare & pick the right home', style: AppTextStyles.title),
          Text(
            'Price, size, amenities and location — side by side.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: _CompareSlot(label: 'Project A')),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.accentIndigo,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'VS',
                  style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const Expanded(child: _CompareSlot(label: 'Project B')),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompareSlot extends StatelessWidget {
  const _CompareSlot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.buildings_2_copy, size: 18, color: AppColors.accentIndigo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
          ),
          const Icon(Iconsax.add_copy, size: 16, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _BannerShell extends StatelessWidget {
  const _BannerShell({required this.onTap, required this.gradient, required this.child});

  final VoidCallback onTap;
  final List<Color> gradient;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl + 4);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _CtaPill extends StatelessWidget {
  const _CtaPill({required this.label, required this.color, this.textColor = Colors.white});

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: textColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          Icon(Iconsax.arrow_right_3_copy, size: 14, color: textColor),
        ],
      ),
    );
  }
}
