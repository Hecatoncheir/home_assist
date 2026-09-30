import 'package:flutter/widgets.dart';

import '../core/cloud/mi_cloud_client.dart';
import '../core/cloud/xiaomi_login.dart';
import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Языки в настройках: код и название на самом этом языке.
const languages = [
  (code: 'ru', name: 'Русский'),
  (code: 'en', name: 'English'),
  (code: 'zh', name: '中文'),
];

/// Понятный пользователю текст ошибки из ядра.
String describeError(AppLocalizations l, Object error) => switch (error) {
  LoginException() => _loginError(l, error),
  SessionExpiredException() => l.errorSessionExpired,
  CommandRejectedException(:final code) => l.errorCommandRejected('$code'),
  CloudException(:final details) => l.errorCloud(details),
  _ => l.errorConnection('$error'),
};

String _loginError(AppLocalizations l, LoginException error) =>
    switch (error.failure) {
      LoginFailure.noQrCode => l.errorNoQr,
      LoginFailure.qrFailed => l.errorQrFailed,
      LoginFailure.qrExpired => l.errorQrExpired,
      LoginFailure.codeNotRequested => l.errorCodeNotRequested,
      LoginFailure.wrongCode => l.errorWrongCode,
      LoginFailure.noSession => l.errorNoSession,
      LoginFailure.noServiceToken => l.errorNoServiceToken,
      LoginFailure.wrongCredentials => l.errorWrongCredentials,
      LoginFailure.rejected => l.errorLoginRejected(
        '${error.code}',
        error.details,
      ),
      LoginFailure.unexpectedResponse => l.errorUnexpectedResponse,
    };
