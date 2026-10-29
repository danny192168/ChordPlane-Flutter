import 'package:flutter/material.dart';

class AppTheme {
  static const bgDeep = Color(0xFF0C0F18);
  static const bgSurface = Color(0xFF121826);
  static const bgElevated = Color(0xFF141A28);
  static const text = Color(0xFFE4E8F0);
  static const textMuted = Color(0xFF95A0B8);
  static const textFaint = Color(0xFF5A6680);
  static const accent = Color(0xFF88A9CE);
  static const accentDim = Color(0xFF567393);
  static const success = Color(0xFF6FCF97);
  static const warning = Color(0xFFF2C94C);
  static const danger = Color(0xFFEB5757);

  static ThemeData get lightTheme {
    return _theme(
      brightness: Brightness.light,
      background: const Color(0xFFECEEF3),
      surface: const Color(0xFFF5F7FA),
      elevated: const Color(0xFFE2E5EC),
      foreground: const Color(0xFF121828),
      muted: textMuted,
      faint: textFaint,
      primary: accentDim,
      primaryVariant: accent,
    );
  }

  static ThemeData get darkTheme {
    return _theme(
      brightness: Brightness.dark,
      background: bgDeep,
      surface: bgSurface,
      elevated: bgElevated,
      foreground: text,
      muted: textMuted,
      faint: textFaint,
      primary: accent,
      primaryVariant: accentDim,
    );
  }

  static ThemeData _theme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color elevated,
    required Color foreground,
    required Color muted,
    required Color faint,
    required Color primary,
    required Color primaryVariant,
  }) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: brightness == Brightness.dark ? bgDeep : Colors.white,
          secondary: primaryVariant,
          onSecondary: brightness == Brightness.dark ? text : Colors.white,
          surface: surface,
          surfaceContainer: elevated,
          surfaceContainerHigh: elevated,
          surfaceContainerHighest: elevated,
          onSurface: foreground,
          onSurfaceVariant: muted,
          outline: faint,
          error: danger,
          onError: Colors.white,
          tertiary: success,
          onTertiary: bgDeep,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      textTheme: Typography.material2021().black.apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: surface,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: faint),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primary, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStatePropertyAll(TextStyle(color: foreground)),
      ),
    );
  }
}
