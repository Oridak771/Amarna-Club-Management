import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Amarna Club design system — emerald & gold.
// Semantic color tokens: use via `context.colors.xxx`.
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

  // ---- Light palette : warm sand + emerald + gold ----
  static const light = AppSemanticColors(
    backgroundPrimary: Color(0xFFF7F6F2),
    backgroundSecondary: Color(0xFFFFFFFF),
    backgroundElevated: Color(0xFFF0EEE7),
    surface: Color(0xFFF2F1EB),
    surfaceHover: Color(0xFFE8E6DD),
    border: Color(0xFFE4E1D7),
    borderActive: Color(0xFF0E7C66),
    textPrimary: Color(0xFF1A1F1D),
    textSecondary: Color(0xFF56605B),
    textMuted: Color(0xFF98A19B),
    textOnAccent: Color(0xFFFFFFFF),
    accentPrimary: Color(0xFF0E7C66),
    accentSecondary: Color(0xFFB8892F),
    success: Color(0xFF178A50),
    warning: Color(0xFFC77D14),
    danger: Color(0xFFCB3B2F),
    info: Color(0xFF2A6FA8),
    priorityLow: Color(0xFF7B857F),
    priorityMedium: Color(0xFFC77D14),
    priorityHigh: Color(0xFFDD5E28),
    priorityCritical: Color(0xFFCB3B2F),
    pool: Color(0xFF0E8AA3),
    horses: Color(0xFFA5622A),
    paintball: Color(0xFF4E8A2E),
    shooting: Color(0xFFB03A3A),
    gym: Color(0xFF6D4FB3),
    padel: Color(0xFF0E7C66),
  );

  // ---- Dark palette : deep green charcoal + luminous emerald & gold ----
  static const dark = AppSemanticColors(
    backgroundPrimary: Color(0xFF0E1311),
    backgroundSecondary: Color(0xFF161D1A),
    backgroundElevated: Color(0xFF1D2622),
    surface: Color(0xFF1F2925),
    surfaceHover: Color(0xFF2A3630),
    border: Color(0xFF27312C),
    borderActive: Color(0xFF3DC9A5),
    textPrimary: Color(0xFFF2F5F3),
    textSecondary: Color(0xFFAEBBB4),
    textMuted: Color(0xFF6C7973),
    textOnAccent: Color(0xFF0B1210),
    accentPrimary: Color(0xFF3DC9A5),
    accentSecondary: Color(0xFFE0B45C),
    success: Color(0xFF4CCB84),
    warning: Color(0xFFE8A94A),
    danger: Color(0xFFEF6E60),
    info: Color(0xFF62A9DE),
    priorityLow: Color(0xFF93A09A),
    priorityMedium: Color(0xFFE8A94A),
    priorityHigh: Color(0xFFF08650),
    priorityCritical: Color(0xFFEF6E60),
    pool: Color(0xFF43C3DD),
    horses: Color(0xFFE0A163),
    paintball: Color(0xFF83CE58),
    shooting: Color(0xFFEB7A7A),
    gym: Color(0xFFA98BE8),
    padel: Color(0xFF3DC9A5),
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
      backgroundPrimary:
          Color.lerp(backgroundPrimary, other.backgroundPrimary, t)!,
      backgroundSecondary:
          Color.lerp(backgroundSecondary, other.backgroundSecondary, t)!,
      backgroundElevated:
          Color.lerp(backgroundElevated, other.backgroundElevated, t)!,
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
      priorityCritical:
          Color.lerp(priorityCritical, other.priorityCritical, t)!,
      pool: Color.lerp(pool, other.pool, t)!,
      horses: Color.lerp(horses, other.horses, t)!,
      paintball: Color.lerp(paintball, other.paintball, t)!,
      shooting: Color.lerp(shooting, other.shooting, t)!,
      gym: Color.lerp(gym, other.gym, t)!,
      padel: Color.lerp(padel, other.padel, t)!,
    );
  }

  Color getActivityColor(String activityId) {
    switch (activityId.toLowerCase()) {
      case 'pool':
        return pool;
      case 'horses':
        return horses;
      case 'paintball':
        return paintball;
      case 'shooting':
        return shooting;
      case 'gym':
        return gym;
      case 'padel':
        return padel;
      default:
        return accentPrimary;
    }
  }
}

/// Convenience getter so widgets can write `context.colors.xxx`.
extension SemanticColorsX on BuildContext {
  AppSemanticColors get colors =>
      Theme.of(this).extension<AppSemanticColors>()!;
}

// ---------------------------------------------------------------------------
// Theme builder — one implementation shared by light and dark.
// ---------------------------------------------------------------------------

class AppTheme {
  static const double radiusCard = 20;
  static const double radiusField = 14;

  // Built once and cached — constructing ThemeData (and its GoogleFonts
  // text theme) on every access is wasted work on each rebuild.
  static final ThemeData lightTheme =
      _build(AppSemanticColors.light, Brightness.light);

  static final ThemeData darkTheme =
      _build(AppSemanticColors.dark, Brightness.dark);

  static TextTheme _textTheme(AppSemanticColors c) {
    return GoogleFonts.manropeTextTheme(
      TextTheme(
        displayLarge: TextStyle(
            fontSize: 34, fontWeight: FontWeight.w800, color: c.textPrimary),
        headlineLarge: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w800, color: c.textPrimary),
        headlineMedium: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary),
        titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: c.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: c.textSecondary),
        labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  static ThemeData _build(AppSemanticColors c, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: c.accentPrimary,
      brightness: brightness,
      primary: c.accentPrimary,
      onPrimary: c.textOnAccent,
      secondary: c.accentSecondary,
      surface: c.backgroundSecondary,
      onSurface: c.textPrimary,
      error: c.danger,
    );

    OutlineInputBorder fieldBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusField),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [c],
      colorScheme: scheme,
      scaffoldBackgroundColor: c.backgroundPrimary,
      cardColor: c.backgroundSecondary,
      dividerColor: c.border,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _textTheme(c),
      cardTheme: CardThemeData(
        color: c.backgroundSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: c.border),
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
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: c.textPrimary,
        ),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: c.backgroundSecondary,
        indicatorColor: c.accentPrimary.withValues(alpha: 0.14),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.backgroundSecondary,
        hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
        labelStyle: TextStyle(color: c.textSecondary),
        prefixIconColor: c.textSecondary,
        suffixIconColor: c.textSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: fieldBorder(c.border),
        enabledBorder: fieldBorder(c.border),
        focusedBorder: fieldBorder(c.borderActive, 1.5),
        errorBorder: fieldBorder(c.danger),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accentPrimary,
          foregroundColor: c.textOnAccent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusField),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accentPrimary,
          foregroundColor: c.textOnAccent,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusField),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.border, width: 1.2),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusField),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accentPrimary,
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.backgroundSecondary,
        selectedColor: c.accentPrimary.withValues(alpha: 0.14),
        side: BorderSide(color: c.border),
        labelStyle:
            TextStyle(color: c.textSecondary, fontWeight: FontWeight.w600),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accentPrimary,
        foregroundColor: c.textOnAccent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        extendedTextStyle: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brightness == Brightness.light
            ? const Color(0xFF1A1F1D)
            : c.backgroundElevated,
        contentTextStyle: GoogleFonts.manrope(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusField),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.textOnAccent
              : c.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.accentPrimary
              : c.surfaceHover,
        ),
      ),
    );
  }
}
