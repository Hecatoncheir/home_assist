import 'package:flutter/material.dart';

import '../core/cloud/regions.dart';
import '../core/devices/device_controller.dart';
import 'theme.dart';
import 'widgets/device_tile.dart';
import 'widgets/spec_controls.dart';

/// Панель устройства: снизу на узком экране, справа на широком.
Future<void> showDeviceSheet(
  BuildContext context,
  DeviceController controller,
) {
  final wide = MediaQuery.sizeOf(context).width >= 720;
  if (!wide) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      builder: (_) => SafeArea(child: _DeviceDetails(controller)),
    );
  }
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Закрыть',
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) => _SidePanel(child: _DeviceDetails(controller)),
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

class _DeviceDetails extends StatefulWidget {
  const _DeviceDetails(this.controller);

  final DeviceController controller;

  @override
  State<_DeviceDetails> createState() => _DeviceDetailsState();
}

class _DeviceDetailsState extends State<_DeviceDetails> {
  DeviceController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller
      ..refresh()
      ..startPolling();
  }

  @override
  void dispose() {
    _controller.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: _controller, builder: _build);

  Widget _build(BuildContext context, Widget? _) {
    final c = context.colors;
    final device = _controller.device;
    final error = _controller.error;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          Center(child: _PowerButton(_controller)),
          const SizedBox(height: 14),
          Text(
            deviceStatus(_controller),
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(error, style: TextStyle(color: c.bad)),
            ),
          _controls(context),
          Divider(color: c.line, height: 32),
          _InfoRow('Модель', device.model),
          _InfoRow('DID', device.did),
          _InfoRow(
            'Регион',
            '${regionNames[device.region]} · ${device.region}',
          ),
          _InfoRow('IP', device.localIp.isEmpty ? '—' : device.localIp),
        ],
      ),
    );
  }

  Widget _controls(BuildContext context) {
    final spec = _controller.spec;
    if (spec == null) return _Note(_missingSpecText);
    final enabled = _controller.device.isOnline;
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : .45,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final service in spec.controls)
              ServiceSection(service: service, controller: _controller),
          ],
        ),
      ),
    );
  }

  String get _missingSpecText => _controller.loaded
      ? 'Для этой модели нет опубликованной спецификации, '
            'поэтому управлять ею пока нельзя.'
      : 'Загружаем описание устройства…';
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: context.colors.muted, fontSize: 13),
    ),
  );
}

/// Круглая кнопка питания: светится, когда устройство включено.
class _PowerButton extends StatelessWidget {
  const _PowerButton(this.controller);

  final DeviceController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final on = controller.isOn;
    final lit = on == true;
    final icon = deviceIcon(controller.device);
    return GestureDetector(
      onTap: on == null ? null : controller.toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 148,
        height: 148,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.tile,
          gradient: lit ? c.glow : null,
          boxShadow: [
            BoxShadow(
              color: lit ? c.glowB.withValues(alpha: .4) : Colors.black12,
              blurRadius: lit ? 40 : 8,
              spreadRadius: lit ? 6 : 0,
            ),
          ],
        ),
        child: _Spinning(
          active: lit && icon == Icons.wind_power,
          child: Icon(icon, size: 72, color: lit ? c.glowInk : c.muted),
        ),
      ),
    );
  }
}

/// Вращает значок, пока устройство работает (лопасти вентилятора).
class _Spinning extends StatefulWidget {
  const _Spinning({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_Spinning> createState() => _SpinningState();
}

class _SpinningState extends State<_Spinning>
    with SingleTickerProviderStateMixin {
  late final _rotation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Spinning old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() => widget.active ? _rotation.repeat() : _rotation.stop();

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RotationTransition(turns: _rotation, child: widget.child);
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
