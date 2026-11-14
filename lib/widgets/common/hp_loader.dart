import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// HousyPoint brand loader: a house outline (roof + walls) with a glowing
/// comet tracing round its edge, "HP" breathing inside the walls with a
/// shine sweeping across, and a gold chimney puffing a little smoke.
///
/// Trial par — abhi sirf Compare screen me. Pasand aaye to [AppSpinner]
/// (app_refresh_indicator.dart) ki jagah baaki screens me lagao.
///
/// Below [_lettersMinSize] the letters can't be read, so small inline
/// loaders show only the tracing house.
class HpLoader extends StatefulWidget {
  const HpLoader({super.key, this.size = 44, this.color});

  final double size;

  /// Defaults to the brand green (brighter on dark). Pass one for special
  /// backgrounds — gold on Refer, white on video.
  final Color? color;

  static const double _lettersMinSize = 26;
  static const double _chimneyMinSize = 36;

  @override
  State<HpLoader> createState() => _HpLoaderState();
}

class _HpLoaderState extends State<HpLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 1600),
    vsync: this,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final custom = widget.color;
    final color =
        custom ?? (AppColors.isDark ? AppColors.mainGreen : AppColors.primary);
    return Semantics(
      label: 'Loading',
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(
            painter: _HpLoaderPainter(
              progress: _controller,
              color: color,
              // Default look par chimney gold; custom color par sab ek rang
              accent: custom ?? AppColors.gold,
              fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
              showLetters: widget.size >= HpLoader._lettersMinSize,
              showChimney: widget.size >= HpLoader._chimneyMinSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _HpLoaderPainter extends CustomPainter {
  _HpLoaderPainter({
    required this.progress,
    required this.color,
    required this.accent,
    required this.fontFamily,
    required this.showLetters,
    required this.showChimney,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final Color accent;
  final String? fontFamily;
  final bool showLetters;
  final bool showChimney;

  // Ghar ka shape, 0..1 box me. Neeche-beech se shuru, clockwise
  // (screen par: right wall upar, chhat, left wall neeche).
  static const _peak = Offset(0.5, 0.12);
  static const _eaveY = 0.46;
  static const _left = 0.14;
  static const _right = 0.86;
  static const _base = 0.9;

  /// Chhat ki line par x ke liye y (right slope)
  static double _roofY(double x) =>
      _peak.dy + (x - _peak.dx) / (_right - _peak.dx) * (_eaveY - _peak.dy);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final s = size.width;
    final stroke = math.max(1.6, s * 0.055);
    Offset p(double x, double y) => Offset(x * s, y * s);

    final house = _roundedPolygon([
      p(0.5, _base),
      p(_right, _base),
      p(_right, _eaveY),
      p(_peak.dx, _peak.dy),
      p(_left, _eaveY),
      p(_left, _base),
    ], s * 0.06);

    final line = Paint()
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (showChimney) _paintChimney(canvas, s, stroke, t, p);

    // Faint track
    canvas.drawPath(house, line..color = color.withValues(alpha: 0.14));

    // Comet — kinaare par ghoomti line, poonch fade hoti hai
    final metric = house.computeMetrics().first;
    final total = metric.length;
    final head = t * total;
    final tail = total * 0.38;
    const pieces = 10;
    for (var i = 0; i < pieces; i++) {
      final a = head - tail + tail * i / pieces;
      final b = head - tail + tail * (i + 1) / pieces;
      final alpha = (i + 1) / pieces;
      canvas.drawPath(
        _extractWrapped(metric, a, b),
        line..color = color.withValues(alpha: alpha),
      );
    }
    final tip = metric.getTangentForOffset(head % total)?.position;
    if (tip != null) {
      // Head par halka glow
      canvas.drawCircle(
        tip,
        stroke * 1.4,
        Paint()..color = color.withValues(alpha: 0.18),
      );
      canvas.drawCircle(tip, stroke * 0.62, Paint()..color = color);
    }

    if (showLetters) _paintLetters(canvas, s, t);
  }

  void _paintChimney(
    Canvas canvas,
    double s,
    double stroke,
    double t,
    Offset Function(double, double) p,
  ) {
    const x0 = 0.64, x1 = 0.73, top = 0.17;
    canvas.drawPath(
      Path()
        ..moveTo(x0 * s, _roofY(x0) * s)
        ..lineTo(x0 * s, top * s)
        ..lineTo(x1 * s, top * s)
        ..lineTo(x1 * s, _roofY(x1) * s),
      Paint()
        ..color = accent
        ..strokeWidth = stroke * 0.9
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Do puff, aadhe cycle ke gap par — upar uthte, bade hote, fade hote
    for (final phase in [0.0, 0.5]) {
      final k = (t + phase) % 1.0;
      final center = p(
        (x0 + x1) / 2 + 0.04 * math.sin(k * math.pi),
        top - 0.03 - 0.12 * k,
      );
      canvas.drawCircle(
        center,
        s * (0.022 + 0.03 * k),
        Paint()..color = accent.withValues(alpha: 0.55 * (1 - k)),
      );
    }
  }

  void _paintLetters(Canvas canvas, double s, double t) {
    // Deewaron ke beech — chhat ke neeche wala hissa
    final center = Offset(0.5 * s, ((_eaveY + _base) / 2 + 0.01) * s);

    // Halki saans — letters 92%↔100%
    final pulse = 0.92 + 0.08 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pulse);
    canvas.translate(-center.dx, -center.dy);

    final fontSize = s * 0.27;
    final style = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -fontSize * 0.04,
      height: 1,
    );
    final measure = TextPainter(
      text: TextSpan(text: 'HP', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = Offset(
      center.dx - measure.width / 2,
      center.dy - measure.height / 2,
    );

    // Shine — roshni ki patli patti letters par left→right
    final shine = Color.lerp(color, Colors.white, 0.6)!;
    final pos = -0.4 + t * 1.8;
    TextPainter(
        text: TextSpan(
          text: 'HP',
          style: style.copyWith(
            foreground: Paint()
              ..shader = LinearGradient(
                colors: [color, shine, color],
                stops: [
                  (pos - 0.18).clamp(0.0, 1.0),
                  pos.clamp(0.0, 1.0),
                  (pos + 0.18).clamp(0.0, 1.0),
                ],
              ).createShader(offset & measure.size),
          ),
        ),
        textDirection: TextDirection.ltr,
      )
      ..layout()
      ..paint(canvas, offset);
    canvas.restore();
  }

  /// Path ka [a, b] hissa; 0 se peeche gaya to end se wrap karke
  static Path _extractWrapped(PathMetric m, double a, double b) {
    final l = m.length;
    a %= l;
    b %= l;
    if (a < 0) a += l;
    if (b < 0) b += l;
    if (a <= b) return m.extractPath(a, b);
    return m.extractPath(a, l)..addPath(m.extractPath(0, b), Offset.zero);
  }

  /// Band polygon jiske kone [r] se gol hain
  static Path _roundedPolygon(List<Offset> pts, double r) {
    final path = Path();
    final n = pts.length;
    for (var i = 0; i < n; i++) {
      final prev = pts[(i - 1 + n) % n];
      final cur = pts[i];
      final next = pts[(i + 1) % n];
      final inDir = cur - prev;
      final outDir = next - cur;
      // Seedhi line par (jaise shuru wala neeche-beech point) kona nahi
      final straight =
          (inDir.dx * outDir.dy - inDir.dy * outDir.dx).abs() < 1e-6;
      if (straight) {
        i == 0 ? path.moveTo(cur.dx, cur.dy) : path.lineTo(cur.dx, cur.dy);
        continue;
      }
      final rin = math.min(r, inDir.distance / 2);
      final rout = math.min(r, outDir.distance / 2);
      final a = cur - inDir / inDir.distance * rin;
      final b = cur + outDir / outDir.distance * rout;
      i == 0 ? path.moveTo(a.dx, a.dy) : path.lineTo(a.dx, a.dy);
      path.quadraticBezierTo(cur.dx, cur.dy, b.dx, b.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_HpLoaderPainter old) =>
      old.color != color ||
      old.accent != accent ||
      old.fontFamily != fontFamily ||
      old.showLetters != showLetters ||
      old.showChimney != showChimney;
}
