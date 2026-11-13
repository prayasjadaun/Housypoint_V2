import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lottie/lottie.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../theme/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_text_styles.dart';

/// Refer & Earn — Refer tab ki gold theme. Dark mode me Refer screen jaisa
/// black + gold card; light mode me halka cream card, gold accents wahi.
class ReferBanner extends StatelessWidget {
  const ReferBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    // Light: white par gold ka halka sa wash
    final lightTop = Color.alphaBlend(
      AppColors.referGold.withValues(alpha: 0.06),
      AppColors.surface,
    );
    final lightBottom = Color.alphaBlend(
      AppColors.referGold.withValues(alpha: 0.16),
      AppColors.surface,
    );
    final eyebrow = dark ? AppColors.referGold : AppColors.goldDark;
    final titleColor = dark ? AppColors.referInk : AppColors.textPrimary;
    final bodyColor = dark ? AppColors.referMuted : AppColors.textSecondary;

    return _BannerShell(
      onTap: onTap,
      gradient: dark
          ? const [AppColors.referDarkRaised, AppColors.referDark]
          : [lightTop, lightBottom],
      borderColor: AppColors.referRule,
      boxShadow: [
        BoxShadow(
          color: dark
              ? Colors.black.withValues(alpha: 0.28)
              : AppColors.referGold.withValues(alpha: 0.14),
          blurRadius: dark ? 24 : 16,
          offset: Offset(0, dark ? 10 : 6),
        ),
      ],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.crown_1_copy, size: 13, color: eyebrow),
                    const SizedBox(width: 5),
                    _Eyebrow(text: 'REFER & EARN', color: eyebrow),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Invite friends,\nearn on every deal',
                  style: AppTextStyles.title.copyWith(
                    color: titleColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rewards when they buy, sell or book an inspection.',
                  style: AppTextStyles.caption.copyWith(
                    color: bodyColor,
                  ),
                ),
                const SizedBox(height: 14),
                const _CtaPill(
                  label: 'Start earning',
                  gradient: AppColors.referGoldGradient,
                  textColor: AppColors.referOnGold,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Gift ke peeche halka gold glow
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.referGold.withValues(alpha: 0.22),
                  AppColors.referGold.withValues(alpha: 0),
                ],
              ),
            ),
            child: Lottie.asset(AppAssets.lottieGift, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}

/// Home inspection (PDI) — clean white card (dark mode: surface); green
/// sirf ticks aur icon me. Neeche plans strip se ek ticket ki tarah judta hai.
class InspectionBanner extends StatelessWidget {
  const InspectionBanner({
    super.key,
    required this.onTap,
    this.attached = false,
  });

  final VoidCallback onTap;

  /// Square bottom corners, for the plan panel joined underneath.
  final bool attached;

  static const _points = [
    'Civil & finishing',
    'Plumbing & electrical',
    'Detailed report',
  ];

  @override
  Widget build(BuildContext context) {
    return _BannerShell(
      onTap: onTap,
      squareBottom: attached,
      gradient: [AppColors.surface, AppColors.surface],
      // Plans strip jaisi hi soft shadow, taaki dono ek card lagein
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F0B3B20),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Eyebrow(
                  text: 'HOME INSPECTION',
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 6),
                Text(
                  'We check what\nbuilders miss',
                  style: AppTextStyles.title.copyWith(height: 1.3),
                ),
                const SizedBox(height: 10),
                for (final p in _points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.tick_circle,
                          size: 15,
                          color: AppColors.primaryText,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          p,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                _CtaPill(
                  label: 'Book inspection',
                  color: AppColors.textPrimary,
                  textColor: AppColors.surface,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySoft,
            ),
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140B3B20),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Iconsax.shield_tick,
                  size: 30,
                  color: AppColors.primaryText,
                ),
              ),
            ),
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

  /// Neutral — black on light, white on dark (no brand colour here).
  static Color get accent => AppColors.textPrimary;

  @override
  Widget build(BuildContext context) {
    return _BannerShell(
      onTap: onTap,
      // Plain white card (dark mode: surface) with a hairline border
      gradient: [AppColors.surface, AppColors.surface],
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(text: 'PROJECT COMPARISON', color: AppColors.textSecondary),
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
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'VS',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Iconsax.buildings_2_copy, size: 18, color: CompareBanner.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Icon(Iconsax.add_copy, size: 16, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _BannerShell extends StatelessWidget {
  const _BannerShell({
    required this.onTap,
    required this.gradient,
    required this.child,
    this.squareBottom = false,
    this.borderColor,
    this.boxShadow,
  });

  final VoidCallback onTap;
  final List<Color> gradient;
  final Widget child;
  final bool squareBottom;

  /// Optional hairline border (for light/plain cards).
  final Color? borderColor;

  /// Optional drop shadow.
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    const corner = Radius.circular(AppRadius.xl + 4);
    final radius = squareBottom
        ? const BorderRadius.vertical(top: corner)
        : const BorderRadius.all(corner);
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
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!),
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
  const _CtaPill({
    required this.label,
    this.color,
    this.gradient,
    this.textColor = Colors.white,
  });

  final String label;
  final Color? color;
  final Gradient? gradient;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Iconsax.arrow_right_3_copy, size: 14, color: textColor),
        ],
      ),
    );
  }
}
