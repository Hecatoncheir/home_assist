import 'package:flutter/material.dart';

import '../theme.dart';

/// Знак приложения: дом с четырьмя окнами, в двух горит свет.
class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dim = c.bg.withValues(alpha: .28);
    Widget pane(Color color) => Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * .07),
      ),
    );
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .22),
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: size * .06,
        crossAxisSpacing: size * .06,
        physics: const NeverScrollableScrollPhysics(),
        children: [pane(c.glowB), pane(dim), pane(dim), pane(c.glowA)],
      ),
    );
  }
}
