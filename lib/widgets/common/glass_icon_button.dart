import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Round frosted button for use on top of photos (back, save, share).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.background,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  /// Solid fill instead of glass, e.g. red when a listing is saved.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: background ?? Colors.black.withValues(alpha: 0.25),
          shape: CircleBorder(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 40,
              child: Icon(icon, size: 19, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
