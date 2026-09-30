import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'session.dart';

/// Хранит сессию в системном хранилище секретов. Пароль не хранится нигде.
class SessionStore {
  const SessionStore([this._storage = const FlutterSecureStorage()]);

  static const _key = 'session';

  final FlutterSecureStorage _storage;

  Future<Session?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    return Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(Session session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));

  Future<void> clear() => _storage.delete(key: _key);
}
