import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../core/cloud/regions.dart';
import '../core/devices/device.dart';
import '../core/devices/device_repository.dart';
import '../core/preferences.dart';
import 'device_sheet.dart';
import 'theme.dart';
import 'widgets/device_tile.dart';

const _allFilter = 'all';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key, required this.repository, required this.prefs});

  final DeviceRepository repository;
  final Preferences prefs;

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List<Device> _devices = const [];
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
    final results = await widget.repository.loadAll(widget.prefs.regions);
    if (!mounted) return;
    setState(() {
      _devices = _sorted(results.expand((r) => r.devices).toList());
      _failed = results.where((r) => r.error != null).toList();
      _loading = false;
    });
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
      _filter == _allFilter || device.region == _filter;

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
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
            children: [
              _Header(devices: _devices, loading: _loading, onRefresh: _reload),
              for (final result in _failed)
                _RegionAlert(result, onRetry: _reload),
              const SizedBox(height: 18),
              _RegionChips(
                devices: _devices,
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
        final device = shown[index];
        return _Rise(
          key: ValueKey('${device.region}/${device.did}'),
          index: index,
          child: DeviceTile(
            device: device,
            onTap: () => showDeviceSheet(context, device),
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

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Доброй ночи';
    if (hour < 12) return 'Доброе утро';
    return hour < 18 ? 'Добрый день' : 'Добрый вечер';
  }

  String get _summary {
    final online = devices.where((d) => d.isOnline).length;
    final regions = devices.map((d) => d.region).toSet().length;
    return 'В сети $online из ${devices.length} · регионов: $regions';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting, style: context.display(28)),
              const SizedBox(height: 8),
              Text(_summary, style: TextStyle(color: c.muted)),
            ],
          ),
        ),
        IconButton.filled(
          tooltip: 'Обновить список',
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
  const _RegionAlert(this.result, {required this.onRetry});

  final RegionResult result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final region =
        '${regionNames[result.region]} (${result.region.toUpperCase()})';
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
          Expanded(child: Text('$region недоступен: ${result.error}')),
          TextButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

class _RegionChips extends StatelessWidget {
  const _RegionChips({
    required this.devices,
    required this.selected,
    required this.onSelected,
  });

  final List<Device> devices;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final regions = devices.map((d) => d.region).toSet();
    int count(String region) => devices.where((d) => d.region == region).length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children: [
          _chip(_allFilter, 'Все', devices.length),
          for (final region in regions)
            _chip(region, region.toUpperCase(), count(region)),
        ],
      ),
    );
  }

  Widget _chip(String value, String label, int count) => _FilterChip(
    label: '$label  $count',
    selected: selected == value,
    onTap: () => onSelected(value),
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
              'Устройства не найдены',
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
