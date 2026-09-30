import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/core/cloud/xiaomi_login.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Фейковый сервер аккаунтов. [auth] — ответ на отправку логина и пароля.
class _FakeAccountServer {
  _FakeAccountServer(this.auth);

  final Map<String, dynamic> auth;
  final requests = <http.Request>[];

  Future<http.Response> handle(http.Request request) async {
    requests.add(request);
    return switch (request.url.path) {
      '/pass/serviceLogin' => _json({'_sign': 'sign', 'code': 70016}),
      '/pass/serviceLoginAuth2' => _json(auth),
      '/pass/getCode' => http.Response.bytes(
        [1, 2, 3],
        200,
        headers: {'set-cookie': 'ick=captcha-id; Path=/'},
      ),
      '/sts' => http.Response(
        '',
        302,
        headers: {
          'location': '/done',
          'set-cookie': 'serviceToken=token; Domain=.mi.com; Path=/',
        },
      ),
      _ => http.Response('ok', 200),
    };
  }

  http.Response _json(Map<String, dynamic> body) =>
      http.Response('&&&START&&&${jsonEncode(body)}', 200);

  http.Request requestTo(String path) =>
      requests.lastWhere((request) => request.url.path == path);
}

XiaomiLogin _login(_FakeAccountServer server) =>
    XiaomiLogin(client: MockClient(server.handle));

void main() {
  test('успешный вход возвращает сессию', () async {
    final server = _FakeAccountServer({
      'code': 0,
      'ssecurity': 'secret',
      'userId': 42,
      'location': 'https://sts.api.io.mi.com/sts?x=1',
    });
    final step = await _login(server).submit(user: 'user', password: 'pass');

    final session = (step as LoginSuccess).session;
    expect(session.userId, '42');
    expect(session.ssecurity, 'secret');
    expect(session.serviceToken, 'token');

    final fields = server.requestTo('/pass/serviceLoginAuth2').bodyFields;
    expect(fields['hash'], '1A1DC91C907325C69271DDF0C944BC72');
    expect(fields['_sign'], 'sign');
  });

  test('неверный пароль даёт понятную ошибку', () async {
    final server = _FakeAccountServer({'code': 70016});
    expect(
      () => _login(server).submit(user: 'user', password: 'bad'),
      throwsA(
        isA<LoginException>().having(
          (e) => e.message,
          'message',
          'Неверный логин или пароль',
        ),
      ),
    );
  });

  test('капча: картинка загружается, ответ уходит вместе с cookie', () async {
    final server = _FakeAccountServer({
      'code': 87001,
      'captchaUrl': '/pass/getCode?icodeType=login',
    });
    final login = _login(server);

    final step = await login.submit(user: 'user', password: 'pass');
    expect((step as CaptchaRequired).image, [1, 2, 3]);

    await login.submit(user: 'user', password: 'pass', captcha: 'abcd');
    final retry = server.requestTo('/pass/serviceLoginAuth2');
    expect(retry.bodyFields['captCode'], 'abcd');
    expect(retry.headers['Cookie'], contains('ick=captcha-id'));
  });
}
