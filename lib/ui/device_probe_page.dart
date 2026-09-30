import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/devices/device_probe.dart';
import '../core/spec/miot_spec.dart';
import 'l10n.dart';
import 'theme.dart';
import 'widgets/home_switch.dart';
import 'widgets/spec_controls.dart';

const _pollInterval = Duration(seconds: 2);
const _maxChanges = 100;

/// Экран исследования: какие свойства отдаёт устройство и как они меняются.
class DeviceProbePage extends StatefulWidget {
  const DeviceProbePage({super.key, required this.probe});

  final DeviceProbe probe;

  @override
  State<DeviceProbePage> createState() => _DeviceProbePageState();
}

class _DeviceProbePageState extends State<DeviceProbePage> {
  ProbeReport? _report;
  Map<PropertyId, Object?> _values = {};
  final _changes = <PropertyChange>[];
  final _changeCounts = <PropertyId, int>{};
  int? _scanningSiid;
  Timer? _watch;
  bool _reading = false;
  Object? _error;

  DeviceProbe get _probe => widget.probe;

  @override
  void dispose() {
    _watch?.cancel();
    super.dispose();
  }

  Future<void> _scan() async {
    _stopWatching();
    setState(() {
      _error = null;
      _changes.clear();
      _changeCounts.clear();
    });
    final report = await _probe.scan(
      onProgress: (siid) {
        if (mounted) setState(() => _scanningSiid = siid);
      },
    );
    if (!mounted) return;
    setState(() {
      _report = report;
      _values = {for (final p in report.properties) p.id: p.value};
      _scanningSiid = null;
    });
  }

  void _toggleWatching(bool on) {
    if (!on) return setState(_stopWatching);
    setState(() => _watch = Timer.periodic(_pollInterval, (_) => _poll()));
  }

  void _stopWatching() {
    _watch?.cancel();
    _watch = null;
  }

  /// Перечитывает найденные свойства и запоминает, что изменилось.
  Future<void> _poll() async {
    if (_reading) return;
    _reading = true;
    try {
      final fresh = await _probe.read(_values.keys);
      if (!mounted) return;
      final changes = DeviceProbe.changes(_values, fresh, DateTime.now());
      setState(() {
        _values = {..._values, ...fresh};
        _error = null;
        _remember(changes);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      _reading = false;
    }
  }

  void _remember(List<PropertyChange> changes) {
    for (final change in changes) {
      _changeCounts[change.id] = (_changeCounts[change.id] ?? 0) + 1;
      _changes.insert(0, change);
    }
    if (_changes.length > _maxChanges) {
      _changes.removeRange(_maxChanges, _changes.length);
    }
  }

  Future<void> _copy() async {
    final l = context.l10n;
    await Clipboard.setData(ClipboardData(text: _reportText(l)));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.probeCopied)));
  }

  String _reportText(AppLocalizations l) {
    final device = _probe.device;
    final properties = _report?.properties ?? const [];
    return [
      l.probeReportTitle(device.name, device.model, device.region),
      '',
      for (final p in properties)
        '${address(p.id)}\t${p.spec?.name ?? l.probeNotInSpec}\t${_values[p.id]}',
      if (_report?.failedServices case final failed? when failed.isNotEmpty)
        l.probeFailedSiids(failed.join(', ')),
      if (_changes.isNotEmpty) ...[
        '',
        '${l.probeChanges}:',
        for (final c in _changes.reversed)
          '${_time(c.at)}\t${address(c.id)}\t${c.from} → ${c.to}',
      ],
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final report = _report;
    final error = _error;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.probeTitle(_probe.device.name)),
        actions: [
          if (report != null)
            IconButton(
              tooltip: l.probeCopy,
              icon: const Icon(Icons.copy_all_outlined),
              onPressed: _copy,
            ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Text(
                l.probeIntro(_probe.maxSiid, _probe.maxPiid),
                style: TextStyle(color: c.muted),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _scanningSiid == null ? _scan : null,
                icon: const Icon(Icons.search),
                label: Text(_scanLabel(l)),
              ),
              if (report != null) ...[
                const SizedBox(height: 8),
                _Summary(report),
                HomeSwitchTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.probeWatch),
                  subtitle: Text(l.probeWatchHint),
                  value: _watch != null,
                  onChanged: _toggleWatching,
                ),
              ],
              if (error != null)
                Text(
                  l.probeReadFailed(describeError(l, error)),
                  style: TextStyle(color: c.bad),
                ),
              if (_changes.isNotEmpty) _ChangeLog(_changes),
              if (report != null)
                for (final property in report.properties)
                  _PropertyRow(
                    property,
                    value: _values[property.id],
                    changes: _changeCounts[property.id] ?? 0,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  String _scanLabel(AppLocalizations l) {
    final siid = _scanningSiid;
    if (siid != null) return l.probeScanning(siid, _probe.maxSiid);
    return _report == null ? l.probeScan : l.probeRescan;
  }
}

String _time(DateTime at) =>
    [at.hour, at.minute, at.second].map((n) => '$n'.padLeft(2, '0')).join(':');

class _Summary extends StatelessWidget {
  const _Summary(this.report);

  final ProbeReport report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final failed = report.failedServices;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        [
          l.probeFound(report.properties.length, report.hiddenCount),
          if (failed.isNotEmpty) l.probeFailedSiids(failed.join(', ')),
        ].join(' '),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ChangeLog extends StatelessWidget {
  const _ChangeLog(this.changes);

  final List<PropertyChange> changes;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8, bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.colors.tile,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.probeChanges,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        for (final change in changes.take(12))
          Text(
            '${_time(change.at)}  ${address(change.id)}  '
            '${change.from} → ${change.to}',
            style: context.mono(color: context.colors.ink),
          ),
      ],
    ),
  );
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow(
    this.property, {
    required this.value,
    required this.changes,
  });

  final ProbedProperty property;
  final Object? value;
  final int changes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spec = property.spec;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(address(property.id), style: context.mono(size: 13)),
          ),
          Expanded(
            child: Text(
              spec?.label ?? context.l10n.probeNotInSpec,
              style: TextStyle(
                color: spec == null ? c.accent : c.ink,
                fontWeight: spec == null ? FontWeight.w700 : null,
              ),
            ),
          ),
          if (changes > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('×$changes', style: context.mono(color: c.glowB)),
            ),
          Flexible(
            child: Text(
              spec == null ? '$value' : formatValue(context.l10n, spec, value),
              textAlign: TextAlign.end,
              style: context.mono(size: 13, color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}
