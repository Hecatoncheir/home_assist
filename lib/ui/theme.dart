import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Палитра приложения. Идея — дом вечером: включённое устройство светится
/// тёплым (`glow*`), всё остальное остаётся холодным и спокойным.
class HomeColors extends ThemeExtension<HomeColors> {
  const HomeColors({
    required this.bg,
    required this.surface,
    required this.tile,
    required this.ink,
    required this.muted,
    required this.line,
    required this.glowA,
    required this.glowB,
    required this.glowInk,
    required this.accent,
    required this.onAccent,
    required this.ok,
    required this.bad,
    required this.badSoft,
  });

  static const light = HomeColors(
    bg: Color(0xFFE7ECF1),
    surface: Color(0xFFF6F8FA),
    tile: Color(0xFFFFFFFF),
    ink: Color(0xFF15202B),
    muted: Color(0xFF5C6978),
    line: Color(0xFFD3DBE3),
    glowA: Color(0xFFFFD27A),
    glowB: Color(0xFFFFAA4C),
    glowInk: Color(0xFF3F2600),
    accent: Color(0xFF1B6C88),
    onAccent: Color(0xFFFFFFFF),
    ok: Color(0xFF24925F),
    bad: Color(0xFFC2412C),
    badSoft: Color(0xFFFBE6E1),
  );

  static const dark = HomeColors(
    bg: Color(0xFF0D131A),
    surface: Color(0xFF141C26),
    tile: Color(0xFF1A2430),
    ink: Color(0xFFE7EDF3),
    muted: Color(0xFF8B99AA),
    line: Color(0xFF293543),
    glowA: Color(0xFFFFCB70),
    glowB: Color(0xFFFF9D3F),
    glowInk: Color(0xFF2E1B00),
    accent: Color(0xFF6FC6DF),
    onAccent: Color(0xFF06222C),
    ok: Color(0xFF4CC38A),
    bad: Color(0xFFFF8A73),
    badSoft: Color(0xFF3A1F1B),
  );

  final Color bg, surface, tile, ink, muted, line;
  final Color glowA, glowB, glowInk;
  final Color accent, onAccent, ok, bad, badSoft;

  LinearGradient get glow => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [glowA, glowB],
  );

  @override
  HomeColors copyWith() => this;

  @override
  HomeColors lerp(HomeColors? other, double t) =>
      other == null || t < .5 ? this : other;
}

extension HomeTheme on BuildContext {
  HomeColors get colors => Theme.of(this).extension<HomeColors>()!;

  /// Заголовки и крупные числа.
  TextStyle display(double size, {FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.unbounded(
        fontSize: size,
        fontWeight: weight,
        height: 1.15,
        color: colors.ink,
      );

  /// Технические значения: модель, DID, IP.
  TextStyle mono({double size = 12, Color? color}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, color: color ?? colors.muted);
}

const tileRadius = BorderRadius.all(Radius.circular(22));

ThemeData buildTheme(HomeColors c, Brightness brightness) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: c.accent,
        brightness: brightness,
      ).copyWith(
        primary: c.accent,
        onPrimary: c.onAccent,
        surface: c.surface,
        onSurface: c.ink,
        error: c.bad,
        outlineVariant: c.line,
      );
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c.line),
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    extensions: [c],
    fontFamily: GoogleFonts.onest().fontFamily,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.tile,
      border: fieldBorder,
      enabledBorder: fieldBorder,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.ink,
        foregroundColor: c.bg,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.bg,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.bg,
    ),
  );
}
