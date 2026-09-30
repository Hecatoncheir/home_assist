import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'session.dart';

/// Хранит сессии аккаунтов в системном хранилище секретов.
/// Пароли не хранятся нигде.
class SessionStore {
  const SessionStore([this._storage = const FlutterSecureStorage()]);

  static const _key = 'sessions';

  /// Ключ версий до поддержки нескольких аккаунтов: одна сессия.
  static const _legacyKey = 'session';

  final FlutterSecureStorage _storage;

  Future<List<Session>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw != null) {
      return [for (final item in jsonDecode(raw) as List) _parse(item)];
    }
    final legacy = await _storage.read(key: _legacyKey);
    return [if (legacy != null) _parse(jsonDecode(legacy))];
  }

  Future<void> save(List<Session> sessions) =>
      _storage.write(key: _key, value: jsonEncode(sessions));

  Session _parse(Object? json) =>
      Session.fromJson(json as Map<String, dynamic>);
}
