import 'package:http/http.dart' as http;

/// HTTP-клиент с хранилищем cookie и ручным проходом по перенаправлениям.
/// Нужен для входа в аккаунт: важные cookie приходят в промежуточных ответах.
class CookieClient {
  CookieClient(this._inner, {required this.userAgent});

  static const _maxRedirects = 10;
  static const _timeout = Duration(seconds: 20);

  final http.Client _inner;
  final String userAgent;

  /// домен → имя → значение
  final _jar = <String, Map<String, String>>{};

  void setCookie(String domain, String name, String value) {
    (_jar[domain] ??= {})[name] = value;
  }

  String? cookie(String name) {
    for (final cookies in _jar.values) {
      final value = cookies[name];
      if (value != null) return value;
    }
    return null;
  }

  Future<http.Response> get(Uri url) async => (await getChain(url)).last;

  /// Все ответы цепочки перенаправлений, последний — итоговый.
  Future<List<http.Response>> getChain(Uri url) async {
    final chain = <http.Response>[];
    Uri? next = url;
    while (next != null && chain.length < _maxRedirects) {
      final response = await _send(http.Request('GET', next));
      chain.add(response);
      next = _redirectTarget(next, response);
    }
    return chain;
  }

  Future<http.Response> postForm(Uri url, Map<String, String> fields) =>
      _send(http.Request('POST', url)..bodyFields = fields);

  Future<http.Response> _send(http.Request request) async {
    final host = request.url.host;
    request.followRedirects = false;
    request.headers['User-Agent'] = userAgent;
    final cookies = _cookieHeader(host);
    if (cookies.isNotEmpty) request.headers['Cookie'] = cookies;

    final streamed = await _inner.send(request).timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    _storeCookies(host, response);
    return response;
  }

  Uri? _redirectTarget(Uri current, http.Response response) {
    final location = response.headers['location'];
    if (!response.isRedirect || location == null) return null;
    return current.resolve(location);
  }

  String _cookieHeader(String host) => _jar.entries
      .where((entry) => _domainMatches(host, entry.key))
      .expand((entry) => entry.value.entries)
      .map((cookie) => '${cookie.key}=${cookie.value}')
      .join('; ');

  bool _domainMatches(String host, String domain) =>
      host == domain || host.endsWith('.$domain');

  void _storeCookies(String host, http.Response response) {
    final lines = response.headersSplitValues['set-cookie'] ?? const [];
    for (final line in lines) {
      _storeCookie(host, line);
    }
  }

  void _storeCookie(String host, String line) {
    final parts = line.split(';').map((part) => part.trim()).toList();
    final separator = parts.first.indexOf('=');
    if (separator <= 0) return;
    final name = parts.first.substring(0, separator);
    final value = parts.first.substring(separator + 1);
    setCookie(_domainAttribute(parts) ?? host, name, value);
  }

  String? _domainAttribute(List<String> parts) {
    for (final part in parts.skip(1)) {
      if (!part.toLowerCase().startsWith('domain=')) continue;
      final domain = part.substring('domain='.length).toLowerCase();
      return domain.startsWith('.') ? domain.substring(1) : domain;
    }
    return null;
  }
}
