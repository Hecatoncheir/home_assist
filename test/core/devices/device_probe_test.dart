import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/core/devices/device.dart';
import 'package:home_assist/core/devices/device_probe.dart';
import 'package:home_assist/core/devices/device_transport.dart';
import 'package:home_assist/core/spec/miot_spec.dart';

import '../../support/fake_cloud.dart';

const _fan = Device(
  did: '1',
  model: 'dmaker.fan.p44',
  name: 'Вентилятор',
  region: 'ru',
  accountId: '42',
  localIp: '',
  token: '',
  isOnline: true,
  parentId: '',
);

/// Устройство отвечает на три свойства: два из спецификации и одно скрытое.
/// Сервис 9 целиком отвечает ошибкой.
final _values = <String, Object>{'2.1': true, '2.3': 1, '2.5': 60};

Object? _respond(CloudCall call) {
  final params = call.data['params'] as List;
  if (params.first['siid'] == 9) return null;
  return [
    for (final param in params)
      {
        ...param as Map<String, dynamic>,
        ..._answer('${param['siid']}.${param['piid']}'),
      },
  ];
}

Map<String, Object> _answer(String address) {
  final value = _values[address];
  return value == null ? {'code': -4003} : {'code': 0, 'value': value};
}

void main() {
  final spec = MiotSpec.fromJson(
    jsonDecode(
      File('test/fixtures/spec/dmaker.fan.p44.json').readAsStringSync(),
    ) as Map<String, dynamic>,
  );
  final probe = DeviceProbe(
    device: _fan,
    spec: spec,
    transport: CloudTransport(fakeCloud(_respond)),
  );

  test('находит свойства, которых нет в спецификации', () async {
    final report = await probe.scan();

    expect(report.properties.map((p) => address(p.id)), ['2.1', '2.3', '2.5']);
    expect(report.properties.first.spec?.name, 'on');
    expect(report.properties.last.hidden, isTrue);
    expect(report.properties.last.value, 60);
    expect(report.hiddenCount, 1);
    expect(report.failedServices, [9]);
  });

  test('сообщает об изменившихся значениях', () {
    const angle = (siid: 2, piid: 5);
    const power = (siid: 2, piid: 1);
    final at = DateTime(2026);

    final changes = DeviceProbe.changes(
      {angle: 60, power: true},
      {angle: 90, power: true},
      at,
    );

    expect(changes.single.id, angle);
    expect(changes.single.from, 60);
    expect(changes.single.to, 90);
  });
}
