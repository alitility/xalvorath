import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get dark {
    const background = Color(0xFF0B0C10);
    const surface = Color(0xFF11131A);
    const accent = Color(0xFF7B5CFF);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

