import 'dart:convert';

import 'package:home_assist/core/accounts/session.dart';
import 'package:home_assist/core/cloud/mi_cloud_client.dart';
import 'package:home_assist/core/cloud/rc4.dart';
import 'package:home_assist/core/cloud/request_signer.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const fakeSession = Session(
  userId: '42',
  ssecurity: 'AAECAwQFBgcICQoLDA0ODw==',
  serviceToken: 'token',
);

/// Расшифрованный запрос к фейковому облаку.
typedef CloudCall = ({String host, String path, Map<String, dynamic> data});

/// Облако, которое на каждый запрос отвечает результатом [respond]
/// и запоминает запросы в [calls].
MiCloudClient fakeCloud(
  Object? Function(CloudCall call) respond, {
  List<CloudCall>? calls,
}) {
  final signer = RequestSigner(fakeSession.ssecurity);
  return MiCloudClient(
    fakeSession,
    client: MockClient((request) async {
      final nonce = request.bodyFields['_nonce']!;
      final data = signer.decrypt(nonce, request.bodyFields['data']!);
      final call = (
        host: request.url.host,
        path: request.url.path.replaceFirst('/app', ''),
        data: jsonDecode(data) as Map<String, dynamic>,
      );
      calls?.add(call);
      final body = jsonEncode({'code': 0, 'result': respond(call)});
      return http.Response(_encrypt(signer.signedNonce(nonce), body), 200);
    }),
  );
}

String _encrypt(String key, String text) {
  final cipher = Rc4(base64.decode(key))..process(List.filled(1024, 0));
  return base64.encode(cipher.process(utf8.encode(text)));
}
