// Рисует исходники иконки приложения в assets/icon/.
// Из них flutter_launcher_icons делает иконки для всех платформ:
//   ICONS=1 flutter test test/screenshots/icon_test.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/ui/theme.dart';

const _size = 1024.0;
const _c = HomeColors.light;
const _backgroundTop = Color(0xFF1E2A38);
const _backgroundBottom = Color(0xFF101820);

final _skip = !Platform.environment.containsKey('ICONS');

void main() {
  group('иконка', skip: _skip, () {
    test('на весь квадрат: iOS и старый Android', () async {
      await _save('icon', (canvas) {
        _background(canvas, Offset.zero & const Size.square(_size), 0);
        _windows(canvas, contentSize: 560);
      });
    });

    test('скруглённая с полями: Windows, macOS, Linux', () async {
      await _save('icon_rounded', (canvas) {
        final body = Rect.fromLTWH(100, 90, 824, 824);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            body.translate(0, 14),
            const Radius.circular(185),
          ),
          Paint()
            ..color = Colors.black.withValues(alpha: .28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
        );
        _background(canvas, body, 185);
        _windows(canvas, contentSize: 450, center: body.center);
      });
    });

    test('передний план адаптивной иконки Android', () async {
      await _save('icon_foreground', (canvas) {
        _windows(canvas, contentSize: 430);
      });
    });
  });
}

void _background(Canvas canvas, Rect rect, double radius) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(radius)),
    Paint()
      ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
        _backgroundTop,
        _backgroundBottom,
      ]),
  );
}

/// Четыре окна дома: два горят тёплым, два тёмные.
void _windows(
  Canvas canvas, {
  required double contentSize,
  Offset center = const Offset(_size / 2, _size / 2),
}) {
  final gap = contentSize * .11;
  final pane = (contentSize - gap) / 2;
  final radius = Radius.circular(pane * .26);
  final origin = center - Offset(contentSize / 2, contentSize / 2);
  Rect cell(int column, int row) => Rect.fromLTWH(
    origin.dx + column * (pane + gap),
    origin.dy + row * (pane + gap),
    pane,
    pane,
  );

  final dark = Paint()..color = Colors.white.withValues(alpha: .13);
  canvas
    ..drawRRect(RRect.fromRectAndRadius(cell(1, 0), radius), dark)
    ..drawRRect(RRect.fromRectAndRadius(cell(0, 1), radius), dark);
  _litWindow(canvas, cell(0, 0), radius, _c.glowA, _c.glowB);
  _litWindow(canvas, cell(1, 1), radius, const Color(0xFFFFE3A3), _c.glowA);
}

void _litWindow(Canvas canvas, Rect rect, Radius radius, Color a, Color b) {
  final shape = RRect.fromRectAndRadius(rect, radius);
  canvas
    ..drawRRect(
      shape,
      Paint()
        ..color = b.withValues(alpha: .55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.width * .14),
    )
    ..drawRRect(
      shape,
      Paint()
        ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [a, b]),
    );
}

Future<void> _save(String name, void Function(Canvas canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(
    _size.toInt(),
    _size.toInt(),
  );
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('assets/icon/$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(png!.buffer.asUint8List());
}
