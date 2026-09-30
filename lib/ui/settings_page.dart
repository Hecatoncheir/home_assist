import 'package:flutter/material.dart';

import '../core/accounts/session.dart';
import '../core/cloud/regions.dart';
import '../core/preferences.dart';
import 'theme.dart';
import 'widgets/device_tile.dart';
import 'widgets/ui_scale.dart';

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

  /// С этой ширины настройки раскладываются в две колонки.
  static const _twoColumns = 860.0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _twoColumns;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 1080 : 640),
              child: ListView(
                // Снизу — место под стеклянную нижнюю панель на телефоне.
                padding: EdgeInsets.fromLTRB(
                  20,
                  28,
                  20,
                  40 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  Text('Настройки', style: context.display(28)),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _column(_left(context))),
                        const SizedBox(width: 24),
                        Expanded(child: _column(_right(context))),
                      ],
                    )
                  else
                    _column([..._left(context), ..._right(context)]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _column(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );

  List<Widget> _left(BuildContext context) => [
    const _SectionTitle('Аккаунты Xiaomi'),
    _accounts(context),
    const _SectionTitle('Оформление'),
    _Card(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      children: [
        SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('Авто')),
            ButtonSegment(value: ThemeMode.light, label: Text('Светлая')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Тёмная')),
          ],
          selected: {prefs.themeMode},
          onSelectionChanged: (modes) => prefs.themeMode = modes.first,
        ),
        const SizedBox(height: 12),
        UiScaleControl(prefs: prefs),
      ],
    ),
  ];

  List<Widget> _right(BuildContext context) {
    final c = context.colors;
    return [
      const _SectionTitle('Какие регионы опрашивать'),
      _Card(
        padding: const EdgeInsets.all(14),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final region in allRegions) _regionChip(region)],
          ),
          const SizedBox(height: 12),
          Text(
            'Изменение применится при следующем обновлении списка.',
            style: TextStyle(color: c.muted, fontSize: 13),
          ),
        ],
      ),
      const SizedBox(height: 20),
      _Card(
        children: [
          ListTile(
            leading: Icon(Icons.logout, color: c.bad),
            title: Text(
              _logoutLabel,
              style: TextStyle(color: c.bad, fontWeight: FontWeight.w600),
            ),
            onTap: onLogout,
          ),
        ],
      ),
    ];
  }

  Widget _accounts(BuildContext context) {
    final c = context.colors;
    return _Card(
      children: [
        for (final session in sessions)
          _AccountRow(
            session,
            onRemove: _demo ? null : () => _confirmRemove(context, session),
          ),
        if (!_demo)
          ListTile(
            leading: Icon(Icons.add, color: c.accent),
            title: Text(
              'Добавить аккаунт',
              style: TextStyle(color: c.accent, fontWeight: FontWeight.w600),
            ),
            onTap: onAddAccount,
          ),
      ],
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

  Widget _regionChip(String region) => _RegionChip(
    region: region,
    selected: prefs.regions.contains(region),
    onTap: () => prefs.setRegionPolled(region, !prefs.regions.contains(region)),
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
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: context
          .display(12, weight: FontWeight.w700)
          .copyWith(color: context.colors.muted, letterSpacing: 1),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children, this.padding = EdgeInsets.zero});

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.tile,
    borderRadius: tileRadius,
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

/// Регион-переключатель в виде «пилюли»: код и название.
class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.region,
    required this.selected,
    required this.onTap,
  });

  final String region;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final foreground = selected ? c.onAccent : c.ink;
    return Semantics(
      toggled: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? c.accent : c.bg,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RegionBadge(region, color: foreground),
              const SizedBox(width: 8),
              Text(
                regionNames[region]!,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
