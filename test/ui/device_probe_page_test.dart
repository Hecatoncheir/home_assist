import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/core/devices/device.dart';
import 'package:home_assist/core/devices/device_probe.dart';
import 'package:home_assist/core/spec/spec_repository.dart';
import 'package:home_assist/demo/demo.dart';
import 'package:home_assist/ui/device_probe_page.dart';
import 'package:home_assist/ui/theme.dart';

const _fan = Device(
  did: '1',
  model: 'dmaker.fan.p44',
  name: 'Вентилятор',
  region: 'cn',
  accountId: 'demo',
  localIp: '',
  token: '',
  isOnline: true,
  parentId: '',
);

void main() {
  for (final size in const [Size(390, 800), Size(1280, 800)]) {
    testWidgets('скан показывает свойства на экране $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final specs = SpecRepository(cacheDir: Directory('test/fixtures'));
      await tester.runAsync(() async {
        final probe = DeviceProbe(
          device: _fan,
          spec: await specs.forModel(_fan.model),
          transport: DemoTransport(specs),
          maxSiid: 9,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTheme(HomeColors.light, Brightness.light),
            home: DeviceProbePage(probe: probe),
          ),
        );
        await tester.tap(find.text('Сканировать'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(find.textContaining('Найдено свойств:'), findsOneWidget);
      expect(find.text('2.6'), findsOneWidget);
      expect(find.text('Air Cooler'), findsOneWidget);

      await tester.tap(find.text('Следить за изменениями'));
      await tester.pump();
      // Уход с экрана останавливает слежение.
      await tester.pumpWidget(const SizedBox());
    });
  }
}
