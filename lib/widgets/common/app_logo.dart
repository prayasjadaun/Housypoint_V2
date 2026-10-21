import 'package:flutter/material.dart';

import '../../theme/app_assets.dart';
import '../../theme/app_colors.dart';

/// The app icon artwork, clipped to its rounded-square shape.
/// Use this everywhere the logo appears in the UI.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40, this.shadow = false});

  final double size;

  /// Soft drop shadow for hero placements (splash, auth header).
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    // Matches the corner curve drawn in the artwork.
    final radius = BorderRadius.circular(size * 0.22);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: size * 0.3,
                  offset: Offset(0, size * 0.1),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        // The artwork has a white margin around its rounded square —
        // zoom past it so only the green tile shows.
        child: SizedBox.square(
          dimension: size,
          child: Transform.scale(
            scale: 1.13,
            child: Image.asset(
              AppAssets.logo,
              fit: BoxFit.cover,
              cacheWidth: (size * 3).round(),
            ),
          ),
        ),
      ),
    );
  }
}

/// [AppLogo] inside a hairline glass frame with a soft shadow and gold glow —
/// for logos sitting on the green brand background (splash, auth header).
class FramedAppLogo extends StatelessWidget {
  const FramedAppLogo({super.key, this.size = 104});

  final double size;

  @override
  Widget build(BuildContext context) {
    final pad = size * 0.06;
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22 + pad),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: size * 0.38,
            offset: Offset(0, size * 0.17),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.10),
            blurRadius: size * 0.58,
            spreadRadius: 6,
          ),
        ],
      ),
      child: AppLogo(size: size),
    );
  }
}
