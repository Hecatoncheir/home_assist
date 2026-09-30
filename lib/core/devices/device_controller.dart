import 'dart:async';

import 'package:flutter/foundation.dart';

import '../spec/miot_spec.dart';
import '../spec/spec_repository.dart';
import 'device.dart';
import 'device_transport.dart';

/// Состояние одного устройства: спецификация, значения свойств и команды.
class DeviceController extends ChangeNotifier {
  DeviceController(this.device, this._specs, this._transport);

  static const _pollInterval = Duration(seconds: 8);

  final Device device;
  final SpecRepository _specs;
  final DeviceTransport _transport;

  MiotSpec? spec;

  /// Стало ли известно, есть ли у модели спецификация.
  bool loaded = false;
  Map<PropertyId, Object?> values = {};

  /// Текст последней ошибки; сбрасывается при следующей удачной операции.
  String? error;

  Timer? _poll;
  bool _disposed = false;

  /// `null`, пока состояние неизвестно или у устройства нет выключателя.
  bool? get isOn => values[spec?.power?.id] as bool?;

  /// Загружает спецификацию и текущее состояние.
  Future<void> load() async {
    await _guard(() async {
      spec = await _specs.forModel(device.model);
      await _read();
    });
    loaded = true;
    _notify();
  }

  Future<void> refresh() => _guard(_read);

  Future<void> toggle() async {
    final power = spec?.power;
    final on = isOn;
    if (power == null || on == null) return;
    await setValue(power, !on);
  }

  /// Значение меняется на экране сразу и откатывается, если команда не прошла.
  Future<void> setValue(MiotProperty property, Object value) async {
    final previous = values[property.id];
    values[property.id] = value;
    _notify();
    await _guard(() => _transport.setProperty(device, property.id, value));
    if (error != null) values[property.id] = previous;
    _notify();
  }

  Future<void> run(MiotAction action) async {
    await _guard(() => _transport.callAction(device, action));
    await refresh();
  }

  /// Пока открыта панель устройства, состояние перечитывается по таймеру.
  void startPolling() {
    _poll ??= Timer.periodic(_pollInterval, (_) => refresh());
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  @override
  void dispose() {
    stopPolling();
    _disposed = true;
    super.dispose();
  }

  Future<void> _read() async {
    final ids = spec?.readableIds ?? const [];
    if (ids.isEmpty || !device.isOnline) return;
    values = await _transport.getProperties(device, ids);
  }

  Future<void> _guard(Future<void> Function() operation) async {
    try {
      await operation();
      error = null;
    } catch (e) {
      error = '$e';
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
