import 'package:flutter/material.dart';

import '../core/accounts/session.dart';
import '../core/cloud/regions.dart';
import '../core/preferences.dart';
import 'theme.dart';
import 'widgets/device_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.sessions,
    required this.prefs,
    required this.onAddAccount,
    required this.onRemoveAccount,
    required this.onLogout,
  });

  final List<Session> sessions;
  final Preferences prefs;
  final VoidCallback onAddAccount;
  final ValueChanged<Session> onRemoveAccount;
  final VoidCallback onLogout;

  bool get _demo => sessions.any((session) => session.isDemo);

  String get _logoutLabel {
    if (_demo) return 'Выйти из демо';
    return sessions.length > 1
        ? 'Выйти из всех аккаунтов'
        : 'Выйти из аккаунта';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
            children: [
              Text('Настройки', style: context.display(28)),
              const _SectionTitle('Аккаунты Xiaomi'),
              _Card(
                children: [
                  for (final session in sessions)
                    _AccountRow(
                      session,
                      onRemove: _demo
                          ? null
                          : () => _confirmRemove(context, session),
                    ),
                  if (!_demo)
                    ListTile(
                      leading: Icon(Icons.add, color: c.accent),
                      title: Text(
                        'Добавить аккаунт',
                        style: TextStyle(
                          color: c.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: onAddAccount,
                    ),
                ],
              ),
              const _SectionTitle('Какие регионы опрашивать'),
              _Card(
                children: [for (final region in allRegions) _regionRow(region)],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Изменение применится при следующем обновлении списка.',
                  style: TextStyle(color: c.muted, fontSize: 13),
                ),
              ),
              const _SectionTitle('Оформление'),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Как в системе'),
                  ),
                  ButtonSegment(value: ThemeMode.light, label: Text('Светлая')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Тёмная')),
                ],
                selected: {prefs.themeMode},
                onSelectionChanged: (modes) => prefs.themeMode = modes.first,
              ),
              const SizedBox(height: 28),
              _Card(
                children: [
                  ListTile(
                    leading: Icon(Icons.logout, color: c.bad),
                    title: Text(
                      _logoutLabel,
                      style: TextStyle(
                        color: c.bad,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: onLogout,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, Session session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Убрать аккаунт?'),
        content: Text(
          '${session.label}\n\nЕго устройства пропадут из списка. '
          'Сами устройства и аккаунт Xiaomi не изменятся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Убрать'),
          ),
        ],
      ),
    );
    if (confirmed == true) onRemoveAccount(session);
  }

  Widget _regionRow(String region) => SwitchListTile(
    secondary: RegionBadge(region),
    title: Text(regionNames[region]!),
    value: prefs.regions.contains(region),
    onChanged: (polled) => prefs.setRegionPolled(region, polled),
  );
}

class _AccountRow extends StatelessWidget {
  const _AccountRow(this.session, {required this.onRemove});

  final Session session;

  /// `null` — аккаунт убрать нельзя (демо).
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const _Avatar(),
    title: Text(session.label, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text('ID ${session.userId}', style: context.mono()),
    trailing: onRemove == null
        ? null
        : IconButton(
            tooltip: 'Убрать аккаунт',
            icon: Icon(Icons.close, color: context.colors.bad),
            onPressed: onRemove,
          ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Text(
      text.toUpperCase(),
      style: context
          .display(12, weight: FontWeight.w700)
          .copyWith(color: context.colors.muted, letterSpacing: 1),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.tile,
    borderRadius: tileRadius,
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: context.colors.glow,
    ),
    child: Icon(Icons.person, color: context.colors.glowInk, size: 20),
  );
}
