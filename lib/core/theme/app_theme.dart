import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const background = Color(0xFF0A0A1A);
  static const panel = Color(0xFF12122A);
  static const border = Color(0xFF2A2A5A);
  static const blue = Color(0xFF4FC3F7);
  static const green = Color(0xFF69F0AE);
  static const purple = Color(0xFFCE93D8);
  static const gold = Color(0xFFFFD54F);
  static const red = Color(0xFFEF5350);
  static const text = Color(0xFFE8EAF6);
  static const muted = Color(0xFF7986CB);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: blue,
        secondary: green,
        tertiary: purple,
        surface: panel,
        onSurface: text,
        error: red,
      ),
      textTheme: GoogleFonts.exo2TextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: text, displayColor: text),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: background,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  static TextStyle get titleStyle => GoogleFonts.orbitron(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: text,
      );

  static TextStyle get scoreStyle => GoogleFonts.orbitron(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: gold,
      );

  static TextStyle get hudStyle => GoogleFonts.orbitron(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: text,
      );
}
