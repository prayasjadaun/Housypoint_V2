import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// A small floating label around the hero icon, e.g. "Verified listings".
class OnboardingChip {
  const OnboardingChip(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// Hero art for one onboarding page: soft green halo, a white tile with a
/// large line icon, and three chips gently floating around it.
class OnboardingIllustration extends StatefulWidget {
  const OnboardingIllustration({
    super.key,
    required this.icon,
    required this.chips,
  });

  final IconData icon;

  /// Exactly three — placed top-left, right and bottom-left.
  final List<OnboardingChip> chips;

  @override
  State<OnboardingIllustration> createState() => _OnboardingIllustrationState();
}

class _OnboardingIllustrationState extends State<OnboardingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);

        return Center(
          child: SizedBox.square(
            dimension: size,
            child: AnimatedBuilder(
              animation: _float,
              builder: (context, _) {
                // Each chip bobs on its own phase so they never move in sync.
                double bob(double phase) =>
                    math.sin((_float.value + phase) * 2 * math.pi) * 6;

                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    _halo(size),
                    _heroTile(size * 0.36),
                    Positioned(
                      left: 0,
                      top: size * 0.16 + bob(0),
                      child: _chip(widget.chips[0]),
                    ),
                    Positioned(
                      right: 0,
                      top: size * 0.46 + bob(0.33),
                      child: _chip(widget.chips[1]),
                    ),
                    Positioned(
                      left: size * 0.06,
                      bottom: size * 0.12 + bob(0.66),
                      child: _chip(widget.chips[2]),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _halo(double size) {
    return Container(
      width: size * 0.86,
      height: size * 0.86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primarySoft,
            AppColors.primarySoft.withValues(alpha: 0.0),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.62,
        height: size * 0.62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.12),
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _heroTile(double tile) {
    return Container(
      width: tile,
      height: tile,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(tile * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Icon(widget.icon, size: tile * 0.46, color: AppColors.primary),
    );
  }

  Widget _chip(OnboardingChip chip) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(chip.icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Text(
            chip.label,
            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
