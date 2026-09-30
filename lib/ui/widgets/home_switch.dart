import 'package:flutter/material.dart';

import '../theme.dart';

/// Переключатель как в прототипе: круглый белый бегунок на цветной дорожке.
class HomeSwitch extends StatelessWidget {
  const HomeSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.onGlow = false,
  });

  final bool value;

  /// `null` — переключатель недоступен.
  final ValueChanged<bool>? onChanged;

  /// Стоит на светящейся плитке: включённая дорожка тогда тёмно-янтарная.
  final bool onGlow;

  Color _track(HomeColors c) {
    if (!value) return c.line;
    return onGlow ? c.glowInk.withValues(alpha: .55) : c.accent;
  }

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged(!value),
        child: Opacity(
          opacity: onChanged == null ? .4 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 46,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _track(context.colors),
              borderRadius: BorderRadius.circular(99),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: const _Thumb(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb();

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
      ],
    ),
  );
}

/// Строка списка с [HomeSwitch] справа; нажатие на строку тоже переключает.
class HomeSwitchTile extends StatelessWidget {
  const HomeSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.contentPadding,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return ListTile(
      contentPadding: contentPadding,
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: HomeSwitch(value: value, onChanged: onChanged),
      onTap: onChanged == null ? null : () => onChanged(!value),
    );
  }
}
