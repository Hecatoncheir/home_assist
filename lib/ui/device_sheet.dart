import 'package:flutter/material.dart';

import '../core/cloud/regions.dart';
import '../core/devices/device.dart';
import 'theme.dart';
import 'widgets/device_tile.dart';

/// Панель устройства: снизу на узком экране, справа на широком.
Future<void> showDeviceSheet(BuildContext context, Device device) {
  final wide = MediaQuery.sizeOf(context).width >= 720;
  if (!wide) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (_) => SafeArea(child: _DeviceDetails(device)),
    );
  }
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Закрыть',
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) => _SidePanel(child: _DeviceDetails(device)),
    transitionBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Material(
      color: context.colors.surface,
      child: SizedBox(width: 420, height: double.infinity, child: child),
    ),
  );
}

class _DeviceDetails extends StatelessWidget {
  const _DeviceDetails(this.device);

  final Device device;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final region = '${regionNames[device.region]} · ${device.region}';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  device.name,
                  style: context.display(17, weight: FontWeight.w500),
                ),
              ),
              IconButton(
                tooltip: 'Закрыть',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Emblem(device),
          const SizedBox(height: 14),
          Text(
            device.isOnline ? 'В сети' : 'Не в сети',
            style: TextStyle(color: c.muted),
          ),
          const SizedBox(height: 20),
          Divider(color: c.line),
          _InfoRow('Модель', device.model),
          _InfoRow('DID', device.did),
          _InfoRow('Регион', region),
          _InfoRow('IP', device.localIp.isEmpty ? '—' : device.localIp),
          Divider(color: c.line),
          const SizedBox(height: 8),
          Text(
            'Управление появится, когда приложение научится читать '
            'спецификацию устройства.',
            style: TextStyle(color: c.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Круг со значком: светится, когда устройство в сети.
class _Emblem extends StatelessWidget {
  const _Emblem(this.device);

  final Device device;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lit = device.isOnline;
    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.tile,
        gradient: lit ? c.glow : null,
        boxShadow: [
          if (lit)
            BoxShadow(color: c.glowB.withValues(alpha: .35), blurRadius: 36),
        ],
      ),
      child: Icon(
        deviceIcon(device),
        size: 72,
        color: lit ? c.glowInk : c.muted,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text(label, style: context.mono()),
        const SizedBox(width: 16),
        Expanded(
          child: SelectableText(
            value,
            textAlign: TextAlign.end,
            style: context.mono(color: context.colors.ink),
          ),
        ),
      ],
    ),
  );
}
