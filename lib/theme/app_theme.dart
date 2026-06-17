import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Base Colors
  static const Color backgroundPrimary = Color(0xFF0D1117);
  static const Color backgroundSecondary = Color(0xFF161B22);
  static const Color backgroundElevated = Color(0xFF21262D);
  static const Color surface = Color(0xFF1C2128);
  static const Color surfaceHover = Color(0xFF2D333B);
  static const Color border = Color(0xFF30363D);
  static const Color borderActive = Color(0xFF58A6FF);

  // Text Colors
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF484F58);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // Accent Colors
  static const Color accentPrimary = Color(0xFF58A6FF);
  static const Color accentSecondary = Color(0xFFBC8CFF);

  // Activity Colors
  static const Color pool = Color(0xFF00D4FF);
  static const Color horses = Color(0xFFFFB347);
  static const Color paintball = Color(0xFF7CFC00);
  static const Color shooting = Color(0xFFFF4757);
  static const Color gym = Color(0xFFA855F7);
  static const Color padel = Color(0xFF34D399);

  // Status Colors
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color danger = Color(0xFFF85149);
  static const Color info = Color(0xFF58A6FF);

  // Priority Colors
  static const Color priorityLow = Color(0xFF8B949E);
  static const Color priorityMedium = Color(0xFFD29922);
  static const Color priorityHigh = Color(0xFFF0883E);
  static const Color priorityCritical = Color(0xFFF85149);

  // Helper method to get activity-specific color
  static Color getActivityColor(String activityKey) {
    switch (activityKey.toLowerCase()) {
      case 'pool':
      case 'piscine':
        return pool;
      case 'horses':
      case 'chevaux':
        return horses;
      case 'paintball':
        return paintball;
      case 'shooting':
      case 'tir':
        return shooting;
      case 'gym':
        return gym;
      case 'padel':
        return padel;
      default:
        return accentPrimary;
    }
  }

  // Helper method to get priority-specific color
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'faible':
      case 'low':
        return priorityLow;
      case 'moyen':
      case 'medium':
        return priorityMedium;
      case 'éleve':
      case 'élevé':
      case 'high':
        return priorityHigh;
      case 'critique':
      case 'critical':
        return priorityCritical;
      default:
        return textSecondary;
    }
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      cardColor: AppColors.backgroundSecondary,
      dividerColor: AppColors.border,

      // Color Scheme (No deprecated fields)
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentPrimary,
        secondary: AppColors.accentSecondary,
        surface: AppColors.backgroundSecondary,
        error: AppColors.danger,
        onPrimary: AppColors.textOnAccent,
        onSecondary: AppColors.textOnAccent,
        onSurface: AppColors.textPrimary,
      ),

      // Text Theme
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
          labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textOnAccent),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
        elevation: 0,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundSecondary,
        selectedItemColor: AppColors.accentPrimary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Input Decoration Theme (Forms)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderActive, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPrimary,
          foregroundColor: AppColors.textOnAccent,
          minimumSize: const Size(double.infinity, 52), // Touch target compliance
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          elevation: 0,
        ),
      ),
    );
  }
}
