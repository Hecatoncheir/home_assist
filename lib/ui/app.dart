import 'package:flutter/material.dart';

import '../core/accounts/session.dart';
import '../core/accounts/session_store.dart';
import '../core/preferences.dart';
import '../core/spec/spec_repository.dart';
import 'home_shell.dart';
import 'login_page.dart';
import 'theme.dart';

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
  Session? _session;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final session = await widget.store.load();
    setState(() {
      _session = session;
      _loading = false;
    });
  }

  Future<void> _logIn(Session session) async {
    await widget.store.save(session);
    setState(() => _session = session);
  }

  Future<void> _logOut() async {
    await widget.store.clear();
    setState(() => _session = null);
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
    final session = _session;
    if (session == null) return LoginPage(onLoggedIn: _logIn);
    return HomeShell(
      key: ValueKey(session.serviceToken),
      session: session,
      prefs: widget.prefs,
      specs: widget.specs,
      onLogout: _logOut,
    );
  }
}
