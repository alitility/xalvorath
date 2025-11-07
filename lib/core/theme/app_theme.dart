import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get dark {
    const background = Color(0xFF090A0F);
    const surface = Color(0xFF11131A);
    const accent = Color(0xFF7B5CFF);
    const glow = Color(0xFF9A7BFF);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: glow,
        surface: surface,
        background: background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
      iconTheme: const IconThemeData(color: glow, size: 28),
      sliderTheme: SliderThemeData(
        thumbColor: accent,
        activeTrackColor: glow,
        inactiveTrackColor: glow.withOpacity(0.3),
        overlayColor: accent.withOpacity(0.2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          shadowColor: glow.withOpacity(0.4),
          elevation: 6,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        shadowColor: glow.withOpacity(0.3),
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
