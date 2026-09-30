import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/core/cloud/xiaomi_login.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Map<String, dynamic> body) =>
    http.Response('&&&START&&&${jsonEncode(body)}', 200);

/// Фейковый сервер аккаунтов для входа по QR-коду.
/// [poll] — ответ на ожидание подтверждения.
MockClient _server(http.Response Function() poll) =>
    MockClient((request) async {
      return switch (request.url.path) {
        '/longPolling/loginUrl' => _json({
          'qr': 'https://account.xiaomi.com/qr.png',
          'loginUrl': 'https://account.xiaomi.com/qr-login',
          'lp': 'https://lp.account.xiaomi.com/lp/abc',
          'timeout': 300,
        }),
        '/qr.png' => http.Response.bytes([7, 7, 7], 200),
        '/lp/abc' => poll(),
        '/sts' => http.Response(
          '',
          200,
          headers: {'set-cookie': 'serviceToken=token; Domain=.mi.com; Path=/'},
        ),
        _ => http.Response('', 404),
      };
    });

void main() {
  test('после подтверждения на телефоне возвращает сессию', () async {
    final login = XiaomiLogin(
      client: _server(
        () => _json({
          'code': 0,
          'userId': 42,
          'ssecurity': 'secret',
          'location': 'https://sts.api.io.mi.com/sts',
        }),
      ),
    );

    final challenge = await login.startQr();
    expect(challenge.image, [7, 7, 7]);
    expect(challenge.loginUrl, 'https://account.xiaomi.com/qr-login');
    expect(challenge.timeout, const Duration(seconds: 300));

    final session = (await login.waitForQr(challenge) as LoginSuccess).session;
    expect(session.userId, '42');
    expect(session.ssecurity, 'secret');
    expect(session.serviceToken, 'token');
  });

  test('отказ сервера — понятная ошибка', () async {
    final login = XiaomiLogin(client: _server(() => http.Response('', 403)));
    final challenge = await login.startQr();

    expect(() => login.waitForQr(challenge), throwsA(isA<LoginException>()));
  });

  test('после отмены ожидание прекращается', () async {
    late XiaomiLogin login;
    // Пока сервер держит запрос, пользователь уходит с экрана.
    login = XiaomiLogin(
      client: _server(() {
        login.cancelQr();
        throw TimeoutException('long polling');
      }),
    );
    final challenge = await login.startQr();

    expect(
      () => login.waitForQr(challenge),
      throwsA(
        isA<LoginException>().having(
          (e) => e.failure,
          'failure',
          LoginFailure.qrExpired,
        ),
      ),
    );
  });
}
