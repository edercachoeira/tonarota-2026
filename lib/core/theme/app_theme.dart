import 'package:flutter/material.dart';

class AppTheme {
  // Cores Harmoniosas Luxury Tech
  static const Color backgroundLight = Color(0xFFF1F5F9); // Slate-100 (mais contraste para os cards brancos)
  static const Color surfaceLight = Colors.white;
  static const Color primaryTeal = Color(0xFF0F766E); // Teal-700 (um tom mais fechado e premium)
  static const Color secondaryAmber = Color(0xFFD97706); // Amber-600
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate-900
  static const Color textSecondaryLight = Color(0xFF475569); // Slate-600
  static const Color borderLight = Color(0xFFE2E8F0); // Slate-200

  // Dark Mode mais profundo
  static const Color backgroundDark = Color(0xFF0A0F1C); // Quase preto azulado profundo
  static const Color surfaceDark = Color(0xFF141D2F); // Levemente mais claro
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate-50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate-400
  static const Color borderDark = Color(0xFF1E293B); // Slate-800

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Outfit',
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        secondary: secondaryAmber,
        surface: surfaceLight,
        error: Colors.redAccent,
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.04), // Sombra muito sutil e premium
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: borderLight, width: 0.5),
          borderRadius: BorderRadius.circular(24), // Bordas mais arredondadas (Luxo)
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // AppBar será flutuante e gerido no layout
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryLight),
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 20,
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: textPrimaryLight, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        titleLarge: TextStyle(color: textPrimaryLight, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        bodyLarge: TextStyle(color: textSecondaryLight, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(color: textSecondaryLight, fontWeight: FontWeight.w400),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC), // Fundo do input levemente diferente do card
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondaryLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryTeal.withOpacity(0.4), // Glow effect
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Outfit',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryTeal,
        secondary: secondaryAmber,
        surface: surfaceDark,
        error: Colors.redAccent,
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 12,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: borderDark, width: 1),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryDark),
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 20,
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: textPrimaryDark, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        titleLarge: TextStyle(color: textPrimaryDark, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        bodyLarge: TextStyle(color: textSecondaryDark, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(color: textSecondaryDark, fontWeight: FontWeight.w400),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondaryDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: primaryTeal.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
