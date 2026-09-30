import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Общий вид круговых регуляторов: дуга из делений на 270° вокруг
/// выпуклой «ручки», по краям дуги — круглые кнопки.
/// Положение на дуге — доля 0…1: 0 — левый нижний край, 1 — правый нижний.
class GaugeGeometry {
  const GaugeGeometry(this.size);

  static const _start = 135 * pi / 180;
  static const _sweep = 270 * pi / 180;

  final double size;

  Offset get center => Offset(size / 2, size / 2);
  double get outer => size / 2 - 4;
  double get inner => outer - 18;
  double get knob => inner - 16;

  double angleAt(double at) => _start + at * _sweep;

  Offset pointAt(double at, double radius) {
    final angle = angleAt(at);
    return center + Offset(cos(angle), sin(angle)) * radius;
  }

  /// Доля дуги под точкой; в промежутке снизу — ближайший край.
  double positionAt(Offset point) {
    final delta = point - center;
    final angle = atan2(delta.dy, delta.dx);
    final fromStart = (angle - _start) % (2 * pi);
    if (fromStart <= _sweep) return fromStart / _sweep;
    final pastEnd = fromStart - _sweep;
    return pastEnd < (2 * pi - _sweep) / 2 ? 1 : 0;
  }
}

/// Дуга из делений. [intensity] — насколько ярко горит деление в точке
/// 0…1: 0 — серое, 1 — тёплый цвет градиента.
class GaugeRingPainter extends CustomPainter {
  const GaugeRingPainter({
    required this.geometry,
    required this.colors,
    required this.intensity,
    this.ticks = 36,
    this.target,
  });

  final GaugeGeometry geometry;
  final HomeColors colors;
  final double Function(double at) intensity;
  final int ticks;

  /// Отметка цели снаружи дуги.
  final double? target;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i <= ticks; i++) {
      final at = i / ticks;
      final lit = Color.lerp(colors.glowA, colors.glowB, at)!;
      final paint = Paint()
        ..color = Color.lerp(colors.line, lit, intensity(at).clamp(0.0, 1.0))!
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        geometry.pointAt(at, geometry.inner + 3),
        geometry.pointAt(at, geometry.outer - 3),
        paint,
      );
    }
    final target = this.target;
    if (target == null) return;
    canvas.drawCircle(
      geometry.pointAt(target, geometry.outer + 1),
      4,
      Paint()..color = colors.accent,
    );
  }

  @override
  bool shouldRepaint(GaugeRingPainter old) => true;
}

/// Выпуклая «ручка» в центре с отметкой положения по краю.
class GaugeKnob extends StatelessWidget {
  const GaugeKnob({
    super.key,
    required this.geometry,
    required this.child,
    this.marker,
  });

  final GaugeGeometry geometry;
  final Widget child;

  /// Положение отметки 0…1; `null` — отметки нет.
  final double? marker;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = geometry.knob;
    final marker = this.marker;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.tile,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? .45 : .12),
                offset: const Offset(6, 8),
                blurRadius: 18,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: dark ? .04 : .9),
                offset: const Offset(-6, -6),
                blurRadius: 16,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: child,
        ),
        if (marker != null)
          Transform.translate(
            offset: geometry.pointAt(marker, radius - 16) - geometry.center,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.glowB,
                boxShadow: [BoxShadow(color: c.glowB, blurRadius: 8)],
              ),
            ),
          ),
      ],
    );
  }
}

/// Состояние кнопки: держат, засчитано, не засчитано.
enum GaugeButtonState { idle, holding, accepted, rejected }

/// Маленькая круглая кнопка у края дуги.
class GaugeButton extends StatelessWidget {
  const GaugeButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.onHoldStart,
    this.onHoldEnd,
    this.state = GaugeButtonState.idle,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Для кнопок, которые держат: нажали и отпустили.
  final VoidCallback? onHoldStart;
  final VoidCallback? onHoldEnd;
  final GaugeButtonState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null || onHoldStart != null;
    final (background, foreground, glyph) = switch (state) {
      GaugeButtonState.holding => (c.glowB, c.glowInk, icon),
      GaugeButtonState.accepted => (c.ok, Colors.white, Icons.check),
      GaugeButtonState.rejected => (c.bad, Colors.white, Icons.close),
      GaugeButtonState.idle => (c.tile, enabled ? c.glowB : c.line, icon),
    };
    return Tooltip(
      message: tooltip,
      child: Listener(
        onPointerDown: (_) => onHoldStart?.call(),
        onPointerUp: (_) => onHoldEnd?.call(),
        onPointerCancel: (_) => onHoldEnd?.call(),
        child: GestureDetector(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .12),
                  offset: const Offset(0, 3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                glyph,
                key: ValueKey(glyph),
                size: 22,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Раскладка регулятора: дуга с ручкой и две кнопки у нижних краёв дуги.
class GaugeLayout extends StatelessWidget {
  const GaugeLayout({
    super.key,
    required this.geometry,
    required this.ring,
    required this.knob,
    required this.left,
    required this.right,
    this.onAim,
    this.onRelease,
  });

  final GaugeGeometry geometry;
  final GaugeRingPainter ring;
  final Widget knob;
  final Widget left;
  final Widget right;

  /// Палец над дугой: доля 0…1.
  final ValueChanged<double>? onAim;
  final VoidCallback? onRelease;

  @override
  Widget build(BuildContext context) {
    final size = geometry.size;
    final aim = onAim;
    final release = onRelease;
    return SizedBox(
      width: size,
      // Кнопки стоят чуть ниже дуги, чтобы не заслонять крайние деления.
      height: size + 18,
      child: Stack(
        children: [
          GestureDetector(
            onTapDown: aim == null
                ? null
                : (d) => aim(geometry.positionAt(d.localPosition)),
            onTapUp: release == null ? null : (_) => release(),
            onPanUpdate: aim == null
                ? null
                : (d) => aim(geometry.positionAt(d.localPosition)),
            onPanEnd: release == null ? null : (_) => release(),
            child: CustomPaint(size: Size.square(size), painter: ring),
          ),
          Positioned.fromRect(
            rect: Offset.zero & Size.square(size),
            child: Center(child: knob),
          ),
          Positioned(left: 4, bottom: 0, child: left),
          Positioned(right: 4, bottom: 0, child: right),
        ],
      ),
    );
  }
}
