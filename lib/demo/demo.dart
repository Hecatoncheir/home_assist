import '../core/accounts/session.dart';
import '../core/cloud/regions.dart';
import '../core/devices/device.dart';
import '../core/devices/device_repository.dart';
import '../core/devices/device_transport.dart';
import '../core/spec/miot_spec.dart';
import '../core/spec/spec_repository.dart';

/// Демо-режим: приложение можно посмотреть без аккаунта Xiaomi.
/// Устройства выдуманы, команды никуда не отправляются.
const demoSession = Session(userId: 'demo', ssecurity: '', serviceToken: '');

Device _device(
  String did,
  String name,
  String model,
  String region, {
  bool online = true,
}) => Device(
  did: did,
  model: model,
  name: name,
  region: region,
  accountId: demoSession.userId,
  localIp: online ? '192.168.1.${30 + int.parse(did)}' : '',
  token: '',
  isOnline: online,
  parentId: '',
);

final _devices = [
  _device('1', 'Вентилятор', 'dmaker.fan.p5', 'ru'),
  _device('2', 'Лампа у кровати', 'yeelink.light.bslamp2', 'ru'),
  _device('3', 'Увлажнитель', 'deerma.humidifier.jsq', 'cn'),
  _device('4', 'Очиститель воздуха', 'zhimi.airp.mb4a', 'cn'),
  _device('5', 'Розетка у стола', 'chuangmi.plug.m3', 'ru'),
  _device('6', 'Обогреватель', 'zhimi.heater.mc2', 'cn'),
  _device('7', 'Робот-пылесос', 'roborock.vacuum.s5', 'ru', online: false),
];

const _onByDefault = {'1', '2', '4'};

class DemoDeviceRepository implements DeviceRepository {
  @override
  Duration get timeout => Duration.zero;

  @override
  Future<List<RegionResult>> loadAll([
    List<String> regions = allRegions,
  ]) async => [
    for (final region in regions)
      RegionResult(
        region,
        devices: _devices.where((d) => d.region == region).toList(),
      ),
  ];
}

/// Хранит состояние устройств в памяти вместо настоящих команд.
class DemoTransport implements DeviceTransport {
  DemoTransport(this._specs);

  final SpecRepository _specs;
  final _state = <String, Map<PropertyId, Object?>>{};

  @override
  Future<Map<PropertyId, Object?>> getProperties(
    Device device,
    List<PropertyId> ids,
  ) async => {...await _stateOf(device)};

  @override
  Future<void> setProperty(Device device, PropertyId id, Object value) async {
    (await _stateOf(device))[id] = value;
  }

  @override
  Future<void> callAction(Device device, MiotAction action) async {}

  Future<Map<PropertyId, Object?>> _stateOf(Device device) async =>
      _state[device.did] ??= _initialState(
        await _specs.forModel(device.model),
        _onByDefault.contains(device.did),
      );

  Map<PropertyId, Object?> _initialState(MiotSpec? spec, bool on) {
    if (spec == null) return {};
    final properties = spec.controls.expand((service) => service.properties);
    return {
      for (final property in properties)
        if (property.readable) property.id: _initialValue(property),
      if (spec.power case final power?) power.id: on,
    };
  }

  Object? _initialValue(MiotProperty property) {
    if (property.format == 'bool') return false;
    if (property.values.isNotEmpty) return property.values.first.value;
    final range = property.range;
    if (range == null) return null;
    final middle = (range.min + range.max) / 2;
    return property.isFloat ? middle : middle.round();
  }
}
