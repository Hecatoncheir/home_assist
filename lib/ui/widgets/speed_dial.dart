import 'package:flutter/material.dart';

import '../../core/devices/device_controller.dart';
import '../../core/spec/miot_spec.dart';
import '../theme.dart';
import 'gauge.dart';

const _geometry = GaugeGeometry(220);

/// Регулятор скорости в том же стиле, что и направление: деления горят
/// до текущей скорости, «−» и «+» у краёв дуги, по дуге можно вести пальцем.
/// Подходит и для списка значений (1–4), и для диапазона (1–100).
class SpeedDial extends StatefulWidget {
  const SpeedDial({
    super.key,
    required this.property,
    required this.controller,
  });

  final MiotProperty property;
  final DeviceController controller;

  @override
  State<SpeedDial> createState() => _SpeedDialState();
}

class _SpeedDialState extends State<SpeedDial> {
  /// Доля 0…1, пока ведут пальцем.
  double? _dragging;

  _Steps get _steps => _Steps(widget.property);

  /// Устройство может прислать что угодно — берём только число.
  num? get _value {
    final value = widget.controller.values[widget.property.id];
    return value is num ? value : null;
  }

  void _set(num value) => widget.controller.setValue(widget.property, value);

  void _release() {
    final at = _dragging;
    setState(() => _dragging = null);
    if (at != null) _set(_steps.valueAt(at));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final steps = _steps;
    final value = _dragging == null ? _value : steps.valueAt(_dragging!);
    final fraction = value == null ? null : steps.fractionOf(value);
    return Center(
      child: GaugeLayout(
        geometry: _geometry,
        ring: GaugeRingPainter(
          geometry: _geometry,
          colors: c,
          ticks: steps.ticks,
          intensity: (at) => fraction != null && at <= fraction + 1e-6 ? 1 : 0,
        ),
        knob: GaugeKnob(
          geometry: _geometry,
          marker: fraction,
          child: _Face(text: value == null ? '—' : steps.label(value)),
        ),
        left: GaugeButton(
          icon: Icons.remove,
          tooltip: 'Медленнее',
          onPressed: value == null || value <= steps.min
              ? null
              : () => _set(steps.previous(value)),
        ),
        right: GaugeButton(
          icon: Icons.add,
          tooltip: 'Быстрее',
          onPressed: value == null || value >= steps.max
              ? null
              : () => _set(steps.next(value)),
        ),
        onAim: (at) => setState(() => _dragging = at),
        onRelease: _release,
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.air, size: 22, color: c.glowB),
        const SizedBox(height: 4),
        Text(text, style: context.display(30)),
        Text('скорость', style: TextStyle(color: c.muted, fontSize: 12)),
      ],
    );
  }
}

/// Допустимые значения свойства и переходы между ними.
class _Steps {
  _Steps(this.property);

  final MiotProperty property;

  List<int> get _options => [for (final o in property.values) o.value];
  MiotRange? get _range => property.range;

  num get min => _options.isNotEmpty ? _options.first : _range!.min;
  num get max => _options.isNotEmpty ? _options.last : _range!.max;

  /// Шаг «−/+» у диапазона: не мельче десятой части.
  num get _step {
    final range = _range!;
    final tenth = (range.max - range.min) / 10;
    return range.step >= tenth ? range.step : tenth.ceil();
  }

  int get ticks => _options.isNotEmpty ? (_options.length - 1) * 8 : 36;

  double fractionOf(num value) {
    if (max == min) return 1;
    final options = _options;
    if (options.isEmpty) return ((value - min) / (max - min)).clamp(0.0, 1.0);
    final index = options.indexOf(value.toInt());
    return index < 0 ? 0 : index / (options.length - 1);
  }

  num valueAt(double at) {
    final options = _options;
    if (options.isNotEmpty) {
      return options[(at * (options.length - 1)).round()];
    }
    final raw = min + at * (max - min);
    final step = _range!.step;
    final snapped = step > 0 ? (raw / step).round() * step : raw;
    return property.isFloat ? snapped : snapped.round();
  }

  num next(num value) => _shift(value, 1);
  num previous(num value) => _shift(value, -1);

  num _shift(num value, int direction) {
    final options = _options;
    if (options.isEmpty) {
      return (value + direction * _step).clamp(min, max);
    }
    final index = options.indexOf(value.toInt()) + direction;
    return options[index.clamp(0, options.length - 1)];
  }

  String label(num value) =>
      _options.isEmpty && property.unit == 'percentage' ? '$value%' : '$value';
}
