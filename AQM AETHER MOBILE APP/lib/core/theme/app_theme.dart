// AQM AETHER — AETHER BLUE: Intelligent Environmental Monitoring Design System
// Palette: Main Background #F5F8FC, Primary Blue #1769AA, Deep Navy #123456,
// Accent Cyan #19B5C5, Card Background #FFFFFF, Primary Text #172B45,
// Secondary Text #718096, Border #E5ECF4, Success #16A477, Warning #E5A23B, Error #DC5252
// Typography: Google Sans (Global)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  // ── AETHER BLUE Color Specification ───────────────────────────────────────
  static const Color backgroundPrimary = Color(0xFFF5F8FC); // MAIN BACKGROUND: #F5F8FC
  static const Color primaryBlue = Color(0xFF1769AA);       // PRIMARY BLUE: #1769AA
  static const Color deepNavy = Color(0xFF123456);          // DEEP NAVY: #123456
  static const Color accentCyan = Color(0xFF19B5C5);        // ACCENT CYAN: #19B5C5
  static const Color cardBackground = Color(0xFFFFFFFF);    // CARD BACKGROUND: #FFFFFF
  static const Color textPrimary = Color(0xFF172B45);       // PRIMARY TEXT: #172B45
  static const Color textSecondary = Color(0xFF718096);     // SECONDARY TEXT: #718096
  static const Color border = Color(0xFFE5ECF4);            // BORDER: #E5ECF4
  static const Color success = Color(0xFF16A477);           // SUCCESS: #16A477
  static const Color warning = Color(0xFFE5A23B);           // WARNING: #E5A23B
  static const Color error = Color(0xFFDC5252);             // ERROR: #DC5252

  // Semantic Light Surfaces & Highlights
  static const Color surface = Color(0xFFFFFFFF);
  static const Color elevatedSurface = Color(0xFFFFFFFF);
  static const Color mutedBackground = Color(0xFFEDF3F9);
  static const Color surfaceVariant = Color(0xFFEDF3F9);
  static const Color backgroundSecondary = Color(0xFFFFFFFF);

  static const Color primaryLight = Color(0xFFE9F2FA);
  static const Color primaryHover = Color(0xFF1F4870);
  static const Color primaryDark = Color(0xFF0C2239);

  static const Color secondary = primaryBlue;
  static const Color secondaryLight = Color(0xFFEBF4FC);
  static const Color secondaryHover = Color(0xFF13578D);

  static const Color accentCyanLight = Color(0xFFE6F8FA);
  static const Color textMuted = Color(0xFF8E9EB2);

  static const Color normal = success;
  static const Color normalLight = Color(0xFFE7F7F1);
  static const Color successLight = Color(0xFFE7F7F1);

  static const Color warningLight = Color(0xFFFDF6EB);
  static const Color critical = error;
  static const Color criticalLight = Color(0xFFFDEEEE);

  static const Color borderSubtle = Color(0xFFEEF4FA);
  static const Color borderMedium = Color(0xFFD6E2EE);
  static const Color borderFocus = primaryBlue;

  // ── Sensor Semantic Accents ───────────────────────────────────────────────
  static const Color accentTemperature = Color(0xFFE65100); // Warm Precision Amber/Orange
  static const Color accentTemperatureLight = Color(0xFFFFF3E0);

  static const Color accentHumidity = accentCyan;           // ACCENT CYAN #19B5C5
  static const Color accentHumidityLight = Color(0xFFE6F8FA);

  static const Color accentGas = Color(0xFF5C6BC0);          // Indigo Gas Accent
  static const Color accentGasLight = Color(0xFFEDE7F6);

  static const Color accentMotion = Color(0xFF00897B);       // Teal Motion Accent
  static const Color accentMotionLight = Color(0xFFE0F2F1);

  // ── Dark Theme Surfaces & Typography (AETHER BLUE Dark) ───────────────────
  static const Color darkBackground = Color(0xFF0B141E);     // Deep Navy-Charcoal
  static const Color darkSurface = Color(0xFF122131);        // Deep Slate Surface
  static const Color darkElevated = Color(0xFF182C40);
  static const Color darkMuted = Color(0xFF0E1A27);
  static const Color darkBorder = Color(0xFF1F354D);         // Subtle Slate Border
  static const Color darkTextPrimary = Color(0xFFF1F6FB);
  static const Color darkTextSecondary = Color(0xFF8FA1B6);
  static const Color darkPrimaryBlue = Color(0xFF4A9BE4);
  static const Color darkAccentCyan = Color(0xFF25D0E2);

  // Compatibility Aliases
  static const Color primaryNavy = deepNavy;
  static const Color primary = deepNavy;
  static const Color navyPrimary = deepNavy;
  static const Color navyLight = primaryLight;
  static const Color navyHover = primaryHover;
  static const Color navyPressed = primaryDark;
  static const Color navyBorder = primaryHover;
  static const Color accentPrimary = deepNavy;
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
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;
}

abstract class AppShadows {
  // Soft, clean shadows for modern environmental IoT cards
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x06123456),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x04123456),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x0C123456),
      offset: Offset(0, 6),
      blurRadius: 16,
      spreadRadius: -2,
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
        primary: AppColors.deepNavy,
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
          backgroundColor: AppColors.deepNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
          foregroundColor: AppColors.deepNavy,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
    final mutedColor = isDark ? const Color(0xFF718296) : AppColors.textMuted;

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
