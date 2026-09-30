import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/preferences.dart';
import '../l10n.dart';
import '../theme.dart';

/// Увеличивает или уменьшает весь интерфейс: приложение раскладывается
/// в меньшем (или большем) логическом окне и растягивается на настоящее.
/// Ctrl + «+» / «−» / «0» меняют масштаб с клавиатуры.
class UiScale extends StatelessWidget {
  const UiScale({super.key, required this.prefs, required this.child});

  final Preferences prefs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scale = prefs.uiScale;
    final media = MediaQuery.of(context);
    final scaled = MediaQuery(
      data: media.copyWith(
        size: media.size / scale,
        devicePixelRatio: media.devicePixelRatio * scale,
        padding: media.padding / scale,
        viewPadding: media.viewPadding / scale,
        viewInsets: media.viewInsets / scale,
      ),
      child: child,
    );
    return CallbackShortcuts(
      bindings: _shortcuts,
      child: scale == 1
          ? scaled
          : FittedBox(
              fit: BoxFit.fill,
              alignment: Alignment.topLeft,
              child: SizedBox.fromSize(size: media.size / scale, child: scaled),
            ),
    );
  }

  Map<ShortcutActivator, VoidCallback> get _shortcuts => {
    const SingleActivator(LogicalKeyboardKey.equal, control: true):
        prefs.zoomIn,
    const SingleActivator(LogicalKeyboardKey.numpadAdd, control: true):
        prefs.zoomIn,
    const SingleActivator(LogicalKeyboardKey.minus, control: true):
        prefs.zoomOut,
    const SingleActivator(LogicalKeyboardKey.numpadSubtract, control: true):
        prefs.zoomOut,
    const SingleActivator(LogicalKeyboardKey.digit0, control: true): () =>
        prefs.uiScale = 1,
  };
}

/// Строка настроек: «−  100 %  +».
class UiScaleControl extends StatelessWidget {
  const UiScaleControl({super.key, required this.prefs});

  final Preferences prefs;

  @override
  Widget build(BuildContext context) {
    final percent = (prefs.uiScale * 100).round();
    final l = context.l10n;
    return Row(
      children: [
        Expanded(child: Text(l.uiScale)),
        IconButton.outlined(
          tooltip: l.zoomOut,
          onPressed: prefs.canZoomOut ? prefs.zoomOut : null,
          icon: const Icon(Icons.remove),
        ),
        GestureDetector(
          onTap: () => prefs.uiScale = 1,
          child: SizedBox(
            width: 64,
            child: Text(
              '$percent %',
              textAlign: TextAlign.center,
              style: context.mono(size: 14, color: context.colors.ink),
            ),
          ),
        ),
        IconButton.outlined(
          tooltip: l.zoomIn,
          onPressed: prefs.canZoomIn ? prefs.zoomIn : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
