import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/core/devices/device.dart';
import 'package:home_assist/core/devices/device_controller.dart';
import 'package:home_assist/core/devices/device_transport.dart';
import 'package:home_assist/core/spec/spec_repository.dart';

import '../../support/fake_cloud.dart';

const _fan = Device(
  did: '1',
  model: 'dmaker.fan.p5',
  name: 'Вентилятор',
  region: 'ru',
  accountId: '42',
  localIp: '',
  token: '',
  isOnline: true,
  parentId: '',
);

void main() {
  late Directory cacheDir;
  late List<CloudCall> calls;
  var setCode = 0;

  /// Фейковое устройство: всё выключено, команды принимает с кодом [setCode].
  Object? respond(CloudCall call) {
    if (call.path == '/miotspec/prop/set') {
      return [
        {'code': setCode},
      ];
    }
    return [
      for (final param in call.data['params'] as List)
        {...param as Map<String, dynamic>, 'code': 0, 'value': false},
    ];
  }

  Future<DeviceController> loadedController() async {
    final controller = DeviceController(
      _fan,
      SpecRepository(cacheDir: cacheDir),
      CloudTransport(fakeCloud(respond, calls: calls)),
    );
    await controller.load();
    return controller;
  }

  setUp(() {
    cacheDir = Directory.systemTemp.createTempSync('specs');
    File('${cacheDir.path}/spec/dmaker.fan.p5.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        File('test/fixtures/spec/dmaker.fan.p5.json').readAsStringSync(),
      );
    calls = [];
    setCode = 0;
  });
  tearDown(() => cacheDir.deleteSync(recursive: true));

  test('читает состояние с сервера региона устройства', () async {
    final controller = await loadedController();

    expect(controller.isOn, isFalse);
    expect(calls.single.host, 'ru.api.io.mi.com');
    expect(calls.single.path, '/miotspec/prop/get');
  });

  test('toggle включает устройство', () async {
    final controller = await loadedController();
    await controller.toggle();

    expect(controller.isOn, isTrue);
    expect(calls.last.data['params'], [
      {'did': '1', 'siid': 2, 'piid': 1, 'value': true},
    ]);
  });

  test('отказ устройства откатывает значение и показывает ошибку', () async {
    final controller = await loadedController();
    setCode = -704042011;
    await controller.toggle();

    expect(controller.isOn, isFalse);
    expect(controller.error, contains('отклонило'));
  });
}
