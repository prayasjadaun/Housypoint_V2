import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Animated city skyline for the home hero — V2's take on V1's
/// "buildings floating" GIF, drawn in code so it's crisp and on-brand.
///
/// Buildings rise from the ground one after another, then the skyline
/// floats gently while windows twinkle gold, clouds drift and the sun glows.
class SkylineAnimation extends StatefulWidget {
  const SkylineAnimation({super.key});

  @override
  State<SkylineAnimation> createState() => _SkylineAnimationState();
}

class _SkylineAnimationState extends State<SkylineAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _SkylinePainter(intro: _intro, loop: _loop),
      ),
    );
  }
}

class _Building {
  const _Building({
    required this.left,
    required this.width,
    required this.height,
    required this.delay,
    this.spire = false,
    this.windowSeed = 0,
  });

  final double left; // fraction of canvas width
  final double width; // fraction of canvas width
  final double height; // fraction of canvas height
  final double delay; // 0..1 start within the intro
  final bool spire;
  final int windowSeed;
}

class _SkylinePainter extends CustomPainter {
  _SkylinePainter({required this.intro, required this.loop})
    : super(repaint: Listenable.merge([intro, loop]));

  final Animation<double> intro;
  final Animation<double> loop;

  // Hand-tuned so the silhouette reads as a skyline at any width.
  static const _back = [
    _Building(left: 0.00, width: 0.10, height: 0.46, delay: 0.00),
    _Building(left: 0.09, width: 0.08, height: 0.62, delay: 0.05),
    _Building(left: 0.20, width: 0.11, height: 0.52, delay: 0.10),
    _Building(left: 0.34, width: 0.07, height: 0.70, delay: 0.12),
    _Building(left: 0.45, width: 0.12, height: 0.48, delay: 0.16),
    _Building(left: 0.60, width: 0.08, height: 0.66, delay: 0.20),
    _Building(left: 0.71, width: 0.10, height: 0.56, delay: 0.22),
    _Building(left: 0.84, width: 0.09, height: 0.72, delay: 0.26),
    _Building(left: 0.93, width: 0.08, height: 0.50, delay: 0.28),
  ];

  static const _front = [
    _Building(left: 0.03, width: 0.12, height: 0.38, delay: 0.18, windowSeed: 1),
    _Building(left: 0.14, width: 0.09, height: 0.58, delay: 0.24, windowSeed: 2),
    _Building(left: 0.25, width: 0.13, height: 0.44, delay: 0.30, windowSeed: 3),
    _Building(left: 0.40, width: 0.10, height: 0.86, delay: 0.36, spire: true, windowSeed: 4),
    _Building(left: 0.52, width: 0.12, height: 0.54, delay: 0.40, windowSeed: 5),
    _Building(left: 0.66, width: 0.09, height: 0.68, delay: 0.44, windowSeed: 6),
    _Building(left: 0.77, width: 0.12, height: 0.42, delay: 0.48, windowSeed: 7),
    _Building(left: 0.90, width: 0.10, height: 0.60, delay: 0.52, windowSeed: 8),
  ];

  /// 0 → 1 rise for one building, with a soft overshoot.
  double _rise(double delay) {
    final t = ((intro.value - delay) / 0.45).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final phase = loop.value * 2 * math.pi;
    final fadeIn = Curves.easeOut.transform(intro.value.clamp(0.0, 1.0));

    _paintSun(canvas, Offset(w * 0.84, h * 0.22), fadeIn, phase);
    _paintClouds(canvas, size, fadeIn);

    final ground = h - 1;

    // Back layer — faint, slower float (parallax)
    canvas.save();
    canvas.translate(0, math.sin(phase + 1.2) * 1.5);
    final backPaint = Paint()..color = Colors.white.withValues(alpha: 0.07);
    for (final b in _back) {
      final rise = _rise(b.delay);
      if (rise <= 0) continue;
      final top = ground - b.height * h * rise;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(b.left * w, top, (b.left + b.width) * w, ground),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        backPaint,
      );
    }
    canvas.restore();

    // Front layer — brighter, floats a little more, with windows
    canvas.save();
    canvas.translate(0, math.sin(phase) * 2.5);
    for (final b in _front) {
      final rise = _rise(b.delay);
      if (rise <= 0) continue;
      _paintFrontBuilding(canvas, b, w, h, ground, rise, phase);
    }
    canvas.restore();

