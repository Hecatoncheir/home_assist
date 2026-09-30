import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/core/devices/device.dart';
import 'package:home_assist/core/devices/device_controller.dart';
import 'package:home_assist/core/devices/device_transport.dart';
import 'package:home_assist/core/devices/swing_controller.dart';
import 'package:home_assist/core/spec/miot_spec.dart';
import 'package:home_assist/core/spec/spec_repository.dart';

const _fan = Device(
  did: '1',
  model: 'dmaker.fan.p44',
  name: 'Вентилятор',
  region: 'cn',
  accountId: 'demo',
  localIp: '',
  token: '',
  isOnline: true,
  parentId: '',
);

const _swingId = (siid: 2, piid: 4);

/// Устройство в памяти: команды выполняются сразу.
class _Transport implements DeviceTransport {
  final values = <PropertyId, Object?>{};

  @override
  Future<Map<PropertyId, Object?>> getProperties(
    Device device,
    List<PropertyId> ids,
  ) async => {...values};

  @override
  Future<void> setProperty(Device device, PropertyId id, Object value) async =>
      values[id] = value;

  @override
  Future<void> callAction(Device device, MiotAction action) async {}
}

class _Memory implements SwingCalibrations {
  final saved = <String, Duration>{};

  @override
  Duration? swingSweep(String did) => saved[did];

  @override
  void saveSwingSweep(String did, Duration sweep) => saved[did] = sweep;

  final states = <String, SwingSnapshot?>{};
  final dwells = <String, Duration>{};

  @override
  Duration? swingDwell(String did) => dwells[did];

  @override
  void saveSwingDwell(String did, Duration dwell) => dwells[did] = dwell;

  @override
  SwingSnapshot? swingState(String did) => states[did];

  @override
  void saveSwingState(String did, SwingSnapshot? state) => states[did] = state;
}

