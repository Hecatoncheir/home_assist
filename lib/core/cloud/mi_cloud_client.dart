import 'dart:convert';

import 'package:http/http.dart' as http;

import '../accounts/session.dart';
import 'regions.dart';
import 'request_signer.dart';

class CloudException implements Exception {
  CloudException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// serviceToken истёк — нужен повторный вход.
class SessionExpiredException extends CloudException {
  SessionExpiredException() : super('Сессия истекла, войдите заново');
}

/// Подписанные запросы к облаку Xiaomi в любом регионе.
class MiCloudClient {
  MiCloudClient(this.session, {http.Client? client, RequestSigner? signer})
    : _http = client ?? http.Client(),
      _signer = signer ?? RequestSigner(session.ssecurity);

  final Session session;
  final http.Client _http;
  final RequestSigner _signer;

  /// Возвращает поле `result` ответа.
  Future<dynamic> call(
    String region,
    String path,
    Map<String, dynamic> data,
  ) async {
    final nonce = _signer.newNonce(DateTime.now());
    final response = await _http.post(
      regionApiUrl(region, path),
      headers: _headers,
      body: _signer.encryptParams(
        method: 'POST',
        path: path,
        nonce: nonce,
        params: {'data': jsonEncode(data)},
      ),
    );
    if (response.statusCode == 401) throw SessionExpiredException();
    if (response.statusCode != 200) {
      throw CloudException('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(_signer.decrypt(nonce, response.body));
    if (json['code'] != 0) {
      throw CloudException('Ошибка ${json['code']}: ${json['message']}');
    }
    return json['result'];
  }

  Map<String, String> get _headers => {
    'Accept-Encoding': 'identity',
    'User-Agent': 'APP/com.xiaomi.mihome',
    'x-xiaomi-protocal-flag-cli': 'PROTOCAL-HTTP2',
    'MIOT-ENCRYPT-ALGORITHM': 'ENCRYPT-RC4',
    'Cookie': _cookies.entries.map((c) => '${c.key}=${c.value}').join('; '),
  };

  Map<String, String> get _cookies => {
    'userId': session.userId,
    'yetAnotherServiceToken': session.serviceToken,
    'serviceToken': session.serviceToken,
    'locale': 'en_GB',
    'timezone': 'GMT+02:00',
    'is_daylight': '1',
    'dst_offset': '3600000',
    'channel': 'MI_APP_STORE',
  };
}
