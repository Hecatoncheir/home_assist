import 'package:flutter/material.dart';

import '../theme.dart';

/// Где сейчас курсор мыши (в координатах экрана) и насколько он «присутствует»:
/// 1 — над окном, плавно до 0 — ушёл. Даёт [AmbientBackground].
class CursorScope extends InheritedWidget {
  const CursorScope({
    super.key,
    required this.position,
    required this.presence,
    required super.child,
  });

  final ValueNotifier<Offset?> position;
  final Animation<double> presence;

  static CursorScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CursorScope>();

  @override
  bool updateShouldNotify(CursorScope old) =>
      old.position != position || old.presence != presence;
}

/// Тонкая граница вокруг [child], которая светлеет там, где рядом курсор.
class RevealBorder extends StatelessWidget {
  const RevealBorder({
    super.key,
    required this.borderRadius,
    required this.child,
  });

  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cursor = CursorScope.of(context);
    return CustomPaint(
      foregroundPainter: _RevealPainter(
        box: context,
        borderRadius: borderRadius,
        color: context.colors.ink,
        glow: Theme.of(context).brightness == Brightness.light
            ? context.colors.glowB
            : Colors.white,
        cursor: cursor,
      ),
      child: child,
    );
  }
}

class _RevealPainter extends CustomPainter {
  _RevealPainter({
    required this.box,
    required this.borderRadius,
    required this.color,
    required this.glow,
    required this.cursor,
  }) : super(
         repaint: cursor == null
             ? null
             : Listenable.merge([cursor.position, cursor.presence]),
       );

  /// Радиус пятна света вокруг курсора.
  static const _reach = 170.0;

  /// Контекст виджета: по нему переводим курсор в свои координаты.
  final BuildContext box;
  final BorderRadius borderRadius;
  final Color color;

  /// Цвет блика: белый в тёмной теме, тёплый оранжевый в светлой —
  /// белое на светлом не видно.
  final Color glow;
  final CursorScope? cursor;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = borderRadius.toRRect(Offset.zero & size).deflate(.6);
    canvas.drawRRect(shape, _stroke(color.withValues(alpha: .07)));
    final spot = _lightAt(size);
    if (spot == null) return;
    canvas.drawRRect(
      shape,
      _glow(spot, glow.withValues(alpha: .95), width: 1.6),
    );
  }

  Paint _glow(
    ({Offset center, double strength}) spot,
    Color tint, {
    required double width,
  }) => _stroke(Colors.white)
    ..strokeWidth = width
    ..shader = RadialGradient(
      colors: [
        tint.withValues(alpha: tint.a * spot.strength),
        tint.withValues(alpha: 0),
      ],
    ).createShader(Rect.fromCircle(center: spot.center, radius: _reach));

  /// Центр света в своих координатах и его сила; `null` — света нет.
  ({Offset center, double strength})? _lightAt(Size size) {
    final global = cursor?.position.value;
    final strength = cursor?.presence.value ?? 0;
    final render = box.findRenderObject();
    if (global == null || strength == 0 || render is! RenderBox) return null;
    if (!render.attached) return null;
    final center = render.globalToLocal(global);
    final far = !(Offset.zero & size).inflate(_reach).contains(center);
    return far ? null : (center: center, strength: strength);
  }

  Paint _stroke(Color color) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..color = color;

  @override
  bool shouldRepaint(_RevealPainter old) =>
      old.color != color ||
      old.glow != glow ||
      old.borderRadius != borderRadius ||
      old.cursor != cursor;
}
