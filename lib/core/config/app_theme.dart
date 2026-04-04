import 'package:flutter/material.dart';

class AppTheme {
  static const primaryGreen = Color(0xFF00ED64);
  static const darkBg = Color(0xFF1C1D1F);
  static const darkSurface = Color(0xFF2C2D30);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: primaryGreen,
          surface: darkSurface,
          surfaceContainerHighest: const Color(0xFF3A3B3D),
          tertiary: primaryGreen.withOpacity(0.2),
        ),
        scaffoldBackgroundColor: darkBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: darkSurface,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: darkSurface,
        ),
        cardTheme: const CardTheme(
          color: darkSurface,
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF3A3B3D),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryGreen),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            backgroundColor: primaryGreen,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primaryGreen),
        ),
        listTileTheme: const ListTileThemeData(
          selectedColor: primaryGreen,
          selectedTileColor: Color(0xFF3A3B3D),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: primaryGreen,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
}
