import '../core/accounts/session.dart';
import '../core/cloud/regions.dart';
import '../core/devices/device.dart';
import '../core/devices/device_repository.dart';
import '../core/devices/device_transport.dart';
import '../core/spec/miot_spec.dart';
import '../core/spec/spec_repository.dart';

/// Демо-режим: приложение можно посмотреть без аккаунта Xiaomi.
/// Устройства выдуманы, команды никуда не отправляются.
const demoSession = Session(
  userId: 'demo',
  ssecurity: '',
  serviceToken: '',
  label: 'Демо',
);

/// Выдуманное устройство; имя подставляется на языке интерфейса по [key].
typedef _DemoDevice = ({
  String did,
  String key,
  String model,
  String region,
  bool online,
});

_DemoDevice _device(
  String did,
  String key,
  String model,
  String region, {
  bool online = true,
}) => (did: did, key: key, model: model, region: region, online: online);

Device _build(_DemoDevice demo, String name) => Device(
  did: demo.did,
  model: demo.model,
  name: name,
  region: demo.region,
  accountId: demoSession.userId,
  localIp: demo.online ? '192.168.1.${30 + int.parse(demo.did)}' : '',
  token: '',
  isOnline: demo.online,
  parentId: '',
);

final _devices = [
  _device('1', 'fan', 'dmaker.fan.p44', 'ru'),
  _device('2', 'lamp', 'yeelink.light.bslamp2', 'ru'),
  _device('3', 'humidifier', 'deerma.humidifier.jsq', 'cn'),
  _device('4', 'purifier', 'zhimi.airp.mb4a', 'cn'),
  _device('5', 'plug', 'chuangmi.plug.m3', 'ru'),
  _device('6', 'heater', 'zhimi.heater.mc2', 'cn'),
  _device('7', 'vacuum', 'roborock.vacuum.s5', 'ru', online: false),
];

const _onByDefault = {'1', '2', '4'};

class DemoDeviceRepository implements DeviceRepository {
  DemoDeviceRepository({required this.nameOf});

  /// Имя устройства по его ключу (`fan`, `lamp`…) на языке интерфейса.
  final String Function(String key) nameOf;

  @override
  Duration get timeout => Duration.zero;

  @override
  Future<List<RegionResult>> loadAll([
    List<String> regions = allRegions,
  ]) async => [
    for (final region in regions)
      RegionResult(
        region,
        accountId: demoSession.userId,
        devices: [
          for (final demo in _devices)
            if (demo.region == region) _build(demo, nameOf(demo.key)),
        ],
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
  ) async {
    final state = await _stateOf(device);
    return {
      for (final id in ids)
        if (state.containsKey(id)) id: state[id],
    };
  }

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
    // Ноль в списках значений обычно означает «норма»: «нет ошибки» и т. п.
    final values = property.values.map((option) => option.value);
    if (values.isNotEmpty) return values.contains(0) ? 0 : values.first;
    final range = property.range;
    if (range == null) return null;
    final middle = (range.min + range.max) / 2;
    return property.isFloat ? middle : middle.round();
  }
}
