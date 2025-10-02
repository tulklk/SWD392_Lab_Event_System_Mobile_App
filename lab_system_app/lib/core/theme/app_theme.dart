import 'package:flutter/material.dart';

class AppTheme {
  // Modern color palette with gradients
  // FPT brand colors
  static const Color _primaryBlue = Color(0xFFFF6600); // FPT Orange
  static const Color _primaryBlueLight = Color(0xFFFF8540); // Light Orange
  static const Color _secondaryBlue = Color(0xFF1A73E8); // Brand Blue
  static const Color _accentBlue = Color(0xFF1A73E8); // Brand Blue
  
  static const Color _lightGray = Color(0xFFF8FAFC);
  static const Color _mediumGray = Color(0xFF64748B);
  static const Color _darkGray = Color(0xFF1E293B);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningOrange = Color(0xFFF59E0B);
  static const Color _errorRed = Color(0xFFEF4444);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: _primaryBlue,
        onPrimary: _white,
        secondary: _secondaryBlue,
        onSecondary: _white,
        tertiary: _primaryBlueLight,
        onTertiary: _white,
        surface: _lightGray,
        onSurface: _darkGray,
        surfaceContainerHighest: _white,
        onSurfaceVariant: _mediumGray,
        outline: const Color(0xFFE2E8F0),
        background: _lightGray,
        onBackground: _darkGray,
        error: _errorRed,
        onError: _white,
        primaryContainer: _primaryBlue.withOpacity(0.1),
        onPrimaryContainer: _primaryBlue,
        secondaryContainer: _secondaryBlue.withOpacity(0.1),
        onSecondaryContainer: _secondaryBlue,
      ),
      scaffoldBackgroundColor: _lightGray,
      appBarTheme: AppBarTheme(
        backgroundColor: _white,
        foregroundColor: _darkGray,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.1),
        titleTextStyle: TextStyle(
          color: _darkGray,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: _white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: _white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryBlue,
          side: BorderSide(color: _primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _errorRed, width: 2),
        ),
        filled: true,
        fillColor: _white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(
          color: _mediumGray,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: _mediumGray.withOpacity(0.7),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _white,
        indicatorColor: _primaryBlue.withOpacity(0.1),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        height: 80,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(
              color: _primaryBlue, 
              fontSize: 12, 
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            );
          }
          return TextStyle(
            color: _mediumGray, 
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: _primaryBlue, size: 24);
          }
          return IconThemeData(color: _mediumGray, size: 24);
        }),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: _darkGray,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          color: _darkGray,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          color: _darkGray,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          color: _darkGray,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          color: _darkGray,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: _mediumGray,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: _mediumGray,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          color: _darkGray,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: _primaryBlue,
        onPrimary: _white,
        secondary: _secondaryBlue,
        onSecondary: _white,
        tertiary: _primaryBlueLight,
        onTertiary: _white,
        surface: const Color(0xFF0F172A),
        onSurface: const Color(0xFFF1F5F9),
        surfaceContainerHighest: const Color(0xFF1E293B),
        onSurfaceVariant: const Color(0xFF94A3B8),
        outline: const Color(0xFF334155),
        background: const Color(0xFF0F172A),
        onBackground: const Color(0xFFF1F5F9),
        error: _errorRed,
        onError: _white,
        primaryContainer: _primaryBlue.withOpacity(0.2),
        onPrimaryContainer: _primaryBlue,
        secondaryContainer: _secondaryBlue.withOpacity(0.2),
        onSecondaryContainer: _secondaryBlue,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: const Color(0xFFF1F5F9),
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.2),
        titleTextStyle: TextStyle(
          color: const Color(0xFFF1F5F9),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.2),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF334155),
            width: 1,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: _white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryBlue,
          side: BorderSide(color: _primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: const Color(0xFF404040)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: const Color(0xFF404040)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF2D2D2D),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: _primaryBlue.withOpacity(0.2),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        surfaceTintColor: Colors.transparent,
        height: 80,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(
              color: _primaryBlue, 
              fontSize: 12, 
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            );
          }
          return TextStyle(
            color: const Color(0xFF94A3B8), 
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: _primaryBlue, size: 24);
          }
          return IconThemeData(color: const Color(0xFF94A3B8), size: 24);
        }),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: const Color(0xFFF1F5F9),
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          color: const Color(0xFFF1F5F9),
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          color: const Color(0xFFF1F5F9),
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          color: const Color(0xFFF1F5F9),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          color: const Color(0xFFF1F5F9),
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: const Color(0xFF94A3B8),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: const Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          color: const Color(0xFFF1F5F9),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
