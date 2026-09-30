// Снимает скриншоты для README с настоящих экранов приложения в демо-режиме.
// Мышь и окна не трогает: всё рисуется внутри теста.
//
// Запуск (в обычном `flutter test` пропускается):
//   SCREENSHOTS=1 flutter test test/screenshots
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/core/accounts/session.dart';
import 'package:home_assist/core/cloud/xiaomi_login.dart';
import 'package:home_assist/core/preferences.dart';
import 'package:home_assist/core/spec/spec_repository.dart';
import 'package:home_assist/demo/demo.dart';
import 'package:home_assist/ui/home_shell.dart';
import 'package:home_assist/ui/login_page.dart';
import 'package:home_assist/ui/settings_page.dart';
import 'package:home_assist/ui/theme.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ratio = 2.0;
const _desktop = Size(1180, 740);
const _phone = Size(390, 844);
const _boundary = ValueKey('screenshot');

final _skip = !Platform.environment.containsKey('SCREENSHOTS');

void main() {
  late Preferences prefs;
  final specs = SpecRepository(cacheDir: Directory('test/fixtures'));

  Future<void> render(
    WidgetTester tester,
    Size size,
    Widget home, {
    bool dark = false,
  }) async {
    debugDisableShadows = false;
    tester.view.physicalSize = size * _ratio;
    tester.view.devicePixelRatio = _ratio;
    addTearDown(tester.view.reset);
    // Внутри runAsync файлы спецификаций читаются по-настоящему.
    await tester.runAsync(
      () => tester.pumpWidget(
        RepaintBoundary(
          key: _boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(HomeColors.light, Brightness.light),
            darkTheme: buildTheme(HomeColors.dark, Brightness.dark),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: home,
          ),
        ),
      ),
    );
    await _settle(tester);
  }

  Widget demoHome() => HomeShell(
    sessions: const [demoSession],
    prefs: prefs,
    specs: specs,
    onAddAccount: (_) async {},
    onRemoveAccount: (_) {},
    onLogout: () {},
  );

  /// Снимает экран и убирает его, чтобы не остались таймеры опроса.
  Future<void> shoot(WidgetTester tester, String name) async {
    await _save(tester, name);
    await tester.pumpWidget(const SizedBox());
    debugDisableShadows = true;
  }

  group('скриншоты', skip: _skip, () {
    // Внутри группы, чтобы при пропуске не искать шрифты в Flutter SDK:
    // в CI их по этому пути нет.
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await Preferences.load();
      await _loadFonts();
    });

    testWidgets('главный экран', (tester) async {
      await render(tester, _desktop, demoHome());
      await shoot(tester, 'home');
    });

    testWidgets('тёмная тема', (tester) async {
      await render(tester, _desktop, demoHome(), dark: true);
      await shoot(tester, 'home-dark');
    });

    testWidgets('панель вентилятора', (tester) async {
      await render(tester, _desktop, demoHome());
      await tester.tap(find.text('Вентилятор'));
      await _settle(tester);
      await shoot(tester, 'device');
    });

    testWidgets('телефон: дом', (tester) async {
      await render(tester, _phone, demoHome());
      await shoot(tester, 'phone-home');
    });

    testWidgets('телефон: лампа', (tester) async {
      await render(tester, _phone, demoHome(), dark: true);
      await tester.tap(find.text('Лампа у кровати'));
      await _settle(tester);
      await shoot(tester, 'phone-device');
    });

    testWidgets('телефон: настройки', (tester) async {
      await render(tester, _phone, _settingsWithTwoAccounts(prefs));
      await shoot(tester, 'phone-settings');
    });

    testWidgets('телефон: вход', (tester) async {
      await render(tester, _phone, LoginPage(onLoggedIn: (_) async {}));
      await shoot(tester, 'phone-login');
    });

    testWidgets('телефон: вход по QR-коду', (tester) async {
      final login = await tester.runAsync(_fakeQrLogin);
      await render(
        tester,
        _phone,
        LoginPage(onLoggedIn: (_) async {}, login: login),
        dark: true,
      );
      await tester.tap(find.text('Войти по QR-коду'));
      await _settle(tester);
      await shoot(tester, 'phone-qr');
      // Досрочно истекают ожидание подтверждения и тайм-ауты запросов.
      await tester.pump(const Duration(hours: 2));
    });
  });
}

