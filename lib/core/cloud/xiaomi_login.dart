import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../accounts/session.dart';
import 'cookie_client.dart';

sealed class LoginStep {}

class LoginSuccess extends LoginStep {
  LoginSuccess(this.session);
  final Session session;
}

/// Нужно показать картинку и повторить вход с текстом с неё.
class CaptchaRequired extends LoginStep {
  CaptchaRequired(this.image);
  final Uint8List image;
}

/// Код уже отправлен пользователю, его нужно передать в `submitCode`.
class TwoFactorRequired extends LoginStep {
  TwoFactorRequired({required this.viaEmail});
  final bool viaEmail;
}

/// QR-код для входа: его сканируют в Mi Home на телефоне.
class QrChallenge {
  QrChallenge({
    required this.image,
    required this.loginUrl,
    required this.pollUrl,
    required this.timeout,
  });

  final Uint8List image;

  /// Та же ссылка, что зашита в QR-код: её можно открыть на телефоне.
  final String loginUrl;
  final Uri pollUrl;
  final Duration timeout;
}

/// Почему не удался вход. Текст для пользователя подбирает интерфейс.
enum LoginFailure {
  noQrCode,
  qrFailed,
  qrExpired,
  codeNotRequested,
  wrongCode,
  noSession,
  noServiceToken,
  wrongCredentials,
  rejected,
  unexpectedResponse,
}

class LoginException implements Exception {
  LoginException(this.failure, {this.code, this.details = ''});

  final LoginFailure failure;

  /// Код и описание ошибки от сервера, если он их прислал.
  final Object? code;
  final String details;

  @override
  String toString() => 'LoginException(${failure.name}, $code, $details)';
}

/// Вход в аккаунт Xiaomi (`sid=xiaomiio`): по логину и паролю или по QR-коду.
class XiaomiLogin {
  XiaomiLogin({http.Client? client, Random? random})
    : _http = CookieClient(
        client ?? http.Client(),
        userAgent: _userAgent(random ?? Random.secure()),
      ) {
    final deviceId = _randomString(random ?? Random.secure(), 6, 'a', 26);
    for (final domain in ['mi.com', 'xiaomi.com']) {
      _http.setCookie(domain, 'sdkVersion', 'accountsdk-18.8.15');
      _http.setCookie(domain, 'deviceId', deviceId);
    }
  }

  static const _host = 'account.xiaomi.com';
  static const _sid = 'xiaomiio';
  static const _locale = 'en_US';
  static const _emailFlag = 8;

  final CookieClient _http;
  _TwoFactor? _twoFactor;

  /// Меняется при отмене: ожидание старого кода по нему понимает,
  /// что пора остановиться.
  int _qrGeneration = 0;

  /// Запрашивает QR-код для входа без пароля.
  Future<QrChallenge> startQr() async {
    final response = await _http.get(
      Uri.https(_host, '/longPolling/loginUrl', {
        '_qrsize': '480',
        'qs': '%3Fsid%3D$_sid%26_json%3Dtrue',
        'callback': 'https://sts.api.io.mi.com/sts',
        '_hasLogo': 'false',
        'sid': _sid,
        'serviceParam': '',
        '_locale': _locale,
        '_dc': '${DateTime.now().millisecondsSinceEpoch}',
      }),
    );
    final json = parseXiaomiJson(response.body);
    final qr = json['qr'];
    final poll = json['lp'];
    if (qr is! String || poll is! String) {
      throw LoginException(LoginFailure.noQrCode);
    }
    final image = await _http.get(Uri.parse(qr));
    return QrChallenge(
      image: image.bodyBytes,
      loginUrl: '${json['loginUrl'] ?? ''}',
      pollUrl: Uri.parse(poll),
      timeout: Duration(seconds: int.tryParse('${json['timeout']}') ?? 300),
    );
  }

  /// Ждёт, пока код отсканируют и подтвердят на телефоне.
  /// Сервер держит каждый запрос открытым, пока не случится одно из двух.
  Future<LoginStep> waitForQr(QrChallenge challenge) async {
    final generation = _qrGeneration;
    final deadline = DateTime.now().add(challenge.timeout);
    while (generation == _qrGeneration && DateTime.now().isBefore(deadline)) {
      final response = await _pollOnce(challenge.pollUrl);
      if (response == null) continue;
      if (response.statusCode != 200) {
        throw LoginException(LoginFailure.qrFailed);
      }
      return _finish(parseXiaomiJson(response.body));
    }
    throw LoginException(LoginFailure.qrExpired);
  }

  /// Прекращает ожидание, например когда пользователь ушёл с экрана.
  void cancelQr() => _qrGeneration++;

  Future<http.Response?> _pollOnce(Uri url) async {
    try {
      return await _http.get(url);
    } on TimeoutException {
      return null;
    }
  }

  Future<LoginStep> submit({
    required String user,
    required String password,
    String captcha = '',
  }) async {
    final sign = await _fetchSign(user);
    final response = await _http.postForm(
      Uri.https(_host, '/pass/serviceLoginAuth2', {'_json': 'true'}),
      {
        'sid': _sid,
        'hash': md5.convert(utf8.encode(password)).toString().toUpperCase(),
        'callback': 'https://sts.api.io.mi.com/sts',
        'qs': '%3Fsid%3D$_sid%26_json%3Dtrue',
        'user': user,
        '_sign': sign,
        '_json': 'true',
        if (captcha.isNotEmpty) 'captCode': captcha,
      },
    );
    return _interpret(parseXiaomiJson(response.body));
  }

