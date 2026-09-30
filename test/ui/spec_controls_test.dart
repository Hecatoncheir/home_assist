import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/core/devices/device.dart';
import 'package:home_assist/core/devices/device_controller.dart';
import 'package:home_assist/core/devices/device_transport.dart';
import 'package:home_assist/core/spec/miot_spec.dart';
import 'package:home_assist/core/spec/spec_repository.dart';
import 'package:home_assist/l10n/app_localizations.dart';
import 'package:home_assist/ui/theme.dart';
import 'package:home_assist/ui/widgets/spec_controls.dart';

const _vacuum = Device(
  did: '1',
  model: 'dreame.vacuum.x',
  name: 'Пылесос',
  region: 'ru',
  accountId: '1',
  localIp: '',
  token: '',
  isOnline: true,
  parentId: '',
);

class _Idle implements DeviceTransport {
  @override
  Future<Map<PropertyId, Object?>> getProperties(
    Device device,
    List<PropertyId> ids,
  ) async => {};

  @override
  Future<void> setProperty(Device device, PropertyId id, Object value) async {}

  @override
  Future<void> callAction(Device device, MiotAction action) async {}
}

void main() {
  testWidgets('длинное значение переносится и не ломает строку', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final service = MiotService.fromJson({
      'iid': 4,
      'type': 'urn:miot-spec-v2:service:vacuum-extend:0:x:1',
      'description': 'Vacuum Extend',
      'properties': [
        {
          'iid': 1,
          'type': 'urn:miot-spec-v2:property:multi-prop-vacuum:0:x:1',
          'description': '',
          'format': 'string',
          'access': ['read'],
        },
      ],
    });
    const long = '[0,3,1,3,2,1,-10800,0,0.0,0,"ru_RU","39692844041"]';
    final controller = DeviceController(
      _vacuum,
      SpecRepository(cacheDir: Directory.systemTemp),
      _Idle(),
    )..values = {(siid: 4, piid: 1): long};

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(HomeColors.light, Brightness.light),
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ServiceSection(service: service, controller: controller),
        ),
      ),
    );

    expect(find.text('multi-prop-vacuum'), findsOneWidget);
    expect(find.text(long), findsOneWidget);
  });
}
