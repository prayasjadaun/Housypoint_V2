import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Zomato-style circular reveal animation for theme switching: snapshots the
/// current (old) theme, swaps the theme underneath, then punches an
/// expanding circular hole through the snapshot at the tap position so the
/// new theme is revealed through it.
class ThemeSwitchOverlay {
  ThemeSwitchOverlay._();

  /// Marks the single [RepaintBoundary] wrapping the whole app (installed by
  /// [MaterialApp.builder] in app.dart) so [animate] always snapshots the
  /// exact same, full-screen boundary — never a smaller one picked up by
  /// searching ancestors from whichever page happens to call it.
  static final rootBoundaryKey = GlobalKey();

  static OverlayEntry? _entry;

  static Future<void> animate(
    BuildContext context, {
    required Offset tapPosition,
    required VoidCallback onThemeChange,
  }) async {
    final boundary = rootBoundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      onThemeChange();
      return;
    }

    // The boundary's own logical size (not MediaQuery's screen size) so the
    // snapshot is never stretched if the boundary's size differs from the
    // screen size.
    final boundarySize = boundary.size;
    final origin = boundary.localToGlobal(Offset.zero);

    final image = await boundary.toImage(
      pixelRatio: ui.PlatformDispatcher.instance.views.first.devicePixelRatio,
    );

    if (!context.mounted) return;

    final overlay = Overlay.of(context);
    final completer = Completer<void>();

    _entry = OverlayEntry(
      builder: (_) => Positioned(
        left: origin.dx,
        top: origin.dy,
        width: boundarySize.width,
        height: boundarySize.height,
        child: _ThemeRevealOverlay(
          image: image,
          tapPosition: tapPosition - origin,
          screenSize: boundarySize,
          onDone: () {
            _entry?.remove();
            _entry = null;
            if (!completer.isCompleted) completer.complete();
          },
        ),
      ),
    );

    // Swap the theme first so it renders underneath the old snapshot.
    onThemeChange();

    overlay.insert(_entry!);

    return completer.future;
  }
}

class _ThemeRevealOverlay extends StatefulWidget {
  const _ThemeRevealOverlay({
    required this.image,
    required this.tapPosition,
    required this.screenSize,
    required this.onDone,
  });

  final ui.Image image;
  final Offset tapPosition;
  final Size screenSize;
  final VoidCallback onDone;

  @override
  State<_ThemeRevealOverlay> createState() => _ThemeRevealOverlayState();
}

class _ThemeRevealOverlayState extends State<_ThemeRevealOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _radius;

  @override
  void initState() {
    super.initState();
    final maxRadius = _maxRadius(widget.tapPosition, widget.screenSize);
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _radius = Tween<double>(begin: 0, end: maxRadius).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuart),
    );
    _controller.forward().whenComplete(widget.onDone);
  }

  double _maxRadius(Offset tap, Size size) {
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    return corners.map((c) => (c - tap).distance).reduce((a, b) => a > b ? a : b);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _radius,
        builder: (_, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _RevealPainter(
              image: widget.image,
              tapPosition: widget.tapPosition,
              radius: _radius.value,
            ),
          );
        },
      ),
    );
  }
}

class _RevealPainter extends CustomPainter {
  _RevealPainter({
    required this.image,
    required this.tapPosition,
    required this.radius,
  });

  final ui.Image image;
  final Offset tapPosition;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    canvas.save();

    // Clip everything EXCEPT the expanding circle — the old theme snapshot
    // stays visible outside the circle while the new theme shows through it.
    final clipPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: tapPosition, radius: radius))
      ..fillType = PathFillType.evenOdd;

    canvas.clipPath(clipPath);

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RevealPainter oldDelegate) => oldDelegate.radius != radius;
}