void main() {
  final spec = MiotSpec.fromJson(
    jsonDecode(
      File('test/fixtures/spec/dmaker.fan.p44.json').readAsStringSync(),
    ) as Map<String, dynamic>,
  );

  ({DeviceController device, SwingController swing, _Transport transport})
  setUp(FakeAsync async, {SwingCalibrations? memory}) {
    final transport = _Transport();
    final device = DeviceController(
      _fan,
      SpecRepository(cacheDir: Directory('test/fixtures')),
      transport,
    )..spec = spec;
    final swing = SwingController(
      device,
      calibrations: memory,
      clock: () => async.getClock(DateTime(2026)).now(),
    );
    return (device: device, swing: swing, transport: transport);
  }

  /// Калибровка по схеме «кнопка = вентилятор стоит у этого края»:
  /// отметили край [from], вентилятор за [sweep] дошёл до другого края,
  /// постоял там [dwell] и тронулся обратно — к [from].
  void markPass(
    FakeAsync async,
    SwingController swing, {
    required int from,
    required Duration sweep,
    Duration dwell = Duration.zero,
  }) {
    swing.holdStart(from);
    async.elapse(dwell);
    swing.holdEnd();
    async.elapse(sweep);
    swing.holdStart(1 - from);
    async.elapse(dwell);
    swing.holdEnd();
  }

  test('калибровка, поворот к цели и остановка качания', () {
    fakeAsync((async) {
      final memory = _Memory();
      final (:device, :swing, :transport) = setUp(async, memory: memory);

      expect(swing.supported, isTrue);
      expect(swing.position, isNull);

      // От нижнего края до верхнего 8 с; сейчас тронулся от верхнего вниз.
      markPass(async, swing, from: 0, sweep: const Duration(seconds: 8));

      expect(swing.sweep, const Duration(seconds: 8));
      expect(memory.saved['1'], const Duration(seconds: 8));
      expect(swing.position, closeTo(1, 1e-9));

      // До середины 4 с; команда остановки уходит чуть раньше —
      // с поправкой на задержку.
      swing.moveTo(.5);
      async.elapse(const Duration(seconds: 5));

      expect(transport.values[_swingId], isFalse);
      expect(device.values[_swingId], isFalse);
      expect(swing.moving, isFalse);
      expect(swing.target, isNull);
      expect(swing.position, closeTo(.5, .05));
    });
  });

  /// Проход 10 с, вентилятор тронулся от нижнего края вверх,
  /// затем остановка около 0.2.
  void calibrateAndStopAt02(FakeAsync async, SwingController swing) {
    markPass(async, swing, from: 1, sweep: const Duration(seconds: 10));
    swing.moveTo(.2);
    async.elapse(const Duration(seconds: 3));
    expect(swing.moving, isFalse);
  }

  test('после долгой паузы вентилятор разворачивается', () {
    fakeAsync((async) {
      final (:device, :swing, :transport) = setUp(async);
      calibrateAndStopAt02(async, swing);
      async.elapse(const Duration(seconds: 10));

      // Пауза дольше порога: пойдёт вниз, до 0.1 — около секунды.
      swing.moveTo(.1);
      async.flushMicrotasks();
      expect(transport.values[_swingId], isTrue);
      async.elapse(const Duration(seconds: 2));

      expect(transport.values[_swingId], isFalse);
      expect(swing.position, closeTo(.1, .05));
    });
  });

  test('после короткой паузы продолжает в ту же сторону', () {
    fakeAsync((async) {
      final (:device, :swing, :transport) = setUp(async);
      calibrateAndStopAt02(async, swing);

      // Пауза короче порога: продолжит вверх, до 0.5 — около 3 с.
      swing.moveTo(.5);
      async.elapse(const Duration(seconds: 4));

      expect(transport.values[_swingId], isFalse);
      expect(swing.position, closeTo(.5, .05));
    });
  });

  test('«не туда» разворачивает расчёт и уточняет порог паузы', () {
    fakeAsync((async) {
      final (:device, :swing, :transport) = setUp(async);
      calibrateAndStopAt02(async, swing);
      async.elapse(const Duration(seconds: 2));

      // Приложение ждёт движения вверх, а вентилятор пошёл вниз.
      swing.moveTo(.1);
      async.elapse(const Duration(milliseconds: 300));
      swing.retry();

      // Пауза была ~3.3 с, а разворот случился: порог стал не больше неё.
      expect(swing.reverseAfter, lessThan(const Duration(milliseconds: 3500)));
      async.elapse(const Duration(seconds: 2));
      expect(transport.values[_swingId], isFalse);
      expect(swing.position, closeTo(.1, .05));
    });
  });

  test('«не туда» после остановки пересчитывает место и едет к цели', () {
    fakeAsync((async) {
      final (:device, :swing, :transport) = setUp(async);
      calibrateAndStopAt02(async, swing);
      async.elapse(const Duration(seconds: 2));

      // Ждали движения вверх до 0.5, а вентилятор 3 с шёл вниз:
      // от 0.2 до нижнего края и обратно до 0.1.
      swing.moveTo(.5);
      async.elapse(const Duration(seconds: 4));
      expect(swing.moving, isFalse);
      expect(swing.canRetry, isTrue);

      swing.retry();
      async.flushMicrotasks();
      expect(swing.target, .5);
      expect(transport.values[_swingId], isTrue);

      async.elapse(const Duration(seconds: 20));
      expect(transport.values[_swingId], isFalse);
      expect(swing.position, closeTo(.5, .05));
    });
  });

  test('пауза у края: замер второй кнопкой и учёт в расчёте', () {
    fakeAsync((async) {
      final memory = _Memory();
      final (:device, :swing, :transport) = setUp(async, memory: memory);

      // Проход 1.5 с без пауз, у краёв стоит по 0.5 с.
      markPass(
        async,
        swing,
        from: 0,
        sweep: const Duration(milliseconds: 1500),
        dwell: const Duration(milliseconds: 500),
      );

      expect(swing.sweep, const Duration(milliseconds: 1500));
      expect(swing.dwell, const Duration(milliseconds: 500));
      expect(memory.dwells['1'], const Duration(milliseconds: 500));
      expect(swing.position, closeTo(1, 1e-9));

      async.elapse(const Duration(milliseconds: 750));
      expect(swing.position, closeTo(.5, 1e-9));

      // Дошёл до 0 и полсекунды стоит на месте.
      async.elapse(const Duration(milliseconds: 1050));
      expect(swing.position, closeTo(0, 1e-9));
    });
  });

  test('после перезапуска помнит калибровку и положение', () {
    fakeAsync((async) {
      final memory = _Memory();
      final first = setUp(async, memory: memory);
      markPass(async, first.swing, from: 1, sweep: const Duration(seconds: 10));
      first.swing.moveTo(.6);
      async.elapse(const Duration(seconds: 8));
      expect(first.swing.moving, isFalse);
      final stoppedAt = first.swing.position!;
      first.device.dispose();

      // «Перезапуск»: новый контроллер с тем же хранилищем.
      async.elapse(const Duration(hours: 3));
      final second = setUp(async, memory: memory);

      expect(second.swing.calibrated, isTrue);
      expect(second.swing.position, closeTo(stoppedAt, 1e-9));
    });
  });

  test('после перезапуска качание дольше двух минут не восстанавливает', () {
    fakeAsync((async) {
      final memory = _Memory();
      final first = setUp(async, memory: memory);
      markPass(async, first.swing, from: 1, sweep: const Duration(seconds: 10));
      first.device.dispose();

      async.elapse(const Duration(minutes: 5));
      final second = setUp(async, memory: memory);

      expect(second.swing.calibrated, isTrue);
      expect(second.swing.position, isNull);
    });
  });

  test('слишком короткий проход не считается калибровкой', () {
    fakeAsync((async) {
      final (:device, :swing, :transport) = setUp(async);

      markPass(async, swing, from: 0, sweep: const Duration(milliseconds: 300));

      expect(swing.calibrated, isFalse);
      expect(swing.holdResult?.accepted, isFalse);
    });
  });
}
