import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'rc4.dart';

/// Подпись и шифрование запросов к облаку Xiaomi (режим ENCRYPT-RC4).
class RequestSigner {
  RequestSigner(this.ssecurity, {Random? random})
    : _random = random ?? Random.secure();

  final String ssecurity;
  final Random _random;

  /// 8 случайных байт + время в минутах (4 байта, big-endian).
  String newNonce(DateTime now) {
    final bytes = ByteData(12);
    for (var i = 0; i < 8; i++) {
      bytes.setUint8(i, _random.nextInt(256));
    }
    bytes.setUint32(8, now.millisecondsSinceEpoch ~/ 60000);
    return base64.encode(bytes.buffer.asUint8List());
  }

  String signedNonce(String nonce) {
    final input = base64.decode(ssecurity) + base64.decode(nonce);
    return base64.encode(sha256.convert(input).bytes);
  }

  /// Возвращает поля формы, готовые к отправке. Порядок [params] важен:
  /// он участвует в подписи.
  Map<String, String> encryptParams({
    required String method,
    required String path,
    required String nonce,
    required Map<String, String> params,
  }) {
    final key = signedNonce(nonce);
    final plain = {
      ...params,
      'rc4_hash__': _signature(method, path, params, key),
    };
    final encrypted = plain.map((k, v) => MapEntry(k, _encrypt(key, v)));
    return {
      ...encrypted,
      'signature': _signature(method, path, encrypted, key),
      'ssecurity': ssecurity,
      '_nonce': nonce,
    };
  }

  String decrypt(String nonce, String body) {
    final cipher = _cipher(signedNonce(nonce));
    return utf8.decode(cipher.process(base64.decode(body)));
  }

  String _encrypt(String key, String value) =>
      base64.encode(_cipher(key).process(utf8.encode(value)));

  /// Xiaomi пропускает первые 1024 байта ключевого потока.
  Rc4 _cipher(String key) => Rc4(base64.decode(key))..process(Uint8List(1024));

  String _signature(
    String method,
    String path,
    Map<String, String> params,
    String signedNonce,
  ) {
    final parts = [
      method.toUpperCase(),
      path,
      for (final entry in params.entries) '${entry.key}=${entry.value}',
      signedNonce,
    ];
    return base64.encode(sha1.convert(utf8.encode(parts.join('&'))).bytes);
  }
}
