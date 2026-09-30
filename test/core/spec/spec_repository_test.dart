import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/core/spec/spec_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _oldType = 'urn:miot-spec-v2:device:fan:0000A005:dmaker-p5:1';
const _newType = 'urn:miot-spec-v2:device:fan:0000A005:dmaker-p5:2';

void main() {
  final fixture = File('test/fixtures/spec/dmaker.fan.p5.json')
      .readAsStringSync();
  late Directory cacheDir;
  late List<Uri> requests;

  Future<http.Response> server(http.Request request) async {
    requests.add(request.url);
    if (!request.url.path.endsWith('/instances')) {
      return http.Response(fixture, 200);
    }
    final instances = [
      {'model': 'dmaker.fan.p5', 'version': 2, 'type': _newType},
      {'model': 'dmaker.fan.p5', 'version': 1, 'type': _oldType},
    ];
    return http.Response(jsonEncode({'instances': instances}), 200);
  }

  SpecRepository repository() =>
      SpecRepository(cacheDir: cacheDir, client: MockClient(server));

  setUp(() {
    cacheDir = Directory.systemTemp.createTempSync('specs');
    requests = [];
  });
  tearDown(() => cacheDir.deleteSync(recursive: true));

  test('разбирает спецификацию вентилятора', () async {
    final spec = (await repository().forModel('dmaker.fan.p5'))!;

    expect(spec.power!.id, (siid: 2, piid: 1));
    expect(spec.controls.first.name, 'fan');
    // Свойство только для записи читать нельзя.
    expect(spec.readableIds, isNot(contains((siid: 2, piid: 7))));

    final properties = spec.controls.first.properties;
    expect(properties[2].values.map((v) => v.label), [
      'Natural Wind',
      'Straight Wind',
    ]);
    expect(properties[5].range!.max, 100);
    expect(spec.controls.last.properties.single.unit, 'minutes');
  });

  test('берёт последнюю версию спецификации', () async {
    await repository().forModel('dmaker.fan.p5');
    expect(requests.last.queryParameters['type'], _newType);
  });

  test('второй раз читает с диска, а не из сети', () async {
    await repository().forModel('dmaker.fan.p5');
    requests.clear();

    expect(await repository().forModel('dmaker.fan.p5'), isNotNull);
    expect(requests, isEmpty);
  });

  test('неизвестная модель — null', () async {
    expect(await repository().forModel('unknown.model'), isNull);
  });
}
