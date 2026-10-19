import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Pull-to-refresh used on every list in the app (same as Inlobo).
/// Native look on each platform — Cupertino spinner on iOS, brand-green
/// Material ring on Android.
///
/// Under a glass app bar pass `edgeOffset: MediaQuery.paddingOf(context).top`
/// so the indicator appears below the bar instead of behind it.
class RefreshIndicatorWrapper extends StatelessWidget {
  const RefreshIndicatorWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.edgeOffset = 0,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final double edgeOffset;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      backgroundColor: AppColors.surface,
      color: AppColors.primary,
      strokeWidth: 2.5,
      displacement: 50,
      edgeOffset: edgeOffset,
      child: child,
    );
  }
}

/// Brand loading spinner: a green 3/4 arc turning on a faint track.
/// Use it for page / section loading instead of CircularProgressIndicator.
class AppSpinner extends StatefulWidget {
  const AppSpinner({super.key, this.size = 28});

  final double size;

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 1200),
    vsync: this,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: CustomPaint(painter: _SpinnerPainter(_controller)),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final stroke = size.width / 9;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.15)
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + progress.value * 2 * math.pi,
      math.pi * 1.5, // 3/4 of a circle
      false,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) => false;
}
