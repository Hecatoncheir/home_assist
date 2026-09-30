import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @auto.
  ///
  /// In ru, this message translates to:
  /// **'Авто'**
  String get auto;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get back;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @yes.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get no;

  /// No description provided for @navHome.
  ///
  /// In ru, this message translates to:
  /// **'Дом'**
  String get navHome;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @sectionAccounts.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунты Xiaomi'**
  String get sectionAccounts;

  /// No description provided for @sectionAppearance.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get sectionAppearance;

  /// No description provided for @sectionLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get sectionLanguage;

  /// No description provided for @sectionRegions.
  ///
  /// In ru, this message translates to:
  /// **'Какие регионы опрашивать'**
  String get sectionRegions;

  /// No description provided for @themeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get themeDark;

  /// No description provided for @regionsHint.
  ///
  /// In ru, this message translates to:
  /// **'Изменение применится при следующем обновлении списка.'**
  String get regionsHint;

  /// No description provided for @addAccount.
  ///
  /// In ru, this message translates to:
  /// **'Добавить аккаунт'**
  String get addAccount;

  /// No description provided for @removeAccount.
  ///
  /// In ru, this message translates to:
  /// **'Убрать аккаунт'**
  String get removeAccount;

  /// No description provided for @removeAccountTitle.
  ///
  /// In ru, this message translates to:
  /// **'Убрать аккаунт?'**
  String get removeAccountTitle;

  /// No description provided for @removeAccountBody.
  ///
  /// In ru, this message translates to:
  /// **'{account}\n\nЕго устройства пропадут из списка. Сами устройства и аккаунт Xiaomi не изменятся.'**
  String removeAccountBody(Object account);

  /// No description provided for @remove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать'**
  String get remove;

  /// No description provided for @logoutDemo.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из демо'**
  String get logoutDemo;

  /// No description provided for @logoutAll.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из всех аккаунтов'**
  String get logoutAll;

  /// No description provided for @logoutAccount.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта'**
  String get logoutAccount;

  /// No description provided for @demoAccount.
  ///
  /// In ru, this message translates to:
  /// **'Демо'**
  String get demoAccount;

  /// No description provided for @uiScale.
  ///
  /// In ru, this message translates to:
  /// **'Масштаб интерфейса'**
  String get uiScale;

  /// No description provided for @zoomOut.
  ///
  /// In ru, this message translates to:
  /// **'Уменьшить (Ctrl + −)'**
  String get zoomOut;

  /// No description provided for @zoomIn.
  ///
  /// In ru, this message translates to:
  /// **'Увеличить (Ctrl + +)'**
  String get zoomIn;

  /// No description provided for @regionName.
  ///
  /// In ru, this message translates to:
  /// **'{region, select, cn{Китай} ru{Россия} de{Европа} us{США} sg{Сингапур} i2{Индия} tw{Тайвань} other{{region}}}'**
  String regionName(String region);

  /// No description provided for @greetingNight.
  ///
  /// In ru, this message translates to:
  /// **'Доброй ночи'**
  String get greetingNight;

  /// No description provided for @greetingMorning.
  ///
  /// In ru, this message translates to:
  /// **'Доброе утро'**
  String get greetingMorning;

  /// No description provided for @greetingDay.
  ///
  /// In ru, this message translates to:
  /// **'Добрый день'**
  String get greetingDay;

  /// No description provided for @greetingEvening.
  ///
  /// In ru, this message translates to:
  /// **'Добрый вечер'**
  String get greetingEvening;

  /// No description provided for @devicesSummary.
  ///
  /// In ru, this message translates to:
  /// **'В сети {online} из {total} · регионов: {regions}'**
  String devicesSummary(Object online, Object total, Object regions);

  /// No description provided for @refreshList.
  ///
  /// In ru, this message translates to:
  /// **'Обновить список'**
  String get refreshList;

  /// No description provided for @regionUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'недоступен: {error}'**
  String regionUnavailable(Object error);

  /// No description provided for @filterAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get filterAll;

  /// No description provided for @noDevices.
  ///
  /// In ru, this message translates to:
  /// **'Устройства не найдены'**
  String get noDevices;

  /// No description provided for @statusOffline.
  ///
  /// In ru, this message translates to:
  /// **'Не в сети'**
  String get statusOffline;

  /// No description provided for @statusOn.
  ///
  /// In ru, this message translates to:
  /// **'Включено'**
  String get statusOn;

  /// No description provided for @statusOff.
  ///
  /// In ru, this message translates to:
  /// **'Выключено'**
  String get statusOff;

  /// No description provided for @statusOnline.
  ///
  /// In ru, this message translates to:
  /// **'В сети'**
  String get statusOnline;

  /// No description provided for @infoModel.
  ///
  /// In ru, this message translates to:
  /// **'Модель'**
  String get infoModel;

  /// No description provided for @infoRegion.
  ///
  /// In ru, this message translates to:
  /// **'Регион'**
  String get infoRegion;

  /// No description provided for @infoAccount.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get infoAccount;

  /// No description provided for @exploreDevice.
  ///
  /// In ru, this message translates to:
  /// **'Исследовать устройство'**
  String get exploreDevice;

  /// No description provided for @direction.
  ///
  /// In ru, this message translates to:
  /// **'Направление'**
  String get direction;

  /// No description provided for @turnOnToRotate.
  ///
  /// In ru, this message translates to:
  /// **'Включите вентилятор, чтобы повернуть его.'**
  String get turnOnToRotate;

  /// No description provided for @noSpec.
  ///
  /// In ru, this message translates to:
  /// **'Для этой модели нет опубликованной спецификации, поэтому управлять ею пока нельзя.'**
  String get noSpec;

  /// No description provided for @loadingSpec.
  ///
  /// In ru, this message translates to:
  /// **'Загружаем описание устройства…'**
  String get loadingSpec;

  /// No description provided for @slower.
  ///
  /// In ru, this message translates to:
  /// **'Медленнее'**
  String get slower;

  /// No description provided for @faster.
  ///
  /// In ru, this message translates to:
  /// **'Быстрее'**
  String get faster;

  /// No description provided for @speed.
  ///
  /// In ru, this message translates to:
  /// **'скорость'**
  String get speed;

  /// No description provided for @unitSeconds.
  ///
  /// In ru, this message translates to:
  /// **'с'**
  String get unitSeconds;

  /// No description provided for @unitMinutes.
  ///
  /// In ru, this message translates to:
  /// **'мин'**
  String get unitMinutes;

  /// No description provided for @unitHours.
  ///
  /// In ru, this message translates to:
  /// **'ч'**
  String get unitHours;

  /// No description provided for @unitWatt.
  ///
  /// In ru, this message translates to:
  /// **'Вт'**
  String get unitWatt;

  /// No description provided for @unitLux.
  ///
  /// In ru, this message translates to:
  /// **'лк'**
  String get unitLux;

  /// No description provided for @calibrate.
  ///
  /// In ru, this message translates to:
  /// **'Калибровка'**
  String get calibrate;

  /// No description provided for @swingRecalibrate.
  ///
  /// In ru, this message translates to:
  /// **'Поехал не туда — пересчитать'**
  String get swingRecalibrate;

  /// No description provided for @swingHoldTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Держите, пока вентилятор стоит у этого края'**
  String get swingHoldTooltip;

  /// No description provided for @swingRelease.
  ///
  /// In ru, this message translates to:
  /// **'Отпустите, как только вентилятор тронется от края… {seconds} с'**
  String swingRelease(Object seconds);

  /// No description provided for @swingNotCounted.
  ///
  /// In ru, this message translates to:
  /// **'Не засчитано: кнопку другого края нужно зажать, как только вентилятор замрёт у него, а держать — пока стоит.'**
  String get swingNotCounted;

  /// No description provided for @swingOtherEdge.
  ///
  /// In ru, this message translates to:
  /// **'Теперь зажмите кнопку другого края, как только вентилятор замрёт у него, и отпустите, когда тронется.'**
  String get swingOtherEdge;

  /// No description provided for @swingCalibrationIntro.
  ///
  /// In ru, this message translates to:
  /// **'Калибровка. Когда вентилятор замрёт у края, зажмите кнопку этого края и отпустите, как только он тронется. Затем то же у другого края.'**
  String get swingCalibrationIntro;

  /// No description provided for @swingLost.
  ///
  /// In ru, this message translates to:
  /// **'Положение сбилось: качание включали не из приложения. Нажмите «Калибровка» и отметьте один край.'**
  String get swingLost;

  /// No description provided for @swingTurning.
  ///
  /// In ru, this message translates to:
  /// **'Поворачиваю…'**
  String get swingTurning;

  /// No description provided for @swingReady.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на дугу, чтобы повернуть вентилятор. Проход — {sweep} с, пауза у края — {dwell} с.'**
  String swingReady(Object sweep, Object dwell);

  /// No description provided for @swingStatusHolding.
  ///
  /// In ru, this message translates to:
  /// **'стоит у края'**
  String get swingStatusHolding;

  /// No description provided for @swingStatusWaitingEdge.
  ///
  /// In ru, this message translates to:
  /// **'ждём края'**
  String get swingStatusWaitingEdge;

  /// No description provided for @swingStatusNoData.
  ///
  /// In ru, this message translates to:
  /// **'нет данных'**
  String get swingStatusNoData;

  /// No description provided for @swingStatusTurning.
  ///
  /// In ru, this message translates to:
  /// **'поворот'**
  String get swingStatusTurning;

  /// No description provided for @swingStatusSwinging.
  ///
  /// In ru, this message translates to:
  /// **'качается'**
  String get swingStatusSwinging;

  /// No description provided for @swingStatusStill.
  ///
  /// In ru, this message translates to:
  /// **'стоит'**
  String get swingStatusStill;

  /// No description provided for @probeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Исследование: {device}'**
  String probeTitle(Object device);

  /// No description provided for @probeIntro.
  ///
  /// In ru, this message translates to:
  /// **'Приложение спрашивает у устройства свойства siid 1–{maxSiid} × piid 1–{maxPiid}, в том числе те, которых нет в спецификации. Только чтение: устройство ничего не меняет.'**
  String probeIntro(Object maxSiid, Object maxPiid);

  /// No description provided for @probeWatch.
  ///
  /// In ru, this message translates to:
  /// **'Следить за изменениями'**
  String get probeWatch;

  /// No description provided for @probeWatchHint.
  ///
  /// In ru, this message translates to:
  /// **'Раз в 2 секунды. Нажимайте кнопки на устройстве или в Mi Home и смотрите, какие значения меняются.'**
  String get probeWatchHint;

  /// No description provided for @probeScanning.
  ///
  /// In ru, this message translates to:
  /// **'Опрашиваю siid {siid} из {maxSiid}…'**
  String probeScanning(Object siid, Object maxSiid);

  /// No description provided for @probeScan.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать'**
  String get probeScan;

  /// No description provided for @probeRescan.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать заново'**
  String get probeRescan;

  /// No description provided for @probeFound.
  ///
  /// In ru, this message translates to:
  /// **'Найдено свойств: {count}, из них нет в спецификации: {hidden}.'**
  String probeFound(Object count, Object hidden);

  /// No description provided for @probeFailedSiids.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при опросе siid: {siids}'**
  String probeFailedSiids(Object siids);

  /// No description provided for @probeChanges.
  ///
  /// In ru, this message translates to:
  /// **'Изменения'**
  String get probeChanges;

  /// No description provided for @probeNotInSpec.
  ///
  /// In ru, this message translates to:
  /// **'нет в спецификации'**
  String get probeNotInSpec;

  /// No description provided for @probeReadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать: {error}'**
  String probeReadFailed(Object error);

  /// No description provided for @probeCopy.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать отчёт'**
  String get probeCopy;

  /// No description provided for @probeCopied.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт скопирован'**
  String get probeCopied;

  /// No description provided for @probeReportTitle.
  ///
  /// In ru, this message translates to:
  /// **'{device} · {model} · регион {region}'**
  String probeReportTitle(Object device, Object model, Object region);

  /// No description provided for @loginTitle.
  ///
  /// In ru, this message translates to:
  /// **'Весь дом в одном списке'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Устройства Xiaomi из всех регионов. Пароль не сохраняется.'**
  String get loginSubtitle;

  /// No description provided for @loginUser.
  ///
  /// In ru, this message translates to:
  /// **'Почта, телефон или ID'**
  String get loginUser;

  /// No description provided for @loginPassword.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get loginPassword;

  /// No description provided for @loginCaptcha.
  ///
  /// In ru, this message translates to:
  /// **'Текст с картинки'**
  String get loginCaptcha;

  /// No description provided for @loginCodeEmail.
  ///
  /// In ru, this message translates to:
  /// **'Код из письма'**
  String get loginCodeEmail;

  /// No description provided for @loginCodeSms.
  ///
  /// In ru, this message translates to:
  /// **'Код из SMS'**
  String get loginCodeSms;

  /// No description provided for @loginSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get loginSubmit;

  /// No description provided for @loginContinue.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get loginContinue;

  /// No description provided for @loginBusy.
  ///
  /// In ru, this message translates to:
  /// **'Входим…'**
  String get loginBusy;

  /// No description provided for @loginWithQr.
  ///
  /// In ru, this message translates to:
  /// **'Войти по QR-коду'**
  String get loginWithQr;

  /// No description provided for @loginDemo.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть демо без аккаунта'**
  String get loginDemo;

  /// No description provided for @backToSettings.
  ///
  /// In ru, this message translates to:
  /// **'К настройкам'**
  String get backToSettings;

  /// No description provided for @qrInstructions.
  ///
  /// In ru, this message translates to:
  /// **'Отсканируйте код в приложении Mi Home или на телефоне Xiaomi (Настройки → Аккаунт Xiaomi) и подтвердите вход.'**
  String get qrInstructions;

  /// No description provided for @qrNewCode.
  ///
  /// In ru, this message translates to:
  /// **'Получить новый код'**
  String get qrNewCode;

  /// No description provided for @qrUsePassword.
  ///
  /// In ru, this message translates to:
  /// **'Войти по логину и паролю'**
  String get qrUsePassword;

  /// No description provided for @qrLoading.
  ///
  /// In ru, this message translates to:
  /// **'Получаем код…'**
  String get qrLoading;

  /// No description provided for @qrWaiting.
  ///
  /// In ru, this message translates to:
  /// **'Ждём подтверждения на телефоне…'**
  String get qrWaiting;

  /// No description provided for @qrLinkHint.
  ///
  /// In ru, this message translates to:
  /// **'Код не читается? Откройте ссылку на телефоне:'**
  String get qrLinkHint;

  /// No description provided for @errorConnection.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось связаться с сервером: {error}'**
  String errorConnection(Object error);

  /// No description provided for @errorSessionExpired.
  ///
  /// In ru, this message translates to:
  /// **'Сессия истекла, войдите заново'**
  String get errorSessionExpired;

  /// No description provided for @errorCloud.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка облака Xiaomi: {details}'**
  String errorCloud(Object details);

  /// No description provided for @errorCommandRejected.
  ///
  /// In ru, this message translates to:
  /// **'Устройство отклонило команду ({code})'**
  String errorCommandRejected(Object code);

  /// No description provided for @errorNoQr.
  ///
  /// In ru, this message translates to:
  /// **'Сервер Xiaomi не выдал QR-код'**
  String get errorNoQr;

  /// No description provided for @errorQrFailed.
  ///
  /// In ru, this message translates to:
  /// **'Вход по QR-коду не удался, получите новый код'**
  String get errorQrFailed;

  /// No description provided for @errorQrExpired.
  ///
  /// In ru, this message translates to:
  /// **'QR-код устарел, получите новый'**
  String get errorQrExpired;

  /// No description provided for @errorCodeNotRequested.
  ///
  /// In ru, this message translates to:
  /// **'Код не запрашивался'**
  String get errorCodeNotRequested;

  /// No description provided for @errorWrongCode.
  ///
  /// In ru, this message translates to:
  /// **'Неверный код подтверждения'**
  String get errorWrongCode;

  /// No description provided for @errorNoSession.
  ///
  /// In ru, this message translates to:
  /// **'Сервер Xiaomi не вернул данные сессии'**
  String get errorNoSession;

  /// No description provided for @errorNoServiceToken.
  ///
  /// In ru, this message translates to:
  /// **'Сервер Xiaomi не выдал serviceToken'**
  String get errorNoServiceToken;

  /// No description provided for @errorWrongCredentials.
  ///
  /// In ru, this message translates to:
  /// **'Неверный логин или пароль'**
  String get errorWrongCredentials;

  /// No description provided for @errorLoginRejected.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка входа {code}: {details}'**
  String errorLoginRejected(Object code, Object details);

  /// No description provided for @errorUnexpectedResponse.
  ///
  /// In ru, this message translates to:
  /// **'Неожиданный ответ сервера Xiaomi'**
  String get errorUnexpectedResponse;

  /// No description provided for @demoDeviceName.
  ///
  /// In ru, this message translates to:
  /// **'{id, select, fan{Вентилятор} lamp{Лампа у кровати} humidifier{Увлажнитель} purifier{Очиститель воздуха} plug{Розетка у стола} heater{Обогреватель} vacuum{Робот-пылесос} other{{id}}}'**
  String demoDeviceName(String id);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
