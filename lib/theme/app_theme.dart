import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Base colors - employee-facing light mode.
  static const Color backgroundPrimary = Color(0xFFF6F8FB);
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color backgroundElevated = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFEFF4FA);
  static const Color surfaceHover = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderActive = Color(0xFF2563EB);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF526173);
  static const Color textMuted = Color(0xFF8A98AA);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // Accent Colors
  static const Color accentPrimary = Color(0xFF2563EB);
  static const Color accentSecondary = Color(0xFF0F766E);

  // Activity Colors
  static const Color pool = Color(0xFF0891B2);
  static const Color horses = Color(0xFFB45309);
  static const Color paintball = Color(0xFF16A34A);
  static const Color shooting = Color(0xFFDC2626);
  static const Color gym = Color(0xFF7C3AED);
  static const Color padel = Color(0xFF059669);

  // Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Priority Colors
  static const Color priorityLow = Color(0xFF64748B);
  static const Color priorityMedium = Color(0xFFD97706);
  static const Color priorityHigh = Color(0xFFEA580C);
  static const Color priorityCritical = Color(0xFFDC2626);

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
  static TextTheme _textTheme(Color primary, Color secondary) {
    return GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w800, color: primary),
        headlineLarge: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w800, color: primary),
        headlineMedium: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700, color: primary),
        titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: primary),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: primary),
        bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.normal, color: primary),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.normal, color: secondary),
        labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accentPrimary,
      brightness: Brightness.light,
      primary: AppColors.accentPrimary,
      secondary: AppColors.accentSecondary,
      surface: AppColors.backgroundSecondary,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      cardColor: AppColors.backgroundSecondary,
      dividerColor: AppColors.border,
      colorScheme: scheme,
      textTheme: _textTheme(AppColors.textPrimary, AppColors.textSecondary),
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        color: AppColors.backgroundSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
        elevation: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundPrimary,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.backgroundSecondary,
        indicatorColor: AppColors.accentPrimary.withValues(alpha: 0.12),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.accentPrimary
                : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.accentPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundSecondary,
        selectedItemColor: AppColors.accentPrimary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSecondary,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.borderActive, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPrimary,
          foregroundColor: AppColors.textOnAccent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundSecondary,
        selectedColor: AppColors.accentPrimary.withValues(alpha: 0.12),
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(
            color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      cardColor: const Color(0xFF111827),
      dividerColor: const Color(0xFF1F2937),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF60A5FA),
        secondary: Color(0xFF2DD4BF),
        surface: Color(0xFF111827),
        error: Color(0xFFF87171),
        onPrimary: AppColors.textOnAccent,
        onSecondary: AppColors.textOnAccent,
        onSurface: Color(0xFFF8FAFC),
      ),
      textTheme: _textTheme(const Color(0xFFF8FAFC), const Color(0xFFCBD5E1)),
      cardTheme: CardThemeData(
        color: const Color(0xFF111827),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1F2937), width: 1),
        ),
        margin: EdgeInsets.zero,
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B1220),
        foregroundColor: Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFFF8FAFC)),
        iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: const Color(0xFF111827),
        indicatorColor: const Color(0xFF60A5FA).withValues(alpha: 0.16),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF111827),
        selectedItemColor: Color(0xFF60A5FA),
        unselectedItemColor: Color(0xFF94A3B8),
        selectedLabelStyle:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1F2937), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1F2937), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF60A5FA),
          foregroundColor: AppColors.textOnAccent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          elevation: 0,
        ),
      ),
    );
  }
}
