import 'package:flutter/material.dart';

class AppTheme {
  // ── Ocean Wave Palette ────────────────────────────────────────────────────
  static const Color deepNavy = Color(0xFF142459);
  static const Color oceanBlue = Color(0xFF3B67B5);
  static const Color skyBlue = Color(0xFF82AADD);
  static const Color softLavender = Color(0xFFA395D1);
  static const Color lilacPink = Color(0xFFCFB8E8);

  // ── Semantic aliases (keep old names so screens don't break) ─────────────
  static const Color primaryColor = oceanBlue;
  static const Color accentGold = deepNavy;
  static const Color darkBrown = deepNavy;
  static const Color lightBeige = Color(0xFFEEF4FF); // soft blue-white bg
  static const Color softTan = skyBlue; // border colour
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color errorRed = Color(0xFFC62828);
  static const Color textDark = deepNavy;
  static const Color textLight = Color(0xFF5483B3);

  // ── Gradient shorthands ───────────────────────────────────────────────────
  static const LinearGradient primaryOmbre = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepNavy, oceanBlue, skyBlue],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient secondaryOmbre = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [oceanBlue, softLavender],
  );

  static const LinearGradient cardOmbre = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [oceanBlue, skyBlue],
  );

  static const LinearGradient wavesOmbre = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepNavy, oceanBlue, skyBlue, softLavender, lilacPink],
  );

  static const List<BoxShadow> modernShadow = [
    BoxShadow(color: Color(0x1A142459), blurRadius: 20, offset: Offset(0, 8)),
  ];

  // ── Material ThemeData ────────────────────────────────────────────────────
  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: oceanBlue,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: oceanBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: skyBlue, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: skyBlue, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: oceanBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textLight),
        hintStyle: const TextStyle(color: textLight),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textDark),
        bodyMedium: TextStyle(fontSize: 14, color: textLight),
      ),
    );
  }
}
