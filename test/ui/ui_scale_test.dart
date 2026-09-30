import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/core/accounts/session.dart';
import 'package:home_assist/core/preferences.dart';
import 'package:home_assist/ui/settings_page.dart';
import 'package:home_assist/l10n/app_localizations.dart';
import 'package:home_assist/ui/theme.dart';
import 'package:home_assist/ui/widgets/ui_scale.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('масштаб меняется кнопками и не ломает вёрстку', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await Preferences.load();

    await tester.pumpWidget(
      ListenableBuilder(
        listenable: prefs,
        builder: (context, _) => MaterialApp(
          theme: buildTheme(HomeColors.light, Brightness.light),
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => UiScale(prefs: prefs, child: child!),
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

    await tester.scrollUntilVisible(find.text('100 %'), 200);
    await tester.tap(find.byTooltip('Увеличить (Ctrl + +)'));
    await tester.pumpAndSettle();
    expect(prefs.uiScale, closeTo(1.1, 1e-9));
    expect(find.text('110 %'), findsOneWidget);

    prefs.uiScale = 9;
    await tester.pumpAndSettle();
    expect(prefs.uiScale, 1.5);
    expect(prefs.canZoomIn, isFalse);

    prefs.uiScale = .8;
    await tester.pumpAndSettle();
    expect(find.text('80 %'), findsOneWidget);
  });
}
