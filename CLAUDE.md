# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## О проекте

Flutter-приложение (Windows, macOS, Linux, Android, iOS) для управления устройствами Xiaomi / Mijia через неофициальный облачный API Xiaomi. Главная идея — устройства **всех регионов** (`cn`, `ru`, `de`, `us`, `sg`, `i2`, `tw`) и **всех аккаунтов** в одном списке. Комментарии, doc-комментарии, названия тестов и сообщения коммитов — на русском. План работ и известные пробелы — в `TODO.md`.

## Команды

Нужен Flutter 3.47+ (в CI — 3.47.5).

```bash
flutter pub get
flutter run                          # обычный запуск
flutter run --dart-define=DEMO=true  # сразу демо-режим, без входа

# Те же проверки, что в CI (job «Анализ и тесты»):
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

flutter test test/core/devices/swing_controller_test.dart         # один файл
flutter test test/core/devices/swing_controller_test.dart --plain-name 'часть имени'  # один тест

SCREENSHOTS=1 flutter test test/screenshots                      # пересъёмка скриншотов для README в docs/screenshots
ICONS=1 flutter test test/screenshots/icon_test.dart && dart run flutter_launcher_icons  # иконки приложения
```

Без переменных `SCREENSHOTS` / `ICONS` эти тесты пропускаются. Релизные сборки и установщики (`packaging/`: Inno Setup, makeself, dmg) собираются в CI только по тегу `vX.Y.Z` или при ручном запуске workflow.

## Архитектура

Слои: `core/cloud` (транспорт HTTP) → `core/spec` (описания устройств) → `core/devices` (модель и логика) → `ui`. Нижние слои не знают о верхних.

- **Облако (`lib/core/cloud`).** `MiCloudClient.call(region, path, data)` — единая точка для подписанных запросов в любой регион: подпись и RC4-шифрование параметров в `request_signer.dart`/`rc4.dart`, адреса регионов в `regions.dart`. HTTP 401 → `SessionExpiredException`. Вход (пароль, капча, код 2FA, QR) — в `xiaomi_login.dart`; результат входа — `Session` (`userId`, `ssecurity`, `serviceToken`).
- **Сессии и настройки.** `SessionStore` хранит список сессий во `flutter_secure_storage` (с миграцией со старого ключа одной сессии); пароли не хранятся нигде. Несекретное (тема, масштаб UI, включённые регионы, порядок плиток, калибровка качания вентиляторов) — в `Preferences` поверх `shared_preferences`; это `ChangeNotifier`, и `HomeAssistApp` перестраивается от него.
- **Спецификации MIoT (`lib/core/spec`).** `SpecRepository.forModel(model)` скачивает спецификацию с miot-spec.org, кэширует на диске (`<cacheDir>/spec/<model>.json`, индекс моделей — неделю) и отдаёт `MiotSpec` или `null`, если спецификации нет. Панель управления устройством (`ui/widgets/spec_controls.dart`) строится **целиком из спецификации** — ручной разметки под модели нет.
- **Устройства (`lib/core/devices`).**
  - `DeviceRepository.loadAll()` опрашивает регионы параллельно; каждый регион даёт `RegionResult` с устройствами **или** ошибкой, сбой одного не мешает остальным.
  - `DeviceTransport` — общий интерфейс `getProperties / setProperty / callAction`. Сейчас есть `CloudTransport` и `DemoTransport`; локальное управление по miIO/UDP планируется как ещё одна реализация этого же интерфейса.
  - `DeviceController` (`ChangeNotifier`) — состояние одного открытого устройства: чтение, переключение, запись свойств, действия.
  - `SwingController` + `SwingTracker` — поворот вентилятора в нужное положение там, где у устройства есть только «качаться / стоять»: положение вычисляется по времени после калибровки, калибровка сохраняется через интерфейс `SwingCalibrations` (реализует `Preferences`).
  - `DeviceProbe` — только читающий перебор siid × piid, чтобы найти свойства, которых нет в спецификации (экран `ui/device_probe_page.dart`).
- **Несколько аккаунтов.** `HomeAssistApp` (`ui/app.dart`) держит список сессий; `HomeShell` на каждую сессию создаёт «связь» `(DeviceRepository, DeviceTransport)` по `accountId` и объединяет устройства. Устройство, видимое из нескольких аккаунтов, показывается один раз.
- **Демо (`lib/demo/demo.dart`).** `demoSession` (`isDemo`) подключает `DemoDeviceRepository` и `DemoTransport` вместо облачных; команды никуда не уходят, но спецификации берутся настоящие. Демо-сессия никогда не сохраняется в `SessionStore`. Новые возможности UI стоит показывать и в демо — скриншоты README снимаются именно с него.

## Переводы

Интерфейс на русском, английском и китайском (`Preferences.language`: `system`, `ru`, `en`, `zh`). Строки лежат в `lib/l10n/app_{ru,en,zh}.arb`, шаблон — `app_ru.arb`; `app_localizations*.dart` рядом генерируются `flutter gen-l10n` (и при `flutter pub get`) и коммитятся вместе с ARB. В коде строки берутся через `context.l10n` из `lib/ui/l10n.dart`.

- Новую строку добавлять во все три ARB — `test/ui/language_test.dart` сверяет наборы ключей.
- Генератор упорядочивает параметры сообщения **по алфавиту**. Если параметров несколько, в `app_ru.arb` нужна запись `@ключ` с `placeholders` в нужном порядке.
- Ядро (`lib/core`) не содержит текста для пользователя: исключения несут причину (`LoginFailure`, `CommandRejectedException`, технические `details`), а текст подбирает `describeError` в `lib/ui/l10n.dart`. Названия регионов (`regionName`) и демо-устройств (`demoDeviceName`) тоже в ARB.
- Названия свойств и режимов в панели устройства приходят из спецификации MIoT и не переводятся.

## Тесты

- Сеть в тестах всегда подменена. `test/support/fake_cloud.dart` → `fakeCloud(respond, calls: …)` даёт настоящий `MiCloudClient` поверх `MockClient`, который расшифровывает запрос и шифрует ответ — так проверяется и подпись, и содержимое вызовов.
- Реальные спецификации лежат в `test/fixtures/spec/<model>.json`; в тестах используется `SpecRepository(cacheDir: Directory('test/fixtures'))`, чтобы они читались из «кэша» без сети.
- Виджет-тесты задают `MaterialApp` с `locale: Locale('ru')` и делегатами `AppLocalizations` — иначе `context.l10n` упадёт, а тексты в `find.text` не совпадут.
- Для логики с таймерами (опрос, качание вентилятора) используется `fake_async`.

## Стиль кода

Когнитивная сложность — минимальная: короткие функции, ранний выход вместо вложенных `if`, никаких абстракций без второго реального применения. Линтер — стандартный `flutter_lints`; форматирование — `dart format` (CI падает на неотформатированном коде).
