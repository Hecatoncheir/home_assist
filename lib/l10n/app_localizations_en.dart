// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get auto => 'Auto';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get retry => 'Retry';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get navHome => 'Home';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAccounts => 'Xiaomi accounts';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get sectionRegions => 'Regions to poll';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get regionsHint =>
      'Changes apply the next time the list is refreshed.';

  @override
  String get addAccount => 'Add account';

  @override
  String get removeAccount => 'Remove account';

  @override
  String get removeAccountTitle => 'Remove account?';

  @override
  String removeAccountBody(Object account) {
    return '$account\n\nIts devices will disappear from the list. The devices themselves and the Xiaomi account stay unchanged.';
  }

  @override
  String get remove => 'Remove';

  @override
  String get logoutDemo => 'Exit demo';

  @override
  String get logoutAll => 'Sign out of all accounts';

  @override
  String get logoutAccount => 'Sign out';

  @override
  String get demoAccount => 'Demo';

  @override
  String get uiScale => 'Interface scale';

  @override
  String get zoomOut => 'Zoom out (Ctrl + −)';

  @override
  String get zoomIn => 'Zoom in (Ctrl + +)';

  @override
  String regionName(String region) {
    String _temp0 = intl.Intl.selectLogic(region, {
      'cn': 'China',
      'ru': 'Russia',
      'de': 'Europe',
      'us': 'USA',
      'sg': 'Singapore',
      'i2': 'India',
      'tw': 'Taiwan',
      'other': '$region',
    });
    return '$_temp0';
  }

  @override
  String get greetingNight => 'Good night';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingDay => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String devicesSummary(Object online, Object total, Object regions) {
    return '$online of $total online · regions: $regions';
  }

  @override
  String get refreshList => 'Refresh list';

  @override
  String regionUnavailable(Object error) {
    return 'unavailable: $error';
  }

  @override
  String get filterAll => 'All';

  @override
  String get noDevices => 'No devices found';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusOn => 'On';

  @override
  String get statusOff => 'Off';

  @override
  String get statusOnline => 'Online';

  @override
  String get infoModel => 'Model';

  @override
  String get infoRegion => 'Region';

  @override
  String get infoAccount => 'Account';

  @override
  String get exploreDevice => 'Explore device';

  @override
  String get direction => 'Direction';

  @override
  String get turnOnToRotate => 'Turn the fan on to rotate it.';

  @override
  String get noSpec =>
      'There is no published specification for this model, so it can\'t be controlled yet.';

  @override
  String get loadingSpec => 'Loading device description…';

  @override
  String get slower => 'Slower';

  @override
  String get faster => 'Faster';

  @override
  String get speed => 'speed';

  @override
  String get unitSeconds => 's';

  @override
  String get unitMinutes => 'min';

  @override
  String get unitHours => 'h';

  @override
  String get unitWatt => 'W';

  @override
  String get unitLux => 'lx';

  @override
  String get calibrate => 'Calibrate';

  @override
  String get swingRecalibrate => 'Went the wrong way — recalculate';

  @override
  String get swingHoldTooltip => 'Hold while the fan stays at this edge';

  @override
  String swingRelease(Object seconds) {
    return 'Release as soon as the fan leaves the edge… $seconds s';
  }

  @override
  String get swingNotCounted =>
      'Not counted: press the other edge\'s button as soon as the fan stops there, and hold it while it stays.';

  @override
  String get swingOtherEdge =>
      'Now press the other edge\'s button as soon as the fan stops there, and release it when the fan moves.';

  @override
  String get swingCalibrationIntro =>
      'Calibration. When the fan stops at an edge, press that edge\'s button and release it as soon as the fan moves. Then do the same at the other edge.';

  @override
  String get swingLost =>
      'Position lost: swinging was turned on outside the app. Tap “Calibrate” and mark one edge.';

  @override
  String get swingTurning => 'Turning…';

  @override
  String swingReady(Object sweep, Object dwell) {
    return 'Tap the arc to rotate the fan. Sweep — $sweep s, pause at the edge — $dwell s.';
  }

  @override
  String get swingStatusHolding => 'at the edge';

  @override
  String get swingStatusWaitingEdge => 'waiting for edge';

  @override
  String get swingStatusNoData => 'no data';

  @override
  String get swingStatusTurning => 'turning';

  @override
  String get swingStatusSwinging => 'swinging';

  @override
  String get swingStatusStill => 'still';

  @override
  String probeTitle(Object device) {
    return 'Exploring: $device';
  }

  @override
  String probeIntro(Object maxSiid, Object maxPiid) {
    return 'The app asks the device for properties siid 1–$maxSiid × piid 1–$maxPiid, including ones missing from the specification. Read only: nothing on the device changes.';
  }

  @override
  String get probeWatch => 'Watch for changes';

  @override
  String get probeWatchHint =>
      'Every 2 seconds. Press buttons on the device or in Mi Home and see which values change.';

  @override
  String probeScanning(Object siid, Object maxSiid) {
    return 'Polling siid $siid of $maxSiid…';
  }

  @override
  String get probeScan => 'Scan';

  @override
  String get probeRescan => 'Scan again';

  @override
  String probeFound(Object count, Object hidden) {
    return 'Properties found: $count, missing from the specification: $hidden.';
  }

  @override
  String probeFailedSiids(Object siids) {
    return 'Polling failed for siid: $siids';
  }

  @override
  String get probeChanges => 'Changes';

  @override
  String get probeNotInSpec => 'not in specification';

  @override
  String probeReadFailed(Object error) {
    return 'Could not read: $error';
  }

  @override
  String get probeCopy => 'Copy report';

  @override
  String get probeCopied => 'Report copied';

  @override
  String probeReportTitle(Object device, Object model, Object region) {
    return '$device · $model · region $region';
  }

  @override
  String get loginTitle => 'Your whole home in one list';

  @override
  String get loginSubtitle =>
      'Xiaomi devices from all regions. Your password is not stored.';

  @override
  String get loginUser => 'Email, phone or ID';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginCaptcha => 'Text from the image';

  @override
  String get loginCodeEmail => 'Code from the email';

  @override
  String get loginCodeSms => 'Code from the SMS';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginContinue => 'Continue';

  @override
  String get loginBusy => 'Signing in…';

  @override
  String get loginWithQr => 'Sign in with QR code';

  @override
  String get loginDemo => 'Try the demo without an account';

  @override
  String get backToSettings => 'Back to settings';

  @override
  String get qrInstructions =>
      'Scan the code in the Mi Home app or on a Xiaomi phone (Settings → Xiaomi Account) and confirm the sign-in.';

  @override
  String get qrNewCode => 'Get a new code';

  @override
  String get qrUsePassword => 'Sign in with login and password';

  @override
  String get qrLoading => 'Getting the code…';

  @override
  String get qrWaiting => 'Waiting for confirmation on the phone…';

  @override
  String get qrLinkHint =>
      'Can\'t scan the code? Open this link on your phone:';

  @override
  String errorConnection(Object error) {
    return 'Could not reach the server: $error';
  }

  @override
  String get errorSessionExpired => 'Session expired, please sign in again';

  @override
  String errorCloud(Object details) {
    return 'Xiaomi cloud error: $details';
  }

  @override
  String errorCommandRejected(Object code) {
    return 'The device rejected the command ($code)';
  }

  @override
  String get errorNoQr => 'The Xiaomi server did not return a QR code';

  @override
  String get errorQrFailed => 'QR sign-in failed, get a new code';

  @override
  String get errorQrExpired => 'The QR code has expired, get a new one';

  @override
  String get errorCodeNotRequested => 'No code was requested';

  @override
  String get errorWrongCode => 'Wrong verification code';

  @override
  String get errorNoSession => 'The Xiaomi server did not return session data';

  @override
  String get errorNoServiceToken =>
      'The Xiaomi server did not return a serviceToken';

  @override
  String get errorWrongCredentials => 'Wrong login or password';

  @override
  String errorLoginRejected(Object code, Object details) {
    return 'Sign-in error $code: $details';
  }

  @override
  String get errorUnexpectedResponse =>
      'Unexpected response from the Xiaomi server';

  @override
  String demoDeviceName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'fan': 'Fan',
      'lamp': 'Bedside lamp',
      'humidifier': 'Humidifier',
      'purifier': 'Air purifier',
      'plug': 'Desk plug',
      'heater': 'Heater',
      'vacuum': 'Robot vacuum',
      'other': '$id',
    });
    return '$_temp0';
  }
}
