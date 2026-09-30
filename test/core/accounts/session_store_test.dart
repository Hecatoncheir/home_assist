import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/core/accounts/session.dart';
import 'package:home_assist/core/accounts/session_store.dart';

const _first = Session(userId: '1', ssecurity: 'a', serviceToken: 'b');
const _second = Session(
  userId: '2',
  ssecurity: 'c',
  serviceToken: 'd',
  label: 'second@example.com',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const store = SessionStore();

  test('сохраняет и читает несколько аккаунтов', () async {
    FlutterSecureStorage.setMockInitialValues({});
    await store.save([_first, _second]);

    final loaded = await store.load();
    expect(loaded.map((s) => s.userId), ['1', '2']);
    expect(loaded.first.label, '1');
    expect(loaded.last.label, 'second@example.com');
  });

  test('подхватывает сессию, сохранённую до поддержки аккаунтов', () async {
    FlutterSecureStorage.setMockInitialValues({
      'session': jsonEncode({
        'userId': '1',
        'ssecurity': 'a',
        'serviceToken': 'b',
      }),
    });

    expect((await store.load()).single.userId, '1');
  });

  test('после удаления всех аккаунтов старая сессия не возвращается', () async {
    FlutterSecureStorage.setMockInitialValues({
      'session': jsonEncode(_first.toJson()),
    });
    await store.save([]);

    expect(await store.load(), isEmpty);
  });
}
