import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/core/accounts/session.dart';
import 'package:home_assist/core/cloud/mi_cloud_client.dart';
import 'package:home_assist/core/cloud/xiaomi_login.dart';
import 'package:home_assist/core/preferences.dart';
import 'package:home_assist/ui/l10n.dart';
import 'package:home_assist/ui/settings_page.dart';
import 'package:home_assist/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Set<String> _keys(String locale) {
  final arb = File('lib/l10n/app_$locale.arb').readAsStringSync();
  final keys = (jsonDecode(arb) as Map<String, dynamic>).keys;
  // Служебные записи `@…` (порядок параметров) есть только в русском.
  return keys.where((key) => !key.startsWith('@')).toSet();
}

void main() {
  test('во всех языках одинаковый набор строк', () {
    final ru = _keys('ru');
    expect(_keys('en'), ru);
    expect(_keys('zh'), ru);
  });

  test('по умолчанию язык берётся из системы', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await Preferences.load();
    expect(prefs.language, 'system');
    expect(prefs.locale, isNull);

    prefs.language = 'zh';
    expect(prefs.locale, const Locale('zh'));
  });

  test('параметры подставляются в порядке из текста', () {
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(ru.devicesSummary(6, 7, 2), 'В сети 6 из 7 · регионов: 2');
    expect(ru.probeScanning(3, 9), 'Опрашиваю siid 3 из 9…');
    expect(
      ru.swingReady('4.0', '1.5'),
      'Нажмите на дугу, чтобы повернуть вентилятор. '
      'Проход — 4.0 с, пауза у края — 1.5 с.',
    );
  });

  test('ошибки ядра переводятся на язык интерфейса', () {
    final wrongPassword = LoginException(LoginFailure.wrongCredentials);
    expect(
      describeError(lookupAppLocalizations(const Locale('ru')), wrongPassword),
      'Неверный логин или пароль',
    );
    expect(
      describeError(lookupAppLocalizations(const Locale('en')), wrongPassword),
      'Wrong login or password',
    );
    expect(
      describeError(
        lookupAppLocalizations(const Locale('zh')),
        CommandRejectedException(-4004),
      ),
      '设备拒绝了该命令（-4004）',
    );
  });

  testWidgets('язык переключается в настройках', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'language': 'ru'});
    final prefs = await Preferences.load();

    await tester.pumpWidget(
      ListenableBuilder(
        listenable: prefs,
        builder: (context, _) => MaterialApp(
          theme: buildTheme(HomeColors.light, Brightness.light),
          locale: prefs.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SettingsPage(
              sessions: const [
                Session(userId: '1', ssecurity: '', serviceToken: ''),
              ],
              prefs: prefs,
              onAddAccount: () {},
              onRemoveAccount: (_) {},
              onLogout: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Настройки'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(prefs.language, 'en');
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Russia'), findsOneWidget);

    await tester.tap(find.text('中文'));
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsOneWidget);
  });
}
