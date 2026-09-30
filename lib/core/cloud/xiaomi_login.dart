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

class LoginException implements Exception {
  LoginException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Вход в аккаунт Xiaomi по логину и паролю (`sid=xiaomiio`).
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
    if (twoFactor == null) throw LoginException('Код не запрашивался');

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
      throw LoginException('Неверный код подтверждения');
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
    if (json['code'] != 0) throw LoginException(_describeError(json));
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
      throw LoginException('Сервер Xiaomi не вернул данные сессии');
    }

    await _http.getChain(Uri.parse(location));
    final serviceToken = _http.cookie('serviceToken');
    if (serviceToken == null) {
      throw LoginException('Сервер Xiaomi не выдал serviceToken');
    }
    return LoginSuccess(
      Session(
        userId: '${json['userId']}',
        ssecurity: ssecurity,
        serviceToken: serviceToken,
      ),
    );
  }

  String _describeError(Map<String, dynamic> json) {
    if (json['code'] == 70016) return 'Неверный логин или пароль';
    final description = json['desc'] ?? json['description'] ?? 'нет описания';
    return 'Ошибка входа ${json['code']}: $description';
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
  if (start < 0) throw LoginException('Неожиданный ответ сервера Xiaomi');
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
