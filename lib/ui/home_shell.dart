import 'package:flutter/material.dart';

import '../core/accounts/session.dart';
import '../core/cloud/mi_cloud_client.dart';
import '../core/devices/device_repository.dart';
import '../core/preferences.dart';
import 'devices_page.dart';
import 'settings_page.dart';
import 'widgets/logo.dart';

const _sections = [
  (icon: Icons.home_outlined, label: 'Дом'),
  (icon: Icons.tune, label: 'Настройки'),
];

/// Каркас после входа: нижняя панель на телефоне, боковая рейка на широком экране.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.session,
    required this.prefs,
    required this.onLogout,
  });

  final Session session;
  final Preferences prefs;
  final VoidCallback onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final _repository = DeviceRepository(MiCloudClient(widget.session));
  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final pages = IndexedStack(
      index: _index,
      children: [
        DevicesPage(repository: _repository, prefs: widget.prefs),
        SettingsPage(
          session: widget.session,
          prefs: widget.prefs,
          onLogout: widget.onLogout,
        ),
      ],
    );
    return Scaffold(
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  _rail(),
                  Expanded(child: pages),
                ],
              )
            : pages,
      ),
      bottomNavigationBar: wide ? null : _bottomBar(),
    );
  }

  Widget _rail() => NavigationRail(
    selectedIndex: _index,
    onDestinationSelected: _select,
    labelType: NavigationRailLabelType.all,
    leading: const Padding(
      padding: EdgeInsets.only(top: 12, bottom: 20),
      child: Logo(),
    ),
    destinations: [
      for (final section in _sections)
        NavigationRailDestination(
          icon: Icon(section.icon),
          label: Text(section.label),
        ),
    ],
  );

  Widget _bottomBar() => NavigationBar(
    selectedIndex: _index,
    onDestinationSelected: _select,
    destinations: [
      for (final section in _sections)
        NavigationDestination(icon: Icon(section.icon), label: section.label),
    ],
  );
}
