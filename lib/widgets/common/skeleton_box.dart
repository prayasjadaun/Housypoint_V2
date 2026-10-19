import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Gently pulsing placeholder block shown while content loads.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 6,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulse,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
