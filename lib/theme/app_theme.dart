import 'package:flutter/material.dart';

class AppTheme {
  // Màu sắc chính
  static const Color primaryColor = Color(0xFF6D9886); // Xanh rêu
  static const Color secondaryColor = Color(0xFFF2E7D5); // Kem ấm
  static const Color accentColor = Color(0xFFD9C5B4); // Gỗ sáng
  static const Color textColor = Color(0xFF4A4A4A); // Xám dịu

  // Tạo ColorScheme theo Material 3
  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
  ).copyWith(
    primary: primaryColor,
    secondary: accentColor,
    surface: Colors.white,
  );

  // Theme chính
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,

    scaffoldBackgroundColor: const Color(0xFFF6F6F6),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Card – cho món ăn → thân thiện & đẹp
    cardTheme: CardThemeData(
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.1),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Text
    textTheme: TextTheme(
      titleLarge: const TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
      bodyMedium: TextStyle(
        color: textColor.withOpacity(0.9),
        fontSize: 16,
      ),
      labelLarge: TextStyle(
        color: primaryColor.withOpacity(0.9),
        fontWeight: FontWeight.w600,
      ),
    ),

    // Input field
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),

    // ListTile
    listTileTheme: ListTileThemeData(
      iconColor: primaryColor,
      textColor: textColor,
      selectedColor: primaryColor,
      selectedTileColor: secondaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
