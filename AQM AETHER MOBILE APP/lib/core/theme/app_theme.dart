// AQM AETHER — Industrial IoT Design System & Typography Engine
// Unified Palette: Deep Petrol Navy #173B57, Cobalt #2563EB, Google Sans

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  // ── Primary Palette Specification ──────────────────────────────────────────
  static const Color primary = Color(0xFF173B57);          // Deep Petrol Navy #173B57
  static const Color primaryLight = Color(0xFFEBF1F7);
  static const Color primaryHover = Color(0xFF204B6E);
  static const Color primaryDark = Color(0xFF0F2639);

  static const Color secondary = Color(0xFF2563EB);        // Cobalt Blue #2563EB
  static const Color secondaryLight = Color(0xFFEFF6FF);
  static const Color secondaryHover = Color(0xFF1D4ED8);

  // ── Light Theme Surfaces ──────────────────────────────────────────────────
  static const Color backgroundPrimary = Color(0xFFF4F7FA); // #F4F7FA
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color elevatedSurface = Color(0xFFF8FAFD);

  // ── Light Theme Typography ────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF172033);       // #172033
  static const Color textSecondary = Color(0xFF667085);     // #667085
  static const Color textMuted = Color(0xFF94A3B8);

  // ── Status & Telemetry ────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A36A);           // #16A36A
  static const Color successLight = Color(0xFFF0FDF5);
  static const Color normal = Color(0xFF16A36A);
  static const Color normalLight = Color(0xFFF0FDF5);

  static const Color warning = Color(0xFFE6A23C);           // #E6A23C
  static const Color warningLight = Color(0xFFFFFBEB);

  static const Color critical = Color(0xFFDC4C4C);          // #DC4C4C
  static const Color criticalLight = Color(0xFFFEF2F2);
  static const Color error = Color(0xFFDC4C4C);

  static const Color border = Color(0xFFE5EAF0);            // #E5EAF0
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color borderMedium = Color(0xFFD1D8E2);
  static const Color borderFocus = Color(0xFF2563EB);

  // ── Sensor Semantic Accents ───────────────────────────────────────────────
  static const Color accentTemperature = Color(0xFFEA580C); // Warm Orange
  static const Color accentTemperatureLight = Color(0xFFFFF7ED);

  static const Color accentHumidity = Color(0xFF0284C7);    // Precision Sky Blue
  static const Color accentHumidityLight = Color(0xFFF0F9FF);

  static const Color accentGas = Color(0xFF7C3AED);         // Violet / Purple
  static const Color accentGasLight = Color(0xFFF5F3FF);

  static const Color accentMotion = Color(0xFF0D9488);      // Teal
  static const Color accentMotionLight = Color(0xFFF0FDFA);

  // ── Dark Theme Surfaces & Typography ──────────────────────────────────────
  static const Color darkBackground = Color(0xFF0B131D);
  static const Color darkSurface = Color(0xFF131F2E);
  static const Color darkElevated = Color(0xFF1A2A3D);
  static const Color darkBorder = Color(0xFF22354B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Compatibility Aliases
  static const Color navyPrimary = primary;
  static const Color navyLight = primaryLight;
  static const Color navyHover = primaryHover;
  static const Color navyPressed = primaryDark;
  static const Color navyBorder = primaryHover;
  static const Color accentPrimary = primary;
  static const Color accentPrimaryLight = primaryLight;
  static const Color accentSecondary = secondary;
  static const Color accentSecondaryLight = secondaryLight;
  static const Color accentAnalytics = secondary;
  static const Color accentAnalyticsLight = secondaryLight;
  static const Color connection = success;
  static const Color connectionLight = successLight;
  static const Color surfaceVariant = Color(0xFFEDF2F7);
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
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x06173B57),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x05173B57),
      offset: Offset(0, 4),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x0C173B57),
      offset: Offset(0, 4),
      blurRadius: 16,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> darkCard = [
    BoxShadow(
      color: Color(0x30000000),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
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
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        error: AppColors.critical,
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
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.googleSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.googleSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          textStyle: GoogleFonts.googleSans(
            fontSize: 14,
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
        primary: AppColors.secondary,
        secondary: AppColors.secondaryLight,
        surface: AppColors.darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.critical,
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
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.googleSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme({required bool isDark}) {
    final primaryColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final mutedColor = isDark ? const Color(0xFF64748B) : AppColors.textMuted;

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
        fontSize: 14,
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
