import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Semantic color tokens — use via Theme.of(context).extension<AppSemanticColors>()
// or the convenience getter `context.colors`.
// ---------------------------------------------------------------------------

class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  // Backgrounds
  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color backgroundElevated;
  final Color surface;
  final Color surfaceHover;

  // Borders
  final Color border;
  final Color borderActive;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnAccent;

  // Accents
  final Color accentPrimary;
  final Color accentSecondary;

  // Status
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  // Priority
  final Color priorityLow;
  final Color priorityMedium;
  final Color priorityHigh;
  final Color priorityCritical;

  // Activity brand colours
  final Color pool;
  final Color horses;
  final Color paintball;
  final Color shooting;
  final Color gym;
  final Color padel;

  const AppSemanticColors({
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.backgroundElevated,
    required this.surface,
    required this.surfaceHover,
    required this.border,
    required this.borderActive,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnAccent,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.priorityLow,
    required this.priorityMedium,
    required this.priorityHigh,
    required this.priorityCritical,
    required this.pool,
    required this.horses,
    required this.paintball,
    required this.shooting,
    required this.gym,
    required this.padel,
  });

  // ---- Light palette ----
  static const light = AppSemanticColors(
    backgroundPrimary: Color(0xFFF6F8FB),
    backgroundSecondary: Color(0xFFFFFFFF),
    backgroundElevated: Color(0xFFF1F5F9),
    surface: Color(0xFFEFF4FA),
    surfaceHover: Color(0xFFE2E8F0),
    border: Color(0xFFE2E8F0),
    borderActive: Color(0xFF2563EB),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF526173),
    textMuted: Color(0xFF8A98AA),
    textOnAccent: Color(0xFFFFFFFF),
    accentPrimary: Color(0xFF2563EB),
    accentSecondary: Color(0xFF0F766E),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    danger: Color(0xFFDC2626),
    info: Color(0xFF2563EB),
    priorityLow: Color(0xFF64748B),
    priorityMedium: Color(0xFFD97706),
    priorityHigh: Color(0xFFEA580C),
    priorityCritical: Color(0xFFDC2626),
    pool: Color(0xFF0891B2),
    horses: Color(0xFFB45309),
    paintball: Color(0xFF16A34A),
    shooting: Color(0xFFDC2626),
    gym: Color(0xFF7C3AED),
    padel: Color(0xFF059669),
  );

  // ---- Dark palette ----
  static const dark = AppSemanticColors(
    backgroundPrimary: Color(0xFF0B1220),
    backgroundSecondary: Color(0xFF111827),
    backgroundElevated: Color(0xFF1A2332),
    surface: Color(0xFF1E293B),
    surfaceHover: Color(0xFF334155),
    border: Color(0xFF1F2937),
    borderActive: Color(0xFF60A5FA),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF64748B),
    textOnAccent: Color(0xFFFFFFFF),
    accentPrimary: Color(0xFF60A5FA),
    accentSecondary: Color(0xFF2DD4BF),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF60A5FA),
    priorityLow: Color(0xFF94A3B8),
    priorityMedium: Color(0xFFFBBF24),
    priorityHigh: Color(0xFFFB923C),
    priorityCritical: Color(0xFFF87171),
    pool: Color(0xFF22D3EE),
    horses: Color(0xFFFBBF24),
    paintball: Color(0xFF4ADE80),
    shooting: Color(0xFFF87171),
    gym: Color(0xFFA78BFA),
    padel: Color(0xFF34D399),
  );

  @override
  AppSemanticColors copyWith({
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? backgroundElevated,
    Color? surface,
    Color? surfaceHover,
    Color? border,
    Color? borderActive,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textOnAccent,
    Color? accentPrimary,
    Color? accentSecondary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? priorityLow,
    Color? priorityMedium,
    Color? priorityHigh,
    Color? priorityCritical,
    Color? pool,
    Color? horses,
    Color? paintball,
    Color? shooting,
    Color? gym,
    Color? padel,
  }) {
    return AppSemanticColors(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      backgroundElevated: backgroundElevated ?? this.backgroundElevated,
      surface: surface ?? this.surface,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      border: border ?? this.border,
      borderActive: borderActive ?? this.borderActive,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      priorityLow: priorityLow ?? this.priorityLow,
      priorityMedium: priorityMedium ?? this.priorityMedium,
      priorityHigh: priorityHigh ?? this.priorityHigh,
      priorityCritical: priorityCritical ?? this.priorityCritical,
      pool: pool ?? this.pool,
      horses: horses ?? this.horses,
      paintball: paintball ?? this.paintball,
      shooting: shooting ?? this.shooting,
      gym: gym ?? this.gym,
      padel: padel ?? this.padel,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      backgroundPrimary: Color.lerp(backgroundPrimary, other.backgroundPrimary, t)!,
      backgroundSecondary: Color.lerp(backgroundSecondary, other.backgroundSecondary, t)!,
      backgroundElevated: Color.lerp(backgroundElevated, other.backgroundElevated, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderActive: Color.lerp(borderActive, other.borderActive, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      priorityLow: Color.lerp(priorityLow, other.priorityLow, t)!,
      priorityMedium: Color.lerp(priorityMedium, other.priorityMedium, t)!,
      priorityHigh: Color.lerp(priorityHigh, other.priorityHigh, t)!,
      priorityCritical: Color.lerp(priorityCritical, other.priorityCritical, t)!,
      pool: Color.lerp(pool, other.pool, t)!,
      horses: Color.lerp(horses, other.horses, t)!,
      paintball: Color.lerp(paintball, other.paintball, t)!,
      shooting: Color.lerp(shooting, other.shooting, t)!,
      gym: Color.lerp(gym, other.gym, t)!,
      padel: Color.lerp(padel, other.padel, t)!,
    );
  }
}

/// Convenience getter so widgets can write `context.colors.xxx`.
extension SemanticColorsX on BuildContext {
  AppSemanticColors get colors =>
      Theme.of(this).extension<AppSemanticColors>()!;
}

// ---------------------------------------------------------------------------
// Theme builder
// ---------------------------------------------------------------------------

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
    const c = AppSemanticColors.light;

    final scheme = ColorScheme.fromSeed(
      seedColor: c.accentPrimary,
      brightness: Brightness.light,
      primary: c.accentPrimary,
      secondary: c.accentSecondary,
      surface: c.backgroundSecondary,
      error: c.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      extensions: const [c],
      scaffoldBackgroundColor: c.backgroundPrimary,
      cardColor: c.backgroundSecondary,
      dividerColor: c.border,
      colorScheme: scheme,
      textTheme: _textTheme(c.textPrimary, c.textSecondary),
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        color: c.backgroundSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border, width: 1),
        ),
        margin: EdgeInsets.zero,
        elevation: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.backgroundPrimary,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: c.textPrimary,
        ),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: c.backgroundSecondary,
        indicatorColor: c.accentPrimary.withValues(alpha: 0.12),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? c.accentPrimary
                : c.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? c.accentPrimary
                : c.textSecondary,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.backgroundSecondary,
        selectedItemColor: c.accentPrimary,
        unselectedItemColor: c.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.backgroundSecondary,
        hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
        labelStyle: TextStyle(color: c.textSecondary),
        prefixIconColor: c.textSecondary,
        suffixIconColor: c.textSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.borderActive, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.danger, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accentPrimary,
          foregroundColor: c.textOnAccent,
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
          foregroundColor: c.accentPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.backgroundSecondary,
        selectedColor: c.accentPrimary.withValues(alpha: 0.12),
        side: BorderSide(color: c.border),
        labelStyle: TextStyle(
            color: c.textSecondary, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  static ThemeData get darkTheme {
    const c = AppSemanticColors.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      extensions: const [c],
      scaffoldBackgroundColor: c.backgroundPrimary,
      cardColor: c.backgroundSecondary,
      dividerColor: c.border,
      colorScheme: ColorScheme.dark(
        primary: c.accentPrimary,
        secondary: c.accentSecondary,
        surface: c.backgroundSecondary,
        error: c.danger,
        onPrimary: c.textOnAccent,
        onSecondary: c.textOnAccent,
        onSurface: c.textPrimary,
      ),
      textTheme: _textTheme(c.textPrimary, c.textSecondary),
      cardTheme: CardThemeData(
        color: c.backgroundSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border, width: 1),
        ),
        margin: EdgeInsets.zero,
        elevation: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.backgroundPrimary,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: c.textPrimary),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: c.backgroundSecondary,
        indicatorColor: c.accentPrimary.withValues(alpha: 0.16),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.backgroundSecondary,
        selectedItemColor: c.accentPrimary,
        unselectedItemColor: c.textSecondary,
        selectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.backgroundSecondary,
        hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.accentPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.danger, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accentPrimary,
          foregroundColor: c.textOnAccent,
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
