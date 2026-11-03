// AQM AETHER — AETHER GRAPHITE – PRECISION IoT Design System
// Colors: Primary Navy #142B45, Primary Blue #3478F6, Accent Cyan #16B8C4,
// Background #F3F6FA, Card #FFFFFF, Text #172536 / #718096, Border #E3EAF2,
// Success #19A875, Warning #E5A23B, Error #E05252, Muted #EAF0F7
// Typography: Google Sans (Global)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  // ── AETHER GRAPHITE – PRECISION IoT Color Specification ────────────────────
  static const Color primaryNavy = Color(0xFF142B45);       // PRIMARY NAVY: #142B45
  static const Color primary = Color(0xFF142B45);
  static const Color primaryLight = Color(0xFFEAF0F7);
  static const Color primaryHover = Color(0xFF1B3757);
  static const Color primaryDark = Color(0xFF0C1B2C);

  static const Color primaryBlue = Color(0xFF3478F6);       // PRIMARY BLUE: #3478F6
  static const Color secondary = Color(0xFF3478F6);
  static const Color secondaryLight = Color(0xFFEFF5FF);
  static const Color secondaryHover = Color(0xFF2563EB);

  static const Color accentCyan = Color(0xFF16B8C4);        // ACCENT CYAN: #16B8C4
  static const Color accentCyanLight = Color(0xFFE6F9FB);

  // ── Light Theme Surfaces ──────────────────────────────────────────────────
  static const Color backgroundPrimary = Color(0xFFF3F6FA); // PRIMARY BACKGROUND: #F3F6FA
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);    // CARD BACKGROUND: #FFFFFF
  static const Color elevatedSurface = Color(0xFFFFFFFF);
  static const Color mutedBackground = Color(0xFFEAF0F7);   // MUTED BACKGROUND: #EAF0F7
  static const Color surfaceVariant = Color(0xFFEAF0F7);

  // ── Light Theme Typography ────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF172536);       // PRIMARY TEXT: #172536
  static const Color textSecondary = Color(0xFF718096);     // SECONDARY TEXT: #718096
  static const Color textMuted = Color(0xFF8C9BAE);

  // ── Status & Telemetry ────────────────────────────────────────────────────
  static const Color success = Color(0xFF19A875);           // SUCCESS: #19A875
  static const Color normal = Color(0xFF19A875);
  static const Color successLight = Color(0xFFE8F7F1);
  static const Color normalLight = Color(0xFFE8F7F1);

  static const Color warning = Color(0xFFE5A23B);           // WARNING: #E5A23B
  static const Color warningLight = Color(0xFFFDF6EC);

  static const Color error = Color(0xFFE05252);             // ERROR: #E05252
  static const Color critical = Color(0xFFE05252);
  static const Color criticalLight = Color(0xFFFDEEEE);

  static const Color border = Color(0xFFE3EAF2);            // BORDER: #E3EAF2
  static const Color borderSubtle = Color(0xFFEDF2F7);
  static const Color borderMedium = Color(0xFFCBD5E1);
  static const Color borderFocus = Color(0xFF3478F6);

  // ── Sensor Semantic Accents ───────────────────────────────────────────────
  static const Color accentTemperature = Color(0xFFEA580C); // Warm Orange
  static const Color accentTemperatureLight = Color(0xFFFFF7ED);

  static const Color accentHumidity = Color(0xFF16B8C4);    // Accent Cyan #16B8C4
  static const Color accentHumidityLight = Color(0xFFE6F9FB);

  static const Color accentGas = Color(0xFF7C3AED);         // Precision Violet
  static const Color accentGasLight = Color(0xFFF5F3FF);

  static const Color accentMotion = Color(0xFF0D9488);      // Precision Teal
  static const Color accentMotionLight = Color(0xFFF0FDFA);

  // ── Dark Theme Surfaces & Typography (AETHER GRAPHITE Dark) ────────────────
  static const Color darkBackground = Color(0xFF0B121C);     // Deep Graphite Slate
  static const Color darkSurface = Color(0xFF131F2E);        // Graphite Card Surface
  static const Color darkElevated = Color(0xFF1A283B);
  static const Color darkMuted = Color(0xFF111B28);
  static const Color darkBorder = Color(0xFF203247);         // Refined Graphite Border
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF8A99AD);
  static const Color darkPrimaryBlue = Color(0xFF5B96F8);
  static const Color darkAccentCyan = Color(0xFF22D3EE);

  // Compatibility Aliases
  static const Color navyPrimary = primaryNavy;
  static const Color navyLight = primaryLight;
  static const Color navyHover = primaryHover;
  static const Color navyPressed = primaryDark;
  static const Color navyBorder = primaryHover;
  static const Color accentPrimary = primaryNavy;
  static const Color accentPrimaryLight = primaryLight;
  static const Color accentSecondary = primaryBlue;
  static const Color accentSecondaryLight = secondaryLight;
  static const Color accentAnalytics = primaryBlue;
  static const Color accentAnalyticsLight = secondaryLight;
  static const Color connection = success;
  static const Color connectionLight = successLight;
  static const Color panelBackground = surface;
  static const Color chartGrid = border;
  static const Color chartTooltipBg = textPrimary;
}

abstract class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
}

abstract class AppRadius {
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 20.0;
  static const double full = 999.0;
}

abstract class AppShadows {
  // Subtle refined shadows for clean scientific precision
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x05142B45),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x04142B45),
      offset: Offset(0, 3),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x0A142B45),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> darkCard = [];
}

abstract class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(isDark: false);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.googleSans().fontFamily,
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryNavy,
        secondary: AppColors.primaryBlue,
        tertiary: AppColors.accentCyan,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.googleSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.googleSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryNavy,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.googleSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: GoogleFonts.googleSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(isDark: true);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.googleSans().fontFamily,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimaryBlue,
        secondary: AppColors.accentCyan,
        surface: AppColors.darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.error,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.googleSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
          letterSpacing: -0.2,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.googleSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          side: const BorderSide(color: AppColors.darkBorder),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.googleSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimaryBlue,
          textStyle: GoogleFonts.googleSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme({required bool isDark}) {
    final primaryColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final mutedColor = isDark ? const Color(0xFF6B7C93) : AppColors.textMuted;

    return TextTheme(
      displayLarge: GoogleFonts.googleSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        letterSpacing: -0.8,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.googleSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        letterSpacing: -0.6,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.googleSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        letterSpacing: -0.5,
        height: 1.25,
      ),
      headlineLarge: GoogleFonts.googleSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: -0.4,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.googleSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.googleSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      titleLarge: GoogleFonts.googleSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: -0.1,
        height: 1.35,
      ),
      titleMedium: GoogleFonts.googleSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.35,
      ),
      titleSmall: GoogleFonts.googleSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.googleSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: primaryColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.googleSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primaryColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.googleSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        height: 1.45,
      ),
      labelLarge: GoogleFonts.googleSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: 0.2,
      ),
      labelMedium: GoogleFonts.googleSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.3,
      ),
      labelSmall: GoogleFonts.googleSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: mutedColor,
        letterSpacing: 0.4,
      ),
    );
  }
}
