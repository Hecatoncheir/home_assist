import 'package:flutter/material.dart';

import '../../core/devices/device.dart';
import '../theme.dart';

const _iconsByKeyword = [
  ('fan', Icons.wind_power),
  ('light', Icons.lightbulb_outline),
  ('humidifier', Icons.water_drop_outlined),
  ('airp', Icons.air),
  ('vacuum', Icons.cleaning_services_outlined),
  ('plug', Icons.power_outlined),
  ('sensor', Icons.thermostat),
  ('kettle', Icons.coffee_maker_outlined),
];

/// Значок по названию модели, например `dmaker.fan.p5` → вентилятор.
IconData deviceIcon(Device device) {
  for (final (keyword, icon) in _iconsByKeyword) {
    if (device.model.contains(keyword)) return icon;
  }
  return Icons.devices_other;
}

class DeviceTile extends StatelessWidget {
  const DeviceTile({super.key, required this.device, required this.onTap});

  final Device device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Opacity(
      opacity: device.isOnline ? 1 : .62,
      child: Material(
        color: c.tile,
        borderRadius: tileRadius,
        elevation: 1,
        shadowColor: Colors.black26,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _IconBox(deviceIcon(device)),
                    RegionBadge(device.region),
                  ],
                ),
                _Caption(device),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: context.colors.bg,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, size: 22),
  );
}

class _Caption extends StatelessWidget {
  const _Caption(this.device);

  final Device device;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          device.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, height: 1.25),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            OnlineDot(device.isOnline),
            const SizedBox(width: 6),
            Text(
              device.isOnline ? 'В сети' : 'Не в сети',
              style: TextStyle(fontSize: 13, color: c.muted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          device.model,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.mono(size: 11),
        ),
      ],
    );
  }
}

class OnlineDot extends StatelessWidget {
  const OnlineDot(this.online, {super.key});

  final bool online;

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: online ? context.colors.ok : context.colors.muted,
    ),
  );
}

class RegionBadge extends StatelessWidget {
  const RegionBadge(this.region, {super.key});

  final String region;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      border: Border.all(color: context.colors.muted),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(region.toUpperCase(), style: context.mono(size: 10)),
  );
}
