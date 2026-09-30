import 'package:flutter/material.dart';

import '../../core/devices/device_controller.dart';
import '../../core/spec/miot_spec.dart';
import '../theme.dart';

const _units = {
  'percentage': ' %',
  'celsius': ' °C',
  'kelvin': ' K',
  'seconds': ' с',
  'minutes': ' мин',
  'hours': ' ч',
  'watt': ' Вт',
  'lux': ' лк',
  'ppm': ' ppm',
};

String formatValue(MiotProperty property, Object? value) {
  if (value == null) return '—';
  if (value is bool) return value ? 'Да' : 'Нет';
  for (final option in property.values) {
    if (option.value == value) return option.label;
  }
  return '$value${_units[property.unit] ?? ''}';
}

/// Элементы управления одного сервиса, построенные по спецификации:
/// `bool` → переключатель, список значений → выбор, диапазон → ползунок,
/// только чтение → строка значения, действие → кнопка.
class ServiceSection extends StatelessWidget {
  const ServiceSection({
    super.key,
    required this.service,
    required this.controller,
  });

  final MiotService service;
  final DeviceController controller;

  @override
  Widget build(BuildContext context) {
    final power = controller.spec?.power;
    final controls = [
      for (final property in service.properties)
        if (property.readable && property != power) _control(property),
      for (final action in service.actions)
        if (!action.hasInputs) _actionButton(action),
    ];
    if (controls.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(color: context.colors.line, height: 32),
        Text(
          service.description.toUpperCase(),
          style: context
              .display(11, weight: FontWeight.w500)
              .copyWith(color: context.colors.muted, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        ...controls,
      ],
    );
  }

  Widget _control(MiotProperty property) {
    final value = controller.values[property.id];
    if (!property.writable) return _ValueRow(property, value);
    if (property.format == 'bool') return _switch(property, value);
    if (property.values.isNotEmpty) return _choice(property, value);
    if (property.range != null) {
      return _RangeControl(property, value, controller);
    }
    return _ValueRow(property, value);
  }

  Widget _switch(MiotProperty property, Object? value) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(property.description),
    value: value == true,
    onChanged: (on) => controller.setValue(property, on),
  );

  Widget _choice(MiotProperty property, Object? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(property.description),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final option in property.values)
              ChoiceChip(
                label: Text(option.label),
                selected: option.value == value,
                onSelected: (_) => controller.setValue(property, option.value),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _actionButton(MiotAction action) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: OutlinedButton(
      onPressed: () => controller.run(action),
      child: Text(action.description),
    ),
  );
}

class _ValueRow extends StatelessWidget {
  const _ValueRow(this.property, this.value);

  final MiotProperty property;
  final Object? value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(child: Text(property.description)),
        Text(formatValue(property, value), style: context.mono(size: 13)),
      ],
    ),
  );
}

/// Ползунок: команда уходит, когда пользователь отпускает палец.
class _RangeControl extends StatefulWidget {
  const _RangeControl(this.property, this.value, this.controller);

  final MiotProperty property;
  final Object? value;
  final DeviceController controller;

  @override
  State<_RangeControl> createState() => _RangeControlState();
}

class _RangeControlState extends State<_RangeControl> {
  double? _dragging;

  MiotProperty get _property => widget.property;
  MiotRange get _range => _property.range!;

  num _typed(double value) => _property.isFloat ? value : value.round();

  int? get _divisions {
    if (_range.step <= 0) return null;
    final count = ((_range.max - _range.min) / _range.step).round();
    return count > 0 && count <= 200 ? count : null;
  }

  void _send(double value) {
    setState(() => _dragging = null);
    widget.controller.setValue(_property, _typed(value));
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.value is num ? widget.value as num : _range.min;
    final value = (_dragging ?? current).clamp(_range.min, _range.max);
    return Column(
      children: [
        _ValueRow(_property, _typed(value.toDouble())),
        Slider(
          min: _range.min.toDouble(),
          max: _range.max.toDouble(),
          divisions: _divisions,
          value: value.toDouble(),
          onChanged: (v) => setState(() => _dragging = v),
          onChangeEnd: _send,
        ),
      ],
    );
  }
}
