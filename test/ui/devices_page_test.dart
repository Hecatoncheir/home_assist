import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_assist/core/accounts/session.dart';
import 'package:home_assist/core/cloud/mi_cloud_client.dart';
import 'package:home_assist/core/devices/device_controller.dart';
import 'package:home_assist/core/devices/device_repository.dart';
import 'package:home_assist/core/devices/device_transport.dart';
import 'package:home_assist/core/preferences.dart';
import 'package:home_assist/core/spec/spec_repository.dart';
import 'package:home_assist/ui/devices_page.dart';
import 'package:home_assist/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_cloud.dart';

const _second = Session(
  userId: '77',
  ssecurity: 'AAECAwQFBgcICQoLDA0ODw==',
  serviceToken: 'token',
  label: 'second@example.com',
);

Map<String, dynamic> _fan(String did, String name) => {
  'did': did,
  'model': 'dmaker.fan.p5',
  'name': name,
  'isOnline': true,
};

/// Облако аккаунта: отдаёт [devices] в регионе [region], всё выключено.
MiCloudClient _cloud(
  Session session,
  String region,
  List<Map<String, dynamic>> devices,
) => fakeCloud(session: session, (call) {
  if (call.path == '/home/device_list') {
    final host = region == 'cn' ? 'api.io.mi.com' : '$region.api.io.mi.com';
    return {'list': call.host == host ? devices : const <Object>[]};
  }
  return [
    for (final param in call.data['params'] as List)
      {...param as Map<String, dynamic>, 'code': 0, 'value': false},
  ];
});

void main() {
  late Directory cacheDir;

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    cacheDir = Directory.systemTemp.createTempSync('specs');
    File('${cacheDir.path}/spec/dmaker.fan.p5.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        File('test/fixtures/spec/dmaker.fan.p5.json').readAsStringSync(),
      );
  });
  tearDown(() => cacheDir.deleteSync(recursive: true));

  Future<void> pumpPage(
    WidgetTester tester,
    Size size,
    List<MiCloudClient> clouds,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final specs = SpecRepository(cacheDir: cacheDir);
    final transports = {
      for (final cloud in clouds) cloud.session.userId: CloudTransport(cloud),
    };
    // Сеть и диск в тестах виджетов работают только внутри runAsync.
    await tester.runAsync(() async {
      final prefs = await Preferences.load();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(HomeColors.light, Brightness.light),
          home: Scaffold(
            body: DevicesPage(
              repositories: [
                for (final cloud in clouds) DeviceRepository(cloud),
              ],
              accounts: [for (final cloud in clouds) cloud.session],
              prefs: prefs,
              createController: (device) => DeviceController(
                device,
                specs,
                transports[device.accountId]!,
              ),
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
      await pumpPage(tester, size, [
        _cloud(fakeSession, 'ru', [_fan('1', 'Вентилятор')]),
      ]);

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

  testWidgets('два аккаунта: общий список без повторов', (tester) async {
    await pumpPage(tester, const Size(1280, 800), [
      _cloud(fakeSession, 'ru', [_fan('1', 'Общий вентилятор')]),
      _cloud(_second, 'cn', [
        _fan('1', 'Общий вентилятор'),
        _fan('2', 'Китайский вентилятор'),
      ]),
    ]);

    expect(find.text('Общий вентилятор'), findsOneWidget);
    expect(find.text('Китайский вентилятор'), findsOneWidget);
    expect(find.text('В сети 2 из 2 · регионов: 2'), findsOneWidget);

    // Фильтр по аккаунту появляется, когда аккаунтов больше одного.
    await tester.tap(find.text('second@example.com  1'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Общий вентилятор'), findsNothing);
    expect(find.text('Китайский вентилятор'), findsOneWidget);
  });
}
