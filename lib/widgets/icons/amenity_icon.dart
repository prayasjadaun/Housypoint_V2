import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Housy Point's own amenity icon set — hand-drawn line icons on a 24×24
/// grid (1.6 stroke, rounded caps), picked from the amenity name.
class AmenityIcon extends StatelessWidget {
  const AmenityIcon({super.key, required this.name, this.size = 24, this.color = Colors.black});

  /// Amenity name from the API, e.g. "swimming pool", "kids play area".
  final String name;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _AmenityPainter(_AmenityKind.of(name), color),
    );
  }
}

enum _AmenityKind {
  gym, pool, garden, clubhouse, security, parking, power, lift, kids, track,
  sports, yoga, spa, wifi, water, fire, shopping, cafe, theatre, games,
  lounge, salon, banquet, other;

  /// First keyword match wins, so put specific words before generic ones.
  static _AmenityKind of(String raw) {
    final n = raw.toLowerCase();
    bool has(List<String> words) => words.any(n.contains);
    if (has(['gym', 'fitness'])) return gym;
    if (has(['pool', 'swim'])) return pool;
    if (has(['kid', 'child', 'play area', 'creche'])) return kids;
    if (has(['jog', 'walk', 'track', 'cycl'])) return track;
    if (has(['yoga', 'meditat'])) return yoga;
    if (has(['sauna', 'steam', 'spa', 'jacuzzi'])) return spa;
    if (has(['salon', 'barber'])) return salon;
    if (has(['theatre', 'theater', 'cinema', 'movie'])) return theatre;
    if (has(['indoor game', 'game', 'billiard', 'snooker', 'table tennis'])) return games;
    if (has(['basketball', 'tennis', 'cricket', 'court', 'badminton', 'football', 'sport'])) return sports;
    if (has(['garden', 'park', 'green', 'lawn', 'landscape'])) return garden;
    if (has(['club'])) return clubhouse;
    if (has(['banquet', 'party', 'hall', 'community'])) return banquet;
    if (has(['lounge', 'sitting'])) return lounge;
    if (has(['security', 'cctv', 'guard', 'gated'])) return security;
    if (has(['parking'])) return parking;
    if (has(['power', 'backup', 'generator', 'electric'])) return power;
    if (has(['lift', 'elevator'])) return lift;
    if (has(['wifi', 'wi-fi', 'internet'])) return wifi;
    if (has(['water', 'rain'])) return water;
    if (has(['fire'])) return fire;
    if (has(['shop', 'retail', 'mart', 'store'])) return shopping;
    if (has(['cafe', 'café', 'coffee', 'restaurant', 'food'])) return cafe;
    return other;
  }
}

class _AmenityPainter extends CustomPainter {
  _AmenityPainter(this.kind, this.color);