/// Даёт отработать настоящим файлам и анимациям.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _save(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _ratio);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('docs/screenshots/$name.png')
        .writeAsBytes(png!.buffer.asUint8List());
  });
}

/// В тестах шрифты приложения не подключены — загружаем их из файлов.
/// Шрифт значков Material берём из Flutter SDK.
Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '';
  final families = {
    'MaterialIcons': [
      '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    ],
    'NunitoSans': [
      for (final weight in ['Regular', 'SemiBold', 'Bold'])
        'assets/fonts/NunitoSans-$weight.ttf',
    ],
    'Nunito': [
      for (final weight in ['SemiBold', 'Bold', 'ExtraBold'])
        'assets/fonts/Nunito-$weight.ttf',
    ],
    'JetBrainsMono': ['assets/fonts/JetBrainsMono-Regular.ttf'],
  };
  for (final MapEntry(key: family, value: paths) in families.entries) {
    final loader = FontLoader(family);
    for (final path in paths) {
      final bytes = File(path).readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

Widget _settingsWithTwoAccounts(Preferences prefs) => Scaffold(
  body: SafeArea(
    child: SettingsPage(
      sessions: const [
        Session(
          userId: '6201480048',
          ssecurity: '',
          serviceToken: '',
          label: 'home@example.com',
        ),
        Session(
          userId: '1877230003',
          ssecurity: '',
          serviceToken: '',
          label: 'china@example.com',
        ),
      ],
      prefs: prefs,
      onAddAccount: () {},
      onRemoveAccount: (_) {},
      onLogout: () {},
    ),
  ),
  bottomNavigationBar: NavigationBar(
    selectedIndex: 1,
    destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Дом'),
      NavigationDestination(icon: Icon(Icons.tune), label: 'Настройки'),
    ],
  ),
);

/// Сервер входа с картинкой, похожей на QR-код. Подтверждения он не присылает.
Future<XiaomiLogin> _fakeQrLogin() async {
  final image = await _fakeQrImage();
  return XiaomiLogin(
    client: MockClient((request) async {
      return switch (request.url.path) {
        '/longPolling/loginUrl' => http.Response(
          '&&&START&&&{"qr":"https://account.xiaomi.com/qr.png",'
          '"loginUrl":"https://account.xiaomi.com/longPolling/login?ticket=demo",'
          '"lp":"https://lp.account.xiaomi.com/lp/demo","timeout":300}',
          200,
        ),
        '/qr.png' => http.Response.bytes(image, 200),
        _ => Future<http.Response>.delayed(
          const Duration(hours: 1),
          () => http.Response('', 408),
        ),
      };
    }),
  );
}

/// Узор из модулей с тремя опорными квадратами. Не сканируется.
Future<Uint8List> _fakeQrImage() async {
  const modules = 29;
  const cell = 10.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final black = Paint()..color = const Color(0xFF15202B);
  final white = Paint()..color = Colors.white;
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, modules * cell, modules * cell),
    white,
  );
  final random = Random(7);
  for (var y = 0; y < modules; y++) {
    for (var x = 0; x < modules; x++) {
      if (random.nextBool()) {
        canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), black);
      }
    }
  }
  for (final corner in const [Offset(0, 0), Offset(22, 0), Offset(0, 22)]) {
    final origin = corner * cell;
    canvas
      ..drawRect(origin & const Size(7 * cell, 7 * cell), black)
      ..drawRect(
        (origin + const Offset(cell, cell)) & const Size(5 * cell, 5 * cell),
        white,
      )
      ..drawRect(
        (origin + const Offset(2 * cell, 2 * cell)) &
            const Size(3 * cell, 3 * cell),
        black,
      );
  }
  final picture = recorder.endRecording();
  final rendered = await picture.toImage(290, 290);
  final png = await rendered.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}