  Future<LoginStep> submitCode(String code) async {
    final twoFactor = _twoFactor;
    if (twoFactor == null) throw LoginException(LoginFailure.codeNotRequested);

    final flag = '${twoFactor.flag}';
    final response = await _http.postForm(
      Uri.https(_host, '/identity/auth/verify${twoFactor.channel}', {
        '_flag': flag,
        '_json': 'true',
        ...twoFactor.query,
      }),
      {'_flag': flag, 'ticket': code, 'trust': 'false', '_json': 'true'},
    );
    final json = parseXiaomiJson(response.body);
    final location = json['location'];
    if (json['code'] != 0 || location is! String) {
      throw LoginException(LoginFailure.wrongCode);
    }

    // Проход по цепочке выставляет passToken, после чего serviceLogin
    // отдаёт ssecurity и адрес для получения serviceToken без пароля.
    await _http.getChain(Uri.parse(location));
    _twoFactor = null;
    return _interpret(await _serviceLogin());
  }

  Future<String> _fetchSign(String user) async {
    _http.setCookie(_host, 'userId', user);
    final json = await _serviceLogin();
    return json['_sign'] as String? ?? '';
  }

  Future<Map<String, dynamic>> _serviceLogin() async {
    final response = await _http.get(
      Uri.https(_host, '/pass/serviceLogin', {'sid': _sid, '_json': 'true'}),
    );
    return parseXiaomiJson(response.body);
  }

  Future<LoginStep> _interpret(Map<String, dynamic> json) async {
    final captchaUrl = json['captchaUrl'];
    if (captchaUrl is String && captchaUrl.isNotEmpty) {
      return _loadCaptcha(captchaUrl);
    }
    final notificationUrl = json['notificationUrl'];
    if (notificationUrl is String && notificationUrl.isNotEmpty) {
      return _startTwoFactor(notificationUrl);
    }
    if (json['code'] != 0) throw _loginError(json);
    return _finish(json);
  }

  Future<LoginStep> _loadCaptcha(String captchaUrl) async {
    final response = await _http.get(Uri.https(_host).resolve(captchaUrl));
    return CaptchaRequired(response.bodyBytes);
  }

  Future<LoginStep> _startTwoFactor(String notificationUrl) async {
    final url = Uri.parse(notificationUrl);
    final context = url.queryParameters['context'] ?? '';
    await _http.get(url);

    final list = await _http.get(
      Uri.https(_host, '/identity/list', {
        'sid': _sid,
        'context': context,
        '_locale': _locale,
      }),
    );
    final twoFactor = _TwoFactor(
      context: context,
      flag: parseXiaomiJson(list.body)['flag'] as int? ?? 4,
    );

    await _http.postForm(
      Uri.https(_host, '/identity/auth/send${twoFactor.channel}Ticket', {
        '_dc': '${DateTime.now().millisecondsSinceEpoch}',
        ...twoFactor.query,
      }),
      {'retry': '0', 'icode': '', '_json': 'true'},
    );
    _twoFactor = twoFactor;
    return TwoFactorRequired(viaEmail: twoFactor.flag == _emailFlag);
  }

  Future<LoginStep> _finish(Map<String, dynamic> json) async {
    final ssecurity = json['ssecurity'];
    final location = json['location'];
    if (ssecurity is! String || location is! String || location.isEmpty) {
      throw LoginException(LoginFailure.noSession);
    }

    await _http.getChain(Uri.parse(location));
    final serviceToken = _http.cookie('serviceToken');
    if (serviceToken == null) {
      throw LoginException(LoginFailure.noServiceToken);
    }
    return LoginSuccess(
      Session(
        userId: '${json['userId']}',
        ssecurity: ssecurity,
        serviceToken: serviceToken,
      ),
    );
  }

  LoginException _loginError(Map<String, dynamic> json) {
    final code = json['code'];
    if (code == 70016) return LoginException(LoginFailure.wrongCredentials);
    final description = json['desc'] ?? json['description'] ?? '—';
    return LoginException(
      LoginFailure.rejected,
      code: code,
      details: '$description',
    );
  }

  static String _userAgent(Random random) {
    final id = _randomString(random, 13, 'A', 5);
    return 'Android-7.1.1-1.0.0-ONEPLUS A3010-136-$id '
        'APP/xiaomi.smarthome APP/com.xiaomi.mihome';
  }

  static String _randomString(
    Random random,
    int length,
    String first,
    int span,
  ) {
    final base = first.codeUnitAt(0);
    return String.fromCharCodes(
      List.generate(length, (_) => base + random.nextInt(span)),
    );
  }
}

/// Ответы сервера аккаунтов начинаются с защитного префикса `&&&START&&&`.
Map<String, dynamic> parseXiaomiJson(String body) {
  final start = body.indexOf('{');
  if (start < 0) throw LoginException(LoginFailure.unexpectedResponse);
  return jsonDecode(body.substring(start)) as Map<String, dynamic>;
}

class _TwoFactor {
  _TwoFactor({required this.context, required this.flag});

  final String context;

  /// 4 — код по SMS, 8 — код на почту.
  final int flag;

  String get channel => flag == XiaomiLogin._emailFlag ? 'Email' : 'Phone';

  Map<String, String> get query => {
    'sid': XiaomiLogin._sid,
    'context': context,
    'mask': '0',
    '_locale': XiaomiLogin._locale,
  };
}
