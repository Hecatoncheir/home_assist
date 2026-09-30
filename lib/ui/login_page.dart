import 'package:flutter/material.dart';

import '../core/accounts/session.dart';
import '../core/cloud/xiaomi_login.dart';
import '../demo/demo.dart';
import 'l10n.dart';
import 'qr_login_view.dart';
import 'theme.dart';
import 'widgets/logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onLoggedIn,
    this.onCancel,
    this.login,
  });

  final Future<void> Function(Session session) onLoggedIn;

  /// Задан, когда экран открыт для добавления ещё одного аккаунта:
  /// тогда с него можно вернуться.
  final VoidCallback? onCancel;

  /// Подменяется в тестах; по умолчанию — настоящий сервер Xiaomi.
  final XiaomiLogin? login;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final _login = widget.login ?? XiaomiLogin();
  final _user = TextEditingController();
  final _password = TextEditingController();
  final _extra = TextEditingController();

  /// Капча или двухфакторная проверка, если сервер их запросил.
  LoginStep? _step;
  Object? _error;
  bool _busy = false;

  /// Вход по QR-коду вместо логина и пароля.
  bool _qrMode = false;

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    _extra.dispose();
    super.dispose();
  }

  Future<LoginStep> _nextStep() {
    final extra = _extra.text.trim();
    if (_step is TwoFactorRequired) return _login.submitCode(extra);
    return _login.submit(
      user: _user.text.trim(),
      password: _password.text,
      captcha: extra,
    );
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final step = await _nextStep();
      _extra.clear();
      if (step is LoginSuccess) {
        final session = step.session.withLabel(_user.text.trim());
        return await widget.onLoggedIn(session);
      }
      _step = step;
    } catch (e) {
      _error = e;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 412),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.onCancel != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l.backToSettings),
                  ),
                ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Logo(size: 64),
              ),
              const SizedBox(height: 20),
              Text(l.loginTitle, style: context.display(26)),
              const SizedBox(height: 10),
              Text(l.loginSubtitle, style: TextStyle(color: c.muted)),
              const SizedBox(height: 22),
              if (_qrMode)
                QrLoginView(
                  login: _login,
                  onLoggedIn: widget.onLoggedIn,
                  onBack: () => setState(() => _qrMode = false),
                )
              else
                ..._passwordForm(c, l),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _passwordForm(HomeColors c, AppLocalizations l) {
    final step = _step;
    final error = _error;
    return [
      TextField(
        controller: _user,
        decoration: InputDecoration(labelText: l.loginUser),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _password,
        obscureText: true,
        decoration: InputDecoration(labelText: l.loginPassword),
        onSubmitted: (_) => _submit(),
      ),
      if (step is CaptchaRequired) ...[
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(step.image, height: 64),
        ),
        const SizedBox(height: 14),
        _extraField(l.loginCaptcha),
      ],
      if (step is TwoFactorRequired) ...[
        const SizedBox(height: 14),
        _extraField(step.viaEmail ? l.loginCodeEmail : l.loginCodeSms),
      ],
      if (error != null) ...[
        const SizedBox(height: 14),
        Text(describeError(l, error), style: TextStyle(color: c.bad)),
      ],
      const SizedBox(height: 18),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: Text(_busy ? l.loginBusy : _buttonLabel(l)),
      ),
      const SizedBox(height: 8),
      if (step != null)
        TextButton(onPressed: _startOver, child: Text(l.back))
      else ...[
        TextButton.icon(
          onPressed: () => setState(() => _qrMode = true),
          icon: const Icon(Icons.qr_code_2),
          label: Text(l.loginWithQr),
        ),
        if (widget.onCancel == null)
          TextButton(
            onPressed: () => widget.onLoggedIn(demoSession),
            child: Text(l.loginDemo),
          ),
      ],
    ];
  }

  /// Возврат с шага капчи или кода к вводу логина и пароля.
  void _startOver() {
    _extra.clear();
    setState(() {
      _step = null;
      _error = null;
    });
  }

  String _buttonLabel(AppLocalizations l) =>
      _step == null ? l.loginSubmit : l.loginContinue;

  Widget _extraField(String label) => TextField(
    controller: _extra,
    autofocus: true,
    decoration: InputDecoration(labelText: label),
    onSubmitted: (_) => _submit(),
  );
}
