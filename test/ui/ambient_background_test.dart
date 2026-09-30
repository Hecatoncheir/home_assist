import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/ui/theme.dart';
import 'package:home_assist/ui/widgets/glass.dart';

void main() {
  testWidgets('курсор над фоном не мешает нажатиям на содержимое', (
    tester,
  ) async {
    var taps = 0;
    const key = ValueKey('background');
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(HomeColors.dark, Brightness.dark),
        home: RepaintBoundary(
          key: key,
          child: AmbientBackground(
            child: Center(
              child: TextButton(
                onPressed: () => taps++,
                child: const Text('Кнопка'),
              ),
            ),
          ),
        ),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(200, 200));
    await mouse.moveTo(const Offset(260, 240));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Кнопка'));
    expect(taps, 1);

    // Для проверки глазами: SAVE_BACKGROUND=1 flutter test этот файл.
    await tester.pump(const Duration(seconds: 1));
    if (Platform.environment.containsKey('SAVE_BACKGROUND')) {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(key),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${Directory.systemTemp.path}/background.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
    await mouse.removePointer();
  });
}
