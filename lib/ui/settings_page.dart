import 'package:flutter/material.dart';

import '../core/accounts/session.dart';
import '../core/cloud/regions.dart';
import '../core/preferences.dart';
import 'theme.dart';
import 'widgets/device_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.session,
    required this.prefs,
    required this.onLogout,
  });

  final Session session;
  final Preferences prefs;
  final VoidCallback onLogout;

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
              const _SectionTitle('Аккаунт Xiaomi'),
              _Card(
                children: [
                  ListTile(
                    leading: const _Avatar(),
                    title: const Text('Основной'),
                    subtitle: Text(
                      'ID ${session.userId}',
                      style: context.mono(),
                    ),
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
                      'Выйти из аккаунта',
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

  Widget _regionRow(String region) => SwitchListTile(
    secondary: RegionBadge(region),
    title: Text(regionNames[region]!),
    value: prefs.regions.contains(region),
    onChanged: (polled) => prefs.setRegionPolled(region, polled),
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
          .display(12, weight: FontWeight.w500)
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
