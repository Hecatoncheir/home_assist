import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_assist/core/devices/device_controller.dart';
import 'package:home_assist/core/devices/device_repository.dart';
import 'package:home_assist/core/devices/device_transport.dart';
import 'package:home_assist/core/preferences.dart';
import 'package:home_assist/core/spec/spec_repository.dart';
import 'package:home_assist/ui/devices_page.dart';
import 'package:home_assist/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_cloud.dart';

/// Облако с одним выключенным вентилятором в регионе `ru`.
Object? _respond(CloudCall call) {
  if (call.path == '/home/device_list') {
    final fan = {
      'did': '1',
      'model': 'dmaker.fan.p5',
      'name': 'Вентилятор',
      'isOnline': true,
    };
    return {
      'list': [if (call.host.startsWith('ru.')) fan],
    };
  }
  return [
    for (final param in call.data['params'] as List)
      {...param as Map<String, dynamic>, 'code': 0, 'value': false},
  ];
}

void main() {
  late Directory cacheDir;

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    cacheDir = Directory.systemTemp.createTempSync('specs');
    File('${cacheDir.path}/spec/dmaker.fan.p5.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        File('test/fixtures/dmaker.fan.p5.json').readAsStringSync(),
      );
  });
  tearDown(() => cacheDir.deleteSync(recursive: true));

  Future<void> pumpPage(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cloud = fakeCloud(_respond);
    final specs = SpecRepository(cacheDir: cacheDir);
    final transport = CloudTransport(cloud);
    // Сеть и диск в тестах виджетов работают только внутри runAsync.
    await tester.runAsync(() async {
      final prefs = await Preferences.load();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(HomeColors.light, Brightness.light),
          home: Scaffold(
            body: DevicesPage(
              repository: DeviceRepository(cloud),
              prefs: prefs,
              createController: (device) =>
                  DeviceController(device, specs, transport),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump(const Duration(seconds: 1));
  }

  for (final size in const [Size(390, 800), Size(1280, 800)]) {
    testWidgets('плитка и панель устройства на экране $size', (tester) async {
      await pumpPage(tester, size);

      expect(find.text('Вентилятор'), findsOneWidget);
      expect(find.text('Выключено'), findsOneWidget);
      expect(find.text('В сети 1 из 1 · регионов: 1'), findsOneWidget);

      await tester.tap(find.text('Вентилятор'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Элементы управления построены из спецификации.
      expect(find.text('Horizontal Swing'), findsOneWidget);
      expect(find.text('Straight Wind'), findsOneWidget);
      expect(find.text('dmaker.fan.p5'), findsOneWidget);
    });
  }
}