  final _AmenityKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), p);
    void rrect(double l, double t, double w, double h, double r) =>
        canvas.drawRRect(RRect.fromLTRBR(l, t, l + w, t + h, Radius.circular(r)), p);
    void circle(double x, double y, double r) => canvas.drawCircle(Offset(x, y), r, p);
    void dot(double x, double y, [double r = 0.9]) => canvas.drawCircle(Offset(x, y), r, fill);
    void path(void Function(Path) build) {
      final path = Path();
      build(path);
      canvas.drawPath(path, p);
    }

    void wave(double y) => path((w) => w
      ..moveTo(3, y)
      ..quadraticBezierTo(5.25, y - 2, 7.5, y)
      ..quadraticBezierTo(9.75, y + 2, 12, y)
      ..quadraticBezierTo(14.25, y - 2, 16.5, y)
      ..quadraticBezierTo(18.75, y + 2, 21, y));

    switch (kind) {
      case _AmenityKind.gym:
        rrect(2.5, 9, 2.5, 6, 1);
        rrect(5, 6.5, 2.8, 11, 1.2);
        rrect(16.2, 6.5, 2.8, 11, 1.2);
        rrect(19, 9, 2.5, 6, 1);
        line(7.8, 12, 16.2, 12);
      case _AmenityKind.pool:
        path((l) => l
          ..moveTo(8, 14)
          ..lineTo(8, 5.5)
          ..quadraticBezierTo(8, 3.5, 10, 3.5));
        path((l) => l
          ..moveTo(15, 14)
          ..lineTo(15, 5.5)
          ..quadraticBezierTo(15, 3.5, 17, 3.5));
        line(8, 8, 15, 8);
        line(8, 11.5, 15, 11.5);
        wave(16.5);
        wave(20.5);
      case _AmenityKind.garden:
        circle(12, 8.5, 5);
        path((t) => t
          ..moveTo(12, 13.5)
          ..lineTo(12, 20.5)
          ..moveTo(12, 16.5)
          ..lineTo(9.5, 14.5)
          ..moveTo(12, 15.5)
          ..lineTo(14.5, 13.8));
        line(5, 20.5, 19, 20.5);
      case _AmenityKind.clubhouse:
        path((r) => r
          ..moveTo(3.5, 11)
          ..lineTo(12, 4)
          ..lineTo(20.5, 11));
        rrect(5.5, 9.5, 13, 11, 1.5);
        rrect(10, 14.5, 4, 6, 1);
        dot(17, 4.8, 0.8);
        line(17, 5.6, 17, 7.8);
      case _AmenityKind.security:
        path((s) => s
          ..moveTo(12, 3)
          ..lineTo(19, 5.8)
          ..lineTo(19, 11)
          ..quadraticBezierTo(19, 17.5, 12, 21)
          ..quadraticBezierTo(5, 17.5, 5, 11)
          ..lineTo(5, 5.8)
          ..close());
        path((c) => c
          ..moveTo(9, 12)
          ..lineTo(11.2, 14.2)
          ..lineTo(15.2, 9.8));
      case _AmenityKind.parking:
        rrect(3.5, 3.5, 17, 17, 4.5);
        path((l) => l
          ..moveTo(10, 16.5)
          ..lineTo(10, 7.5)
          ..lineTo(13, 7.5)
          ..quadraticBezierTo(15.5, 7.5, 15.5, 10)
          ..quadraticBezierTo(15.5, 12.5, 13, 12.5)
          ..lineTo(10, 12.5));
      case _AmenityKind.power:
        path((b) => b
          ..moveTo(13.5, 2.5)
          ..lineTo(5.5, 13.5)
          ..lineTo(11.5, 13.5)
          ..lineTo(10.5, 21.5)
          ..lineTo(18.5, 10)
          ..lineTo(12.5, 10)
          ..close());
      case _AmenityKind.lift:
        rrect(5, 2.5, 14, 19, 2.5);
        path((a) => a
          ..moveTo(9.5, 9.5)
          ..lineTo(12, 7)
          ..lineTo(14.5, 9.5)
          ..moveTo(9.5, 14.5)
          ..lineTo(12, 17)
          ..lineTo(14.5, 14.5));
      case _AmenityKind.kids:
        // Slide with a ladder
        path((s) => s
          ..moveTo(4, 20.5)
          ..lineTo(4, 7)
          ..lineTo(8, 7)
          ..quadraticBezierTo(10, 7, 11.5, 9.5)
          ..lineTo(17.5, 18.5)
          ..quadraticBezierTo(18.5, 20.5, 20.5, 20.5));
        line(8, 7, 8, 20.5);
        line(4, 11, 8, 11);
        line(4, 15, 8, 15);
        circle(17.5, 6.5, 2.2);
      case _AmenityKind.track:
        rrect(2.5, 6.5, 19, 11, 5.5);
        rrect(6.5, 10, 11, 4, 2);
        line(12, 6.5, 12, 10);
      case _AmenityKind.sports:
        circle(12, 12, 8.5);
        line(3.5, 12, 20.5, 12);
        line(12, 3.5, 12, 20.5);
        path((s) => s
          ..moveTo(6, 6)
          ..quadraticBezierTo(9, 12, 6, 18)
          ..moveTo(18, 6)
          ..quadraticBezierTo(15, 12, 18, 18));
      case _AmenityKind.yoga:
        circle(12, 5, 2);
        path((b) => b
          ..moveTo(12, 7.5)
          ..lineTo(12, 13)
          ..moveTo(6, 10.5)
          ..quadraticBezierTo(9, 9, 12, 10)
          ..quadraticBezierTo(15, 9, 18, 10.5)
          ..moveTo(5, 18)
          ..quadraticBezierTo(8, 14, 12, 13)
          ..quadraticBezierTo(16, 14, 19, 18)
          ..moveTo(4, 20.5)
          ..lineTo(20, 20.5));
      case _AmenityKind.spa:
        // Lotus
        path((l) => l
          ..moveTo(12, 19)
          ..quadraticBezierTo(7.5, 14.5, 12, 6)
          ..quadraticBezierTo(16.5, 14.5, 12, 19)
          ..moveTo(12, 19)
          ..quadraticBezierTo(5, 18.5, 3.5, 11.5)
          ..quadraticBezierTo(8.5, 12, 10, 14.5)
          ..moveTo(12, 19)
          ..quadraticBezierTo(19, 18.5, 20.5, 11.5)
          ..quadraticBezierTo(15.5, 12, 14, 14.5));
        line(6, 21, 18, 21);
      case _AmenityKind.wifi:
        for (final r in [11.0, 7.0, 3.0]) {
          canvas.drawArc(
            Rect.fromCircle(center: const Offset(12, 19), radius: r + 2),
            -math.pi * 0.78,
            math.pi * 0.56,
            false,
            p,
          );
        }
        dot(12, 19, 1.3);
      case _AmenityKind.water:
        path((d) => d
          ..moveTo(12, 3)
          ..quadraticBezierTo(18.5, 10.5, 18.5, 14.5)
          ..arcToPoint(const Offset(5.5, 14.5), radius: const Radius.circular(6.5))
          ..quadraticBezierTo(5.5, 10.5, 12, 3));
        path((s) => s
          ..moveTo(9, 15)
          ..quadraticBezierTo(9.5, 17.5, 12, 17.8));
      case _AmenityKind.fire:
        path((f) => f
          ..moveTo(12, 21)
          ..quadraticBezierTo(5.5, 20.5, 5.5, 14.5)
          ..quadraticBezierTo(5.5, 10, 10, 7)
          ..quadraticBezierTo(10, 10, 12, 11)
          ..quadraticBezierTo(12, 6, 14.5, 3)
          ..quadraticBezierTo(18.5, 8, 18.5, 14.5)
          ..quadraticBezierTo(18.5, 20.5, 12, 21));
      case _AmenityKind.shopping:
        path((b) => b
          ..moveTo(5, 8)
          ..lineTo(19, 8)
          ..lineTo(18, 20.5)
          ..lineTo(6, 20.5)
          ..close());
        path((h) => h
          ..moveTo(9, 10.5)
          ..lineTo(9, 7)
          ..arcToPoint(const Offset(15, 7), radius: const Radius.circular(3))
          ..lineTo(15, 10.5));
      case _AmenityKind.cafe:
        path((c) => c
          ..moveTo(4.5, 9)
          ..lineTo(16.5, 9)
          ..lineTo(16.5, 15)
          ..quadraticBezierTo(16.5, 19.5, 12, 19.5)
          ..lineTo(9, 19.5)
          ..quadraticBezierTo(4.5, 19.5, 4.5, 15)
          ..close());
        path((h) => h
          ..moveTo(16.5, 10.5)
          ..quadraticBezierTo(20, 10.5, 20, 13)
          ..quadraticBezierTo(20, 15.5, 16.5, 15.5));
        path((s) => s
          ..moveTo(8, 6.5)
          ..quadraticBezierTo(9, 5, 8, 3.5)
          ..moveTo(12, 6.5)
          ..quadraticBezierTo(13, 5, 12, 3.5));
      case _AmenityKind.theatre:
        rrect(3, 3.5, 18, 11, 2);
        path((t) => t
          ..moveTo(10.5, 6.5)
          ..lineTo(14.5, 9)
          ..lineTo(10.5, 11.5)
          ..close());
        for (final x in [5.0, 10.0, 15.0]) {
          rrect(x, 17, 4, 3.5, 1.2);
        }
      case _AmenityKind.games:
        path((g) => g
          ..moveTo(7, 7.5)
          ..lineTo(17, 7.5)
          ..quadraticBezierTo(21.5, 7.5, 21.5, 13)
          ..quadraticBezierTo(21.5, 18.5, 18, 18)
          ..quadraticBezierTo(16, 17.5, 15, 15.5)
          ..lineTo(9, 15.5)
          ..quadraticBezierTo(8, 17.5, 6, 18)
          ..quadraticBezierTo(2.5, 18.5, 2.5, 13)
          ..quadraticBezierTo(2.5, 7.5, 7, 7.5));
        line(7.5, 10, 7.5, 13);
        line(6, 11.5, 9, 11.5);
        dot(16, 10.5);
        dot(17.5, 12.5);
      case _AmenityKind.lounge:
        path((s) => s
          ..moveTo(5, 11)
          ..lineTo(5, 8)
          ..quadraticBezierTo(5, 6, 7, 6)
          ..lineTo(17, 6)
          ..quadraticBezierTo(19, 6, 19, 8)
          ..lineTo(19, 11));
        rrect(2.5, 10.5, 19, 7, 2.5);
        line(5, 17.5, 5, 19.5);
        line(19, 17.5, 19, 19.5);
        line(7, 14, 17, 14);
      case _AmenityKind.salon:
        circle(7, 17.5, 3);
        circle(17, 17.5, 3);
        line(9.2, 15.4, 18, 4);
        line(14.8, 15.4, 6, 4);
      case _AmenityKind.banquet:
        // Cloche on a platter
        path((c) => c
          ..moveTo(4, 16.5)
          ..quadraticBezierTo(4, 8, 12, 8)
          ..quadraticBezierTo(20, 8, 20, 16.5));
        line(2.5, 16.5, 21.5, 16.5);
        line(4, 19.5, 20, 19.5);
        circle(12, 6, 1.6);
      case _AmenityKind.other:
        // Sparkle
        path((s) => s
          ..moveTo(12, 3)
          ..quadraticBezierTo(13, 11, 21, 12)
          ..quadraticBezierTo(13, 13, 12, 21)
          ..quadraticBezierTo(11, 13, 3, 12)
          ..quadraticBezierTo(11, 11, 12, 3));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AmenityPainter old) => old.kind != kind || old.color != color;
}
