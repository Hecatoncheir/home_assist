import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme.dart';

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
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
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
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Сетка мелких точек одного цвета: ярче у верхнего правого угла,
/// где тёплое пятно, и почти исчезает к противоположному.
class _DotGrid extends CustomPainter {
  const _DotGrid(this.color);

  static const _spacing = 11.0;
  static const _bands = 6;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width, 0);
    final reach = size.longestSide;
    final bands = List.generate(_bands, (_) => <Offset>[]);
    for (var y = _spacing / 2; y < size.height; y += _spacing) {
      for (var x = _spacing / 2; x < size.width; x += _spacing) {
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
