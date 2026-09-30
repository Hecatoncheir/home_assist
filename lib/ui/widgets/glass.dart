import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'reveal.dart';

/// Матовое стекло: размывает то, что под ним, и слегка тонирует цветом
/// поверхности. Подходит для панелей поверх контента.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.tint = .72,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// Насколько поверхность непрозрачна: 0 — только размытие, 1 — сплошная.
  final double tint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: tint),
            borderRadius: borderRadius,
            border: Border.all(color: c.ink.withValues(alpha: .06)),
          ),
          // Свой Material: иначе нажатия на строки списка не видны сквозь тон.
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
  }
}

/// Фон с мягкими цветными пятнами: без них стеклу нечего размывать.
/// Точки под курсором мыши разгораются — фон откликается на движение.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  final _cursor = ValueNotifier<Offset?>(null);

  /// Тот же курсор в координатах экрана — для подсветки границ.
  final _global = ValueNotifier<Offset?>(null);
  late final _presence = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void dispose() {
    _cursor.dispose();
    _global.dispose();
    _presence.dispose();
    super.dispose();
  }

  void _hover(PointerEvent event) {
    _cursor.value = event.localPosition;
    _global.value = event.position;
    _presence.forward();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MouseRegion(
      opaque: false,
      onHover: _hover,
      onExit: (_) => _presence.reverse(),
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.bg),
        child: Stack(
          children: [
            _Glow(
              color: c.glowA.withValues(alpha: .28),
              alignment: const Alignment(1.1, -1.1),
            ),
            _Glow(
              color: c.accent.withValues(alpha: .16),
              alignment: const Alignment(-1.2, 1.1),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(painter: _DotGrid(c.ink)),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _DotSpotlight(
                      // В светлой теме точки у курсора — тёплые, как блик краёв.
                      color: Theme.of(context).brightness == Brightness.light
                          ? c.glowB
                          : c.ink,
                      cursor: _cursor,
                      presence: _presence,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CursorScope(
                position: _global,
                presence: _presence,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Точки той же сетки возле курсора: крупнее и ярче, к краю круга гаснут.
class _DotSpotlight extends CustomPainter {
  _DotSpotlight({
    required this.color,
    required this.cursor,
    required this.presence,
  }) : super(repaint: Listenable.merge([cursor, presence]));

  static const _radius = 150.0;

  final Color color;
  final ValueListenable<Offset?> cursor;
  final Animation<double> presence;

  @override
  void paint(Canvas canvas, Size size) {
    final center = cursor.value;
    if (center == null || presence.value == 0) return;
    const step = _DotGrid.spacing;
    final first = Offset(
      _snap(center.dx - _radius),
      _snap(center.dy - _radius),
    );
    final paint = Paint();
    for (var y = first.dy; y <= center.dy + _radius; y += step) {
      for (var x = first.dx; x <= center.dx + _radius; x += step) {
        final distance = (Offset(x, y) - center).distance;
        if (distance > _radius) continue;
        final t = 1 - distance / _radius;
        final eased = t * t * (3 - 2 * t);
        paint.color = color.withValues(alpha: .38 * eased * presence.value);
        canvas.drawCircle(Offset(x, y), 1 + 1.4 * eased, paint);
      }
    }
  }

  /// Ближайший узел сетки не левее и не выше [value].
  static double _snap(double value) {
    const step = _DotGrid.spacing;
    return ((value - step / 2) / step).ceil() * step + step / 2;
  }

  @override
  bool shouldRepaint(_DotSpotlight old) => old.color != color;
}

/// Сетка мелких точек одного цвета: ярче у верхнего правого угла,
/// где тёплое пятно, и почти исчезает к противоположному.
class _DotGrid extends CustomPainter {
  const _DotGrid(this.color);

  static const spacing = 11.0;
  static const _bands = 6;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width, 0);
    final reach = size.longestSide;
    final bands = List.generate(_bands, (_) => <Offset>[]);
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        final point = Offset(x, y);
        final fade = 1 - ((point - origin).distance / reach).clamp(0.0, 1.0);
        bands[(fade * (_bands - 1)).round()].add(point);
      }
    }
    for (var band = 0; band < _bands; band++) {
      final strength = band / (_bands - 1);
      final paint = Paint()
        ..color = color.withValues(alpha: .03 + .09 * strength)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawPoints(ui.PointMode.points, bands[band], paint);
    }
  }

  @override
  bool shouldRepaint(_DotGrid old) => old.color != color;
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.alignment});

  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: alignment,
            radius: .9,
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    ),
  );
}
