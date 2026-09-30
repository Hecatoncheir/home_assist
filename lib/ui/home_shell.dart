import 'package:flutter/material.dart';

import '../core/accounts/session.dart';
import '../core/cloud/mi_cloud_client.dart';
import '../core/devices/device_controller.dart';
import '../core/devices/device_repository.dart';
import '../core/devices/device_transport.dart';
import '../core/preferences.dart';
import '../core/spec/spec_repository.dart';
import '../demo/demo.dart';
import 'devices_page.dart';
import 'login_page.dart';
import 'settings_page.dart';
import 'widgets/logo.dart';

const _sections = [
  (icon: Icons.home_outlined, label: 'Дом'),
  (icon: Icons.tune, label: 'Настройки'),
];

/// Связь с одним аккаунтом: откуда брать устройства и куда слать команды.
typedef _Link = ({DeviceRepository repository, DeviceTransport transport});

/// Каркас после входа: нижняя панель на телефоне, боковая рейка на широком экране.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.sessions,
    required this.prefs,
    required this.specs,
    required this.onAddAccount,
    required this.onRemoveAccount,
    required this.onLogout,
  });

  final List<Session> sessions;
  final Preferences prefs;
  final SpecRepository specs;
  final Future<void> Function(Session session) onAddAccount;
  final ValueChanged<Session> onRemoveAccount;
  final VoidCallback onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// accountId → связь с этим аккаунтом.
  late final Map<String, _Link> _links = {
    for (final session in widget.sessions) session.userId: _connect(session),
  };
  int _index = 0;

  _Link _connect(Session session) {
    if (session.isDemo) {
      return (
        repository: DemoDeviceRepository(),
        transport: DemoTransport(widget.specs),
      );
    }
    final cloud = MiCloudClient(session);
    return (
      repository: DeviceRepository(cloud),
      transport: CloudTransport(cloud),
    );
  }

  void _select(int index) => setState(() => _index = index);

  /// Экран входа поверх настроек; с него можно вернуться кнопкой «Назад».
  void _openAddAccount() {
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => LoginPage(
          onCancel: navigator.pop,
          onLoggedIn: (session) async {
            navigator.pop();
            await widget.onAddAccount(session);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final pages = IndexedStack(
      index: _index,
      children: [
        DevicesPage(
          repositories: [for (final link in _links.values) link.repository],
          accounts: widget.sessions,
          prefs: widget.prefs,
          createController: (device) => DeviceController(
            device,
            widget.specs,
            _links[device.accountId]!.transport,
          ),
        ),
        SettingsPage(
          sessions: widget.sessions,
          prefs: widget.prefs,
          onAddAccount: _openAddAccount,
          onRemoveAccount: widget.onRemoveAccount,
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