    // Ground line
    canvas.drawLine(
      Offset(0, ground),
      Offset(w, ground),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18 * fadeIn)
        ..strokeWidth = 1,
    );
  }

  void _paintFrontBuilding(
    Canvas canvas,
    _Building b,
    double w,
    double h,
    double ground,
    double rise,
    double phase,
  ) {
    final left = b.left * w;
    final right = (b.left + b.width) * w;
    final top = ground - b.height * h * rise;
    final rect = Rect.fromLTRB(left, top, right, ground);

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.20),
            Colors.white.withValues(alpha: 0.10),
          ],
        ).createShader(rect),
    );

    if (b.spire) {
      final cx = (left + right) / 2;
      final spirePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx, top), Offset(cx, top - 14 * rise), spirePaint);
      // Blinking aviation light
      final blink = (math.sin(phase * 6) + 1) / 2;
      canvas.drawCircle(
        Offset(cx, top - 15 * rise),
        2,
        Paint()..color = AppColors.gold.withValues(alpha: 0.4 + 0.6 * blink),
      );
    }

    // Windows appear once the building has (almost) finished rising
    final windowsAlpha = ((rise - 0.85) / 0.15).clamp(0.0, 1.0);
    if (windowsAlpha <= 0) return;

    const cell = 7.0;
    const gap = 5.0;
    final cols = ((rect.width - gap) / (cell + gap)).floor();
    final rows = ((rect.height - gap * 2) / (cell + gap)).floor();
    if (cols <= 0 || rows <= 0) return;
    final offsetX = (rect.width - (cols * (cell + gap) - gap)) / 2;

    final random = math.Random(b.windowSeed);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final lit = random.nextDouble() < 0.42;
        final seed = random.nextDouble() * 2 * math.pi;
        final twinkle = lit ? 0.55 + 0.45 * math.sin(phase * 3 + seed) : 0.0;
        final color = lit
            ? AppColors.gold.withValues(alpha: (0.25 + 0.55 * twinkle) * windowsAlpha)
            : Colors.white.withValues(alpha: 0.10 * windowsAlpha);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              rect.left + offsetX + c * (cell + gap),
              rect.top + gap * 1.6 + r * (cell + gap),
              cell,
              cell,
            ),
            const Radius.circular(1.5),
          ),
          Paint()..color = color,
        );
      }
    }
  }

  void _paintSun(Canvas canvas, Offset center, double fadeIn, double phase) {
    final pulse = 1 + math.sin(phase * 2) * 0.06;
    canvas.drawCircle(
      center,
      46 * pulse,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.30 * fadeIn),
            AppColors.gold.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 46 * pulse)),
    );
    canvas.drawCircle(
      center,
      15,
      Paint()..color = AppColors.gold.withValues(alpha: 0.85 * fadeIn),
    );
  }

  void _paintClouds(Canvas canvas, Size size, double fadeIn) {
    // Shapes are drawn opaque inside one translucent layer, so where the
    // puffs overlap the cloud stays one even tone.
    final layer = Paint()..color = Colors.white.withValues(alpha: 0.10 * fadeIn);
    final paint = Paint()..color = Colors.white;
    const span = 160.0;
    for (final (y, speed, offset, scale) in const [
      (0.16, 1.0, 0.1, 1.0),
      (0.36, 0.6, 0.6, 0.75),
    ]) {
      final travel = size.width + span;
      final x = (loop.value * speed * travel + offset * travel) % travel - span / 2;
      canvas.saveLayer(null, layer);
      _cloud(canvas, Offset(x, size.height * y), scale, paint);
      canvas.restore();
    }
  }

  void _cloud(Canvas canvas, Offset o, double s, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx - 30 * s, o.dy, 60 * s, 14 * s),
        Radius.circular(7 * s),
      ),
      paint,
    );
    canvas.drawCircle(Offset(o.dx - 8 * s, o.dy + 2 * s), 10 * s, paint);
    canvas.drawCircle(Offset(o.dx + 10 * s, o.dy + 4 * s), 8 * s, paint);
  }

  @override
  bool shouldRepaint(_SkylinePainter oldDelegate) => false;
}
