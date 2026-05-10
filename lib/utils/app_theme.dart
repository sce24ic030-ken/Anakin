import 'package:flutter/material.dart';

class AppTheme {
  static const Color _darkBackground = Color(0xFF0A0A0A);
  static const Color _darkSurface = Color(0xFF1A1A1A);
  static const Color _darkSurfaceVariant = Color(0xFF252525);
  static const Color _darkPrimary = Color(0xFFE0E0E0);
  static const Color _darkSecondary = Color(0xFF9E9E9E);
  static const Color _darkAccent = Color(0xFF4A4A4A);
  static const Color _darkDivider = Color(0xFF2C2C2C);
  static const Color _darkHighlight = Color(0xFF3A3A3A);

  static const Color _lightBackground = Color(0xFFF5F5F5);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceVariant = Color(0xFFEBEBEB);
  static const Color _lightPrimary = Color(0xFF1A1A1A);
  static const Color _lightSecondary = Color(0xFF757575);
  static const Color _lightAccent = Color(0xFFBDBDBD);
  static const Color _lightDivider = Color(0xFFE0E0E0);
  static const Color _lightHighlight = Color(0xFFD5D5D5);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        surface: _darkBackground,
        onSurface: _darkPrimary,
        primary: _darkPrimary,
        onPrimary: _darkBackground,
        secondary: _darkSecondary,
        onSecondary: _darkBackground,
        tertiary: _darkAccent,
        outline: _darkDivider,
        surfaceContainerHighest: _darkSurfaceVariant,
      ),
      scaffoldBackgroundColor: _darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _darkPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: _darkPrimary),
      ),
      cardTheme: CardTheme(
        color: _darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _darkDivider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: _darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _darkPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: _darkPrimary,
        unselectedLabelColor: _darkSecondary,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 3, color: _darkPrimary),
        ),
      ),
      iconTheme: const IconThemeData(color: _darkPrimary),
      dividerTheme: const DividerThemeData(color: _darkDivider),
      chipTheme: ChipThemeData(
        backgroundColor: _darkSurface,
        selectedColor: _darkHighlight,
        labelStyle: const TextStyle(color: _darkPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _darkDivider),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _darkPrimary,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        surface: _lightBackground,
        onSurface: _lightPrimary,
        primary: _lightPrimary,
        onPrimary: Colors.white,
        secondary: _lightSecondary,
        onSecondary: Colors.white,
        tertiary: _lightAccent,
        outline: _lightDivider,
        surfaceContainerHighest: _lightSurfaceVariant,
      ),
      scaffoldBackgroundColor: _lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _lightPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: _lightPrimary),
      ),
      cardTheme: CardTheme(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _lightDivider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _lightPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: _lightPrimary,
        unselectedLabelColor: _lightSecondary,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 3, color: _lightPrimary),
        ),
      ),
      iconTheme: const IconThemeData(color: _lightPrimary),
      dividerTheme: const DividerThemeData(color: _lightDivider),
      chipTheme: ChipThemeData(
        backgroundColor: _lightSurface,
        selectedColor: _lightHighlight,
        labelStyle: const TextStyle(color: _lightPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _lightDivider),
        ),
      ),
    );
  }
}