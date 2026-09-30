import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/devices/device.dart';
import '../../core/devices/device_controller.dart';
import '../theme.dart';

const _iconsByKeyword = [
  ('light', Icons.lightbulb_outline),
  ('humidifier', Icons.water_drop_outlined),
  ('airp', Icons.air),
  ('vacuum', Icons.cleaning_services_outlined),
  ('plug', Icons.power_outlined),
  ('sensor', Icons.thermostat),
  ('kettle', Icons.coffee_maker_outlined),
];

bool isFan(Device device) => device.model.contains('fan');

/// Значок по названию модели, например `yeelink.light.lamp4` → лампа.
IconData _iconFor(Device device) {
  for (final (keyword, icon) in _iconsByKeyword) {
    if (device.model.contains(keyword)) return icon;
  }
  return Icons.devices_other;
}

/// Значок устройства. У вентилятора — лопасти без ножки, чтобы их можно
/// было вращать.
class DeviceIcon extends StatelessWidget {
  const DeviceIcon(this.device, {super.key, required this.size, this.color});

  final Device device;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colors.ink;
    if (!isFan(device)) return Icon(_iconFor(device), size: size, color: color);
    return CustomPaint(size: Size.square(size), painter: _RotorPainter(color));
  }
}

/// Три лопасти вокруг втулки, симметричные относительно центра.
class _RotorPainter extends CustomPainter {
  const _RotorPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7 * unit;
    final blade = Rect.fromCenter(
      center: Offset(0, -5.4 * unit),
      width: 5.2 * unit,
      height: 8.2 * unit,
    );
    canvas.translate(size.width / 2, size.height / 2);
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(blade, paint);
      canvas.rotate(2 * pi / 3);
    }
    canvas.drawCircle(Offset.zero, 1.5 * unit, paint);
  }

  @override
  bool shouldRepaint(_RotorPainter old) => old.color != color;
}

String deviceStatus(DeviceController controller) {
  if (!controller.device.isOnline) return 'Не в сети';
  return switch (controller.isOn) {
    true => 'Включено',
    false => 'Выключено',
    null => 'В сети',
  };
}

/// Плитка устройства. Включённое устройство светится тёплым.
class DeviceTile extends StatelessWidget {
  const DeviceTile({super.key, required this.controller, required this.onTap});

  final DeviceController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: controller, builder: _build);

  Widget _build(BuildContext context, Widget? _) {
    final c = context.colors;
    final device = controller.device;
    final on = controller.isOn;
    final lit = on == true;
    final ink = lit ? c.glowInk : c.ink;
    final shadow = lit ? c.glowB.withValues(alpha: .35) : Colors.black12;
    return Opacity(
      opacity: device.isOnline ? 1 : .62,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.tile,
          gradient: lit ? c.glow : null,
          borderRadius: tileRadius,
          boxShadow: [
            BoxShadow(
              color: shadow,
              blurRadius: lit ? 26 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          textStyle: TextStyle(color: ink),
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
                      _IconBox(device, lit: lit),
                      if (on != null)
                        Switch(
                          value: on,
                          onChanged: (_) => controller.toggle(),
                        ),
                    ],
                  ),
                  _Caption(
                    device: device,
                    status: deviceStatus(controller),
                    muted: lit ? ink.withValues(alpha: .75) : c.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox(this.device, {required this.lit});

  final Device device;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: lit ? Colors.white.withValues(alpha: .45) : c.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: DeviceIcon(device, size: 22, color: lit ? c.glowInk : c.ink),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({
    required this.device,
    required this.status,
    required this.muted,
  });

  final Device device;
  final String status;
  final Color muted;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        device.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, height: 1.25),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          OnlineDot(device.isOnline),
          const SizedBox(width: 6),
          Expanded(
            child: Text(status, style: TextStyle(fontSize: 13, color: muted)),
          ),
          RegionBadge(device.region, color: muted),
        ],
      ),
    ],
  );
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
  const RegionBadge(this.region, {super.key, this.color});

  final String region;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        region.toUpperCase(),
        style: context.mono(size: 10, color: color),
      ),
    );
  }
}
