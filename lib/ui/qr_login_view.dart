import 'package:flutter/material.dart';

import '../core/accounts/session.dart';
import '../core/cloud/xiaomi_login.dart';
import 'l10n.dart';
import 'theme.dart';

/// Вход по QR-коду: код сканируют в Mi Home на телефоне, пароль не нужен.
class QrLoginView extends StatefulWidget {
  const QrLoginView({
    super.key,
    required this.login,
    required this.onLoggedIn,
    required this.onBack,
  });

  final XiaomiLogin login;
  final Future<void> Function(Session session) onLoggedIn;
  final VoidCallback onBack;

  @override
  State<QrLoginView> createState() => _QrLoginViewState();
}

class _QrLoginViewState extends State<QrLoginView> {
  QrChallenge? _challenge;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    widget.login.cancelQr();
    super.dispose();
  }

  /// Получает код и ждёт подтверждения; при ошибке предлагает новый код.
  Future<void> _start() async {
    setState(() {
      _challenge = null;
      _error = null;
    });
    try {
      final challenge = await widget.login.startQr();
      if (!mounted) return;
      setState(() => _challenge = challenge);
      final step = await widget.login.waitForQr(challenge);
      if (mounted && step is LoginSuccess) {
        await widget.onLoggedIn(step.session);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.qrInstructions, style: TextStyle(color: c.muted)),
        const SizedBox(height: 18),
        Center(child: _code(c)),
        const SizedBox(height: 14),
        if (error != null)
          Text(describeError(l, error), style: TextStyle(color: c.bad))
        else
          _waiting(c, l),
        const SizedBox(height: 18),
        if (error != null)
          FilledButton(onPressed: _start, child: Text(l.qrNewCode)),
        TextButton(onPressed: widget.onBack, child: Text(l.qrUsePassword)),
      ],
    );
  }

  /// Картинка на белом фоне в любой теме, иначе камера может её не прочитать.
  Widget _code(HomeColors c) {
    final challenge = _challenge;
    return Container(
      width: 240,
      height: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
      ),
      child: challenge == null
          ? const Center(child: CircularProgressIndicator())
          : Image.memory(challenge.image, fit: BoxFit.contain),
    );
  }

  Widget _waiting(HomeColors c, AppLocalizations l) {
    final url = _challenge?.loginUrl ?? '';
    return Column(
      children: [
        Text(
          _challenge == null ? l.qrLoading : l.qrWaiting,
          style: TextStyle(color: c.muted),
        ),
        if (url.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(l.qrLinkHint, style: TextStyle(color: c.muted, fontSize: 13)),
          SelectableText(
            url,
            textAlign: TextAlign.center,
            style: context.mono(size: 11),
          ),
        ],
      ],
    );
  }
}
