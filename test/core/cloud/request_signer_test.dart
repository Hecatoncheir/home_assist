import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/core/cloud/rc4.dart';
import 'package:home_assist/core/cloud/request_signer.dart';

// Эталонные значения посчитаны независимой реализацией на Python
// по алгоритму из Xiaomi Cloud Tokens Extractor.
const _ssecurity = 'AAECAwQFBgcICQoLDA0ODw==';
const _nonce = 'ZGVmZ2hpamtsbW5v';

void main() {
  final signer = RequestSigner(_ssecurity, random: Random(1));

  test('RC4 совпадает с известным вектором', () {
    final output = Rc4(utf8.encode('Key')).process(utf8.encode('Plaintext'));
    final hex = output.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    expect(hex, 'bbf316e8d940af0ad3');
  });

  test('signedNonce', () {
    expect(
      signer.signedNonce(_nonce),
      '+JfC+ScjV+jXa9PgCRtBpAfTWAAwPFTV0LabBt47GcA=',
    );
  });

  test('encryptParams шифрует поля и подписывает запрос', () {
    final fields = signer.encryptParams(
      method: 'POST',
      path: '/home/device_list',
      nonce: _nonce,
      params: {'data': '{"getVirtualModel":true}'},
    );
    expect(fields, {
      'data': 'cBCKspLxnDdDVDI6fLoeWLCsrP0AQDe2',
      'rc4_hash__': 'c1aOktblhhVwTmQYWpEddeThwLweRyaAFiCReg==',
      'signature': 'iHu3ZD1B1gEfxfetuoP6ADvA1bI=',
      'ssecurity': _ssecurity,
      '_nonce': _nonce,
    });
  });

  test('decrypt обратен шифрованию', () {
    expect(
      signer.decrypt(_nonce, 'cBCKspLxnDdDVDI6fLoeWLCsrP0AQDe2'),
      '{"getVirtualModel":true}',
    );
  });

  test('newNonce содержит время в минутах', () {
    final now = DateTime.fromMillisecondsSinceEpoch(60000 * 0x01020304);
    final bytes = base64.decode(signer.newNonce(now));
    expect(bytes.sublist(8), [1, 2, 3, 4]);
  });
}
