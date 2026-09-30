import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../core/accounts/session.dart';
import '../core/devices/device.dart';
import '../core/devices/device_controller.dart';
import '../core/devices/device_repository.dart';
import '../core/preferences.dart';
import 'device_sheet.dart';
import 'l10n.dart';
import 'theme.dart';
import 'widgets/device_tile.dart';
import 'widgets/reveal.dart';

const _allFilter = 'all';

class DevicesPage extends StatefulWidget {
  const DevicesPage({
    super.key,
    required this.repositories,
    required this.accounts,
    required this.prefs,
    required this.createController,
  });

  /// По одному источнику на аккаунт.
  final List<DeviceRepository> repositories;
  final List<Session> accounts;
  final Preferences prefs;
  final DeviceController Function(Device device) createController;

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List<Device> _devices = const [];
  Map<Device, DeviceController> _controllers = const {};
  List<RegionResult> _failed = const [];
  String _filter = _allFilter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final regions = widget.prefs.regions;
    final perAccount = await Future.wait([
      for (final repository in widget.repositories) repository.loadAll(regions),
    ]);
    final results = perAccount.expand((r) => r).toList();
    if (!mounted) return;
    _disposeControllers();
    setState(() {
      _devices = _sorted(_unique(results.expand((r) => r.devices)));
      _controllers = {
        for (final device in _devices)
          device: widget.createController(device)..load(),
      };
      _failed = results.where((r) => r.error != null).toList();
      _loading = false;
    });
  }

  /// Устройство, доступное двум аккаунтам, показывается один раз.
  List<Device> _unique(Iterable<Device> devices) {
    final seen = <String>{};
    return devices.where((device) => seen.add(device.did)).toList();
  }

  String _accountLabel(String accountId) =>
      widget.accounts.firstWhere((a) => a.userId == accountId).label;

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  /// Расставляет устройства в сохранённом порядке, новые — в конец.
  List<Device> _sorted(List<Device> devices) {
    final order = widget.prefs.deviceOrder;
    int rank(Device device) {
      final index = order.indexOf(device.did);
      return index < 0 ? order.length : index;
    }

    return devices..sort((a, b) => rank(a).compareTo(rank(b)));
  }

  bool _matches(Device device) =>
      _filter == _allFilter ||
      device.region == _filter ||
      device.accountId == _filter;

  List<Device> get _shown => _devices.where(_matches).toList();

  /// Переставляет плитку среди показанных, не трогая скрытые фильтром.
  void _reorder(int from, int to) {
    final shown = _shown;
    shown.insert(to, shown.removeAt(from));
    setState(() {
      _devices = [
        for (final device in _devices)
          _matches(device) ? shown.removeAt(0) : device,
      ];
    });
    widget.prefs.deviceOrder = [for (final device in _devices) device.did];
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(
            // Снизу — место под стеклянную нижнюю панель на телефоне.
            padding: EdgeInsets.fromLTRB(
              20,
              28,
              20,
              40 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              _Header(devices: _devices, loading: _loading, onRefresh: _reload),
              for (final result in _failed)
                _RegionAlert(
                  result,
                  account: widget.accounts.length > 1
                      ? _accountLabel(result.accountId)
                      : null,
                  onRetry: _reload,
                ),
              const SizedBox(height: 18),
              _FilterChips(
                devices: _devices,
                accounts: widget.accounts,
                selected: _filter,
                onSelected: (filter) => setState(() => _filter = filter),
              ),
              const SizedBox(height: 18),
              _body(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final shown = _shown;
    if (shown.isEmpty) return _EmptyState(loading: _loading);
    return ReorderableGridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      dragStartDelay: _dragStartDelay,
      onReorder: _reorder,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        mainAxisExtent: 156,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: shown.length,
      itemBuilder: (context, index) {
        final controller = _controllers[shown[index]]!;
        final device = controller.device;
        return _Rise(
          key: ValueKey('${device.region}/${device.did}'),
          index: index,
          child: DeviceTile(
            controller: controller,
            onTap: () => showDeviceSheet(context, controller),
          ),
        );
      },
    );
  }

  /// Мышью плитку тянут сразу, пальцем — после удержания.
  Duration get _dragStartDelay {
    const touch = {TargetPlatform.android, TargetPlatform.iOS};
    final isTouch = touch.contains(defaultTargetPlatform);
    return Duration(milliseconds: isTouch ? 400 : 120);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.devices,
    required this.loading,
    required this.onRefresh,
  });

  final List<Device> devices;
  final bool loading;
  final VoidCallback onRefresh;

  String _greeting(AppLocalizations l) {
    final hour = DateTime.now().hour;
    if (hour < 5) return l.greetingNight;
    if (hour < 12) return l.greetingMorning;
    return hour < 18 ? l.greetingDay : l.greetingEvening;
  }

  String _summary(AppLocalizations l) {
    final online = devices.where((d) => d.isOnline).length;
    final regions = devices.map((d) => d.region).toSet().length;
    return l.devicesSummary(online, devices.length, regions);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(l), style: context.display(28)),
              const SizedBox(height: 8),
              Text(_summary(l), style: TextStyle(color: c.muted)),
            ],
          ),
        ),
        IconButton.filled(
          tooltip: l.refreshList,
          style: IconButton.styleFrom(
            backgroundColor: c.tile,
            foregroundColor: c.ink,
            fixedSize: const Size(44, 44),
          ),
          onPressed: loading ? null : onRefresh,
          icon: loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _RegionAlert extends StatelessWidget {
  const _RegionAlert(
    this.result, {
    required this.account,
    required this.onRetry,
  });

  final RegionResult result;

  /// Название аккаунта; `null`, когда аккаунт один и уточнять незачем.
  final String? account;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final region =
        '${l.regionName(result.region)} (${result.region.toUpperCase()})';
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: c.badSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: c.bad),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              [
                region,
                ?account,
                l.regionUnavailable(describeError(l, result.error!)),
              ].join(' · '),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(l.retry)),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.devices,
    required this.accounts,
    required this.selected,
    required this.onSelected,
  });

  final List<Device> devices;
  final List<Session> accounts;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final regions = devices.map((d) => d.region).toSet();
    int count(String region) => devices.where((d) => d.region == region).length;
    int owned(Session account) =>
        devices.where((d) => d.accountId == account.userId).length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children: [
          _chip(_allFilter, context.l10n.filterAll, devices.length),
          for (final region in regions)
            _chip(region, region.toUpperCase(), count(region)),
          if (accounts.length > 1)
            for (final account in accounts)
              _chip(account.userId, account.label, owned(account)),
        ],
      ),
    );
  }

  Widget _chip(String value, String label, int count) => RevealBorder(
    borderRadius: BorderRadius.circular(99),
    child: _FilterChip(
      label: '$label  $count',
      selected: selected == value,
      onTap: () => onSelected(value),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.ink : c.tile,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: selected ? c.bg : c.muted,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 64),
    child: Center(
      child: loading
          ? const CircularProgressIndicator()
          : Text(
              context.l10n.noDevices,
              style: TextStyle(color: context.colors.muted),
            ),
    ),
  );
}

/// Плитка «всплывает» при первом появлении, каждая следующая чуть позже.
class _Rise extends StatelessWidget {
  const _Rise({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 320 + index * 40),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (_, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
    ),
  );
}
