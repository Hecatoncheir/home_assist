// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get auto => 'Авто';

  @override
  String get cancel => 'Отмена';

  @override
  String get close => 'Закрыть';

  @override
  String get back => 'Назад';

  @override
  String get retry => 'Повторить';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get navHome => 'Дом';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get sectionAccounts => 'Аккаунты Xiaomi';

  @override
  String get sectionAppearance => 'Оформление';

  @override
  String get sectionLanguage => 'Язык';

  @override
  String get sectionRegions => 'Какие регионы опрашивать';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get regionsHint =>
      'Изменение применится при следующем обновлении списка.';

  @override
  String get addAccount => 'Добавить аккаунт';

  @override
  String get removeAccount => 'Убрать аккаунт';

  @override
  String get removeAccountTitle => 'Убрать аккаунт?';

  @override
  String removeAccountBody(Object account) {
    return '$account\n\nЕго устройства пропадут из списка. Сами устройства и аккаунт Xiaomi не изменятся.';
  }

  @override
  String get remove => 'Убрать';

  @override
  String get logoutDemo => 'Выйти из демо';

  @override
  String get logoutAll => 'Выйти из всех аккаунтов';

  @override
  String get logoutAccount => 'Выйти из аккаунта';

  @override
  String get demoAccount => 'Демо';

  @override
  String get uiScale => 'Масштаб интерфейса';

  @override
  String get zoomOut => 'Уменьшить (Ctrl + −)';

  @override
  String get zoomIn => 'Увеличить (Ctrl + +)';

  @override
  String regionName(String region) {
    String _temp0 = intl.Intl.selectLogic(region, {
      'cn': 'Китай',
      'ru': 'Россия',
      'de': 'Европа',
      'us': 'США',
      'sg': 'Сингапур',
      'i2': 'Индия',
      'tw': 'Тайвань',
      'other': '$region',
    });
    return '$_temp0';
  }

  @override
  String get greetingNight => 'Доброй ночи';

  @override
  String get greetingMorning => 'Доброе утро';

  @override
  String get greetingDay => 'Добрый день';

  @override
  String get greetingEvening => 'Добрый вечер';

  @override
  String devicesSummary(Object online, Object total, Object regions) {
    return 'В сети $online из $total · регионов: $regions';
  }

  @override
  String get refreshList => 'Обновить список';

  @override
  String regionUnavailable(Object error) {
    return 'недоступен: $error';
  }

  @override
  String get filterAll => 'Все';

  @override
  String get noDevices => 'Устройства не найдены';

  @override
  String get statusOffline => 'Не в сети';

  @override
  String get statusOn => 'Включено';

  @override
  String get statusOff => 'Выключено';

  @override
  String get statusOnline => 'В сети';

  @override
  String get infoModel => 'Модель';

  @override
  String get infoRegion => 'Регион';

  @override
  String get infoAccount => 'Аккаунт';

  @override
  String get exploreDevice => 'Исследовать устройство';

  @override
  String get direction => 'Направление';

  @override
  String get turnOnToRotate => 'Включите вентилятор, чтобы повернуть его.';

  @override
  String get noSpec =>
      'Для этой модели нет опубликованной спецификации, поэтому управлять ею пока нельзя.';

  @override
  String get loadingSpec => 'Загружаем описание устройства…';

  @override
  String get slower => 'Медленнее';

  @override
  String get faster => 'Быстрее';

  @override
  String get speed => 'скорость';

  @override
  String get unitSeconds => 'с';

  @override
  String get unitMinutes => 'мин';

  @override
  String get unitHours => 'ч';

  @override
  String get unitWatt => 'Вт';

  @override
  String get unitLux => 'лк';

  @override
  String get calibrate => 'Калибровка';

  @override
  String get swingRecalibrate => 'Поехал не туда — пересчитать';

  @override
  String get swingHoldTooltip => 'Держите, пока вентилятор стоит у этого края';

  @override
  String swingRelease(Object seconds) {
    return 'Отпустите, как только вентилятор тронется от края… $seconds с';
  }

  @override
  String get swingNotCounted =>
      'Не засчитано: кнопку другого края нужно зажать, как только вентилятор замрёт у него, а держать — пока стоит.';

  @override
  String get swingOtherEdge =>
      'Теперь зажмите кнопку другого края, как только вентилятор замрёт у него, и отпустите, когда тронется.';

  @override
  String get swingCalibrationIntro =>
      'Калибровка. Когда вентилятор замрёт у края, зажмите кнопку этого края и отпустите, как только он тронется. Затем то же у другого края.';

  @override
  String get swingLost =>
      'Положение сбилось: качание включали не из приложения. Нажмите «Калибровка» и отметьте один край.';

  @override
  String get swingTurning => 'Поворачиваю…';

  @override
  String swingReady(Object sweep, Object dwell) {
    return 'Нажмите на дугу, чтобы повернуть вентилятор. Проход — $sweep с, пауза у края — $dwell с.';
  }

  @override
  String get swingStatusHolding => 'стоит у края';

  @override
  String get swingStatusWaitingEdge => 'ждём края';

  @override
  String get swingStatusNoData => 'нет данных';

  @override
  String get swingStatusTurning => 'поворот';

  @override
  String get swingStatusSwinging => 'качается';

  @override
  String get swingStatusStill => 'стоит';

  @override
  String probeTitle(Object device) {
    return 'Исследование: $device';
  }

  @override
  String probeIntro(Object maxSiid, Object maxPiid) {
    return 'Приложение спрашивает у устройства свойства siid 1–$maxSiid × piid 1–$maxPiid, в том числе те, которых нет в спецификации. Только чтение: устройство ничего не меняет.';
  }

  @override
  String get probeWatch => 'Следить за изменениями';

  @override
  String get probeWatchHint =>
      'Раз в 2 секунды. Нажимайте кнопки на устройстве или в Mi Home и смотрите, какие значения меняются.';

  @override
  String probeScanning(Object siid, Object maxSiid) {
    return 'Опрашиваю siid $siid из $maxSiid…';
  }

  @override
  String get probeScan => 'Сканировать';

  @override
  String get probeRescan => 'Сканировать заново';

  @override
  String probeFound(Object count, Object hidden) {
    return 'Найдено свойств: $count, из них нет в спецификации: $hidden.';
  }

  @override
  String probeFailedSiids(Object siids) {
    return 'Ошибка при опросе siid: $siids';
  }

  @override
  String get probeChanges => 'Изменения';

  @override
  String get probeNotInSpec => 'нет в спецификации';

  @override
  String probeReadFailed(Object error) {
    return 'Не удалось прочитать: $error';
  }

  @override
  String get probeCopy => 'Скопировать отчёт';

  @override
  String get probeCopied => 'Отчёт скопирован';

  @override
  String probeReportTitle(Object device, Object model, Object region) {
    return '$device · $model · регион $region';
  }

  @override
  String get loginTitle => 'Весь дом в одном списке';

  @override
  String get loginSubtitle =>
      'Устройства Xiaomi из всех регионов. Пароль не сохраняется.';

  @override
  String get loginUser => 'Почта, телефон или ID';

  @override
  String get loginPassword => 'Пароль';

  @override
  String get loginCaptcha => 'Текст с картинки';

  @override
  String get loginCodeEmail => 'Код из письма';

  @override
  String get loginCodeSms => 'Код из SMS';

  @override
  String get loginSubmit => 'Войти';

  @override
  String get loginContinue => 'Продолжить';

  @override
  String get loginBusy => 'Входим…';

  @override
  String get loginWithQr => 'Войти по QR-коду';

  @override
  String get loginDemo => 'Посмотреть демо без аккаунта';

  @override
  String get backToSettings => 'К настройкам';

  @override
  String get qrInstructions =>
      'Отсканируйте код в приложении Mi Home или на телефоне Xiaomi (Настройки → Аккаунт Xiaomi) и подтвердите вход.';

  @override
  String get qrNewCode => 'Получить новый код';

  @override
  String get qrUsePassword => 'Войти по логину и паролю';

  @override
  String get qrLoading => 'Получаем код…';

  @override
  String get qrWaiting => 'Ждём подтверждения на телефоне…';

  @override
  String get qrLinkHint => 'Код не читается? Откройте ссылку на телефоне:';

  @override
  String errorConnection(Object error) {
    return 'Не удалось связаться с сервером: $error';
  }

  @override
  String get errorSessionExpired => 'Сессия истекла, войдите заново';

  @override
  String errorCloud(Object details) {
    return 'Ошибка облака Xiaomi: $details';
  }

  @override
  String errorCommandRejected(Object code) {
    return 'Устройство отклонило команду ($code)';
  }

  @override
  String get errorNoQr => 'Сервер Xiaomi не выдал QR-код';

  @override
  String get errorQrFailed => 'Вход по QR-коду не удался, получите новый код';

  @override
  String get errorQrExpired => 'QR-код устарел, получите новый';

  @override
  String get errorCodeNotRequested => 'Код не запрашивался';

  @override
  String get errorWrongCode => 'Неверный код подтверждения';

  @override
  String get errorNoSession => 'Сервер Xiaomi не вернул данные сессии';

  @override
  String get errorNoServiceToken => 'Сервер Xiaomi не выдал serviceToken';

  @override
  String get errorWrongCredentials => 'Неверный логин или пароль';

  @override
  String errorLoginRejected(Object code, Object details) {
    return 'Ошибка входа $code: $details';
  }

  @override
  String get errorUnexpectedResponse => 'Неожиданный ответ сервера Xiaomi';

  @override
  String demoDeviceName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'fan': 'Вентилятор',
      'lamp': 'Лампа у кровати',
      'humidifier': 'Увлажнитель',
      'purifier': 'Очиститель воздуха',
      'plug': 'Розетка у стола',
      'heater': 'Обогреватель',
      'vacuum': 'Робот-пылесос',
      'other': '$id',
    });
    return '$_temp0';
  }
}
