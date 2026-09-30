import '../cloud/mi_cloud_client.dart';
import '../spec/miot_spec.dart';
import 'device.dart';

/// Канал связи с устройством. Облако и локальная сеть реализуют его одинаково.
abstract interface class DeviceTransport {
  /// Свойства, которые устройство не отдало, в ответ не попадают.
  Future<Map<PropertyId, Object?>> getProperties(
    Device device,
    List<PropertyId> ids,
  );

  Future<void> setProperty(Device device, PropertyId id, Object value);

  Future<void> callAction(Device device, MiotAction action);
}

/// Управление через облако. Запрос уходит на сервер региона устройства.
class CloudTransport implements DeviceTransport {
  CloudTransport(this._cloud);

  final MiCloudClient _cloud;

  @override
  Future<Map<PropertyId, Object?>> getProperties(
    Device device,
    List<PropertyId> ids,
  ) async {
    final result = await _cloud.call(device.region, '/miotspec/prop/get', {
      'params': [
        for (final id in ids)
          {'did': device.did, 'siid': id.siid, 'piid': id.piid},
      ],
    });
    return {
      for (final item in result as List)
        if (item['code'] == 0)
          (siid: item['siid'] as int, piid: item['piid'] as int): item['value'],
    };
  }

  @override
  Future<void> setProperty(Device device, PropertyId id, Object value) async {
    final result = await _cloud.call(device.region, '/miotspec/prop/set', {
      'params': [
        {'did': device.did, 'siid': id.siid, 'piid': id.piid, 'value': value},
      ],
    });
    _check((result as List).first['code']);
  }

  @override
  Future<void> callAction(Device device, MiotAction action) async {
    final result = await _cloud.call(device.region, '/miotspec/action', {
      'params': {
        'did': device.did,
        'siid': action.siid,
        'aiid': action.aiid,
        'in': const <Object>[],
      },
    });
    _check(result['code']);
  }

  void _check(Object? code) {
    if (code != 0) throw CloudException('Устройство отклонило команду ($code)');
  }
}
