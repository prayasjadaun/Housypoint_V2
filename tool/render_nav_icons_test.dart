// One-off: shell nav ke icons ko assets/nav/*.png me render karta hai,
// kyunki iOS 26 native tab bar icon font / SVG nahi dikha sakta.
// Run: flutter test tool/render_nav_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

const _size = 78.0;
// Line icons ki line har taraf se kitne px patli (78px icon, line ~5px)
const _thinBy = 1.5;
const _hires = 8.0;

void main() {
  testWidgets('render nav icons', (tester) async {
    await tester.runAsync(() async {
      final home = Platform.environment['HOME'];
      final ttf = File(
        '$home/.pub-cache/hosted/pub.dev/iconsax_flutter-1.0.1/fonts/FlutterIconsax.ttf',
      ).readAsBytesSync();
      await (FontLoader(
        'packages/iconsax_flutter/FlutterIconsax',
      )..addFont(Future.value(ByteData.sublistView(ttf)))).load();

      Directory('assets/nav').createSync(recursive: true);

      // `_copy` = linear, bina suffix = bold (same shape, bhara hua) — selected tab
      const icons = {
        'home': Iconsax.home_2_copy,
        'listings': Iconsax.buildings_copy,
        'saved': Iconsax.heart_copy,
        'refer': Iconsax.gift_copy,
        'menu': Iconsax.category_copy,
        'home_filled': Iconsax.home_2,
        'listings_filled': Iconsax.buildings,
        'saved_filled': Iconsax.heart,
        'refer_filled': Iconsax.gift,
        'menu_filled': Iconsax.category,
      };
      for (final e in icons.entries) {
        await _save(e.key, (canvas) {
          TextPainter glyph(Paint paint) => TextPainter(
            textDirection: TextDirection.ltr,
            text: TextSpan(
              text: String.fromCharCode(e.value.codePoint),
              style: TextStyle(
                fontFamily: e.value.fontFamily,
                package: e.value.fontPackage,
                fontSize: _size,
                height: 1,
                foreground: paint,
              ),
            ),
          )..layout();
          final fill = glyph(Paint()..color = Colors.black);
          final at = Offset(
            (_size - fill.width) / 2,
            (_size - fill.height) / 2,
          );
          // Filled icons nahi, warna unke andar ke cut-outs mote ho jaate
          if (e.key.endsWith('_filled')) return fill.paint(canvas, at);
          // Line native bar me moti lagti hai — glyph ke kinare par stroke se
          // erase karo, har jagah barabar patli hoti hai
          canvas.saveLayer(null, Paint());
          fill.paint(canvas, at);
          glyph(
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = _thinBy * 2
              ..blendMode = BlendMode.dstOut,
          ).paint(canvas, at);
          canvas.restore();
        });
      }
    });
  });
}

Future<void> _save(String name, void Function(Canvas) draw) async {
  // Bade canvas par banao phir chhota karo — kinare smooth rahein
  const big = _size * _hires;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(_hires);
  draw(canvas);
  final bigImage = await recorder.endRecording().toImage(
    big.toInt(),
    big.toInt(),
  );

  final small = ui.PictureRecorder();
  Canvas(small).drawImageRect(
    bigImage,
    Offset.zero & const Size(big, big),
    Offset.zero & const Size(_size, _size),
    Paint()..filterQuality = FilterQuality.high,
  );
  final image = await small.endRecording().toImage(
    _size.toInt(),
    _size.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('assets/nav/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}
