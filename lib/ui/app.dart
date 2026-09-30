import 'package:flutter/material.dart';

import '../core/accounts/session.dart';
import '../core/accounts/session_store.dart';
import '../core/preferences.dart';
import '../core/spec/spec_repository.dart';
import '../demo/demo.dart';
import 'home_shell.dart';
import 'login_page.dart';
import 'theme.dart';
import 'widgets/ui_scale.dart';

class HomeAssistApp extends StatefulWidget {
  const HomeAssistApp({
    super.key,
    required this.prefs,
    required this.specs,
    this.store = const SessionStore(),
  });

  final Preferences prefs;
  final SpecRepository specs;
  final SessionStore store;

  @override
  State<HomeAssistApp> createState() => _HomeAssistAppState();
}

class _HomeAssistAppState extends State<HomeAssistApp> {
  /// `flutter run --dart-define=DEMO=true` открывает демо сразу, без входа.
  static const _startInDemo = bool.fromEnvironment('DEMO');

  List<Session> _sessions = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final sessions = _startInDemo ? [demoSession] : await widget.store.load();
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  /// Повторный вход в тот же аккаунт заменяет его сессию, а не дублирует.
  Future<void> _addAccount(Session session) => _setSessions([
    ..._sessions.where((s) => s.userId != session.userId && !s.isDemo),
    session,
  ]);

  Future<void> _removeAccount(Session session) =>
      _setSessions(_sessions.where((s) => s != session).toList());

  Future<void> _setSessions(List<Session> sessions) async {
    final real = sessions.where((s) => !s.isDemo).toList();
    await widget.store.save(real);
    setState(() => _sessions = sessions);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.prefs,
      builder: (context, _) => MaterialApp(
        title: 'Home Assist',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(HomeColors.light, Brightness.light),
        darkTheme: buildTheme(HomeColors.dark, Brightness.dark),
        themeMode: widget.prefs.themeMode,
        builder: (context, child) =>
            UiScale(prefs: widget.prefs, child: child!),
        home: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _home(),
        ),
      ),
    );
  }

  Widget _home() {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_sessions.isEmpty) return LoginPage(onLoggedIn: _addAccount);
    return HomeShell(
      // Смена состава аккаунтов пересоздаёт каркас и перезагружает список.
      key: ValueKey(_sessions.map((s) => s.serviceToken).join()),
      sessions: _sessions,
      prefs: widget.prefs,
      specs: widget.specs,
      onAddAccount: _addAccount,
      onRemoveAccount: _removeAccount,
      onLogout: () => _setSessions(const []),
    );
  }
}
