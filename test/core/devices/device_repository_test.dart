import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/core/accounts/session.dart';
import 'package:home_assist/core/cloud/mi_cloud_client.dart';
import 'package:home_assist/core/cloud/rc4.dart';
import 'package:home_assist/core/cloud/request_signer.dart';
import 'package:home_assist/core/devices/device_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _session = Session(
  userId: '42',
  ssecurity: 'AAECAwQFBgcICQoLDA0ODw==',
  serviceToken: 'token',
);

/// Фейковое облако: `ru` отдаёт одно устройство, `cn` — пустой список,
/// остальные регионы отвечают ошибкой 500.
Future<http.Response> _fakeCloud(http.Request request) async {
  final devices = {
    'ru.api.io.mi.com': [
      {
        'did': '1',
        'model': 'dmaker.fan.p5',
        'name': 'Вентилятор',
        'isOnline': true,
      },
    ],
    'api.io.mi.com': <Object>[],
  }[request.url.host];
  if (devices == null) return http.Response('', 500);

  final body = jsonEncode({
    'code': 0,
    'result': {'list': devices},
  });
  return http.Response(_encrypt(request.bodyFields['_nonce']!, body), 200);
}

String _encrypt(String nonce, String text) {
  final key = RequestSigner(_session.ssecurity).signedNonce(nonce);
  final cipher = Rc4(base64.decode(key))..process(List.filled(1024, 0));
  return base64.encode(cipher.process(utf8.encode(text)));
}

void main() {
  test('собирает устройства по регионам и переживает сбой региона', () async {
    final cloud = MiCloudClient(_session, client: MockClient(_fakeCloud));
    final results = await DeviceRepository(cloud).loadAll(['ru', 'cn', 'de']);

    final ru = results[0];
    expect(ru.error, isNull);
    expect(ru.devices.single.name, 'Вентилятор');
    expect(ru.devices.single.region, 'ru');
    expect(ru.devices.single.accountId, '42');
    expect(ru.devices.single.isOnline, isTrue);

    expect(results[1].devices, isEmpty);
    expect(results[1].error, isNull);
    expect(results[2].error, isA<CloudException>());
  });

  test('запрос несёт cookie сессии и уходит на сервер региона', () async {
    late http.Request seen;
    final cloud = MiCloudClient(
      _session,
      client: MockClient((request) {
        seen = request;
        return _fakeCloud(request);
      }),
    );
    await DeviceRepository(cloud).loadAll(['ru']);

    expect('${seen.url}', 'https://ru.api.io.mi.com/app/home/device_list');
    expect(seen.headers['Cookie'], contains('serviceToken=token'));
    expect(seen.bodyFields.keys, containsAll(['data', 'signature', '_nonce']));
  });
}
