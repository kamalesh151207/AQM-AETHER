// AQM AETHER — CLINICAL SLATE WHITE Design System
// Palette: Main Background #F4F6F9, Surface/Cards #FFFFFF, Primary Text #0F172A,
// Secondary Text #64748B, Border #E2E8F0, Accent #2563EB (Cobalt Blue),
// Success #16A34A, Warning #D97706, Error #DC2626
// Typography: Google Sans (Global)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  // ── CLINICAL SLATE WHITE Palette Specification ─────────────────────────────
  static const Color backgroundPrimary = Color(0xFFF4F6F9); // Main Canvas / App Background: #F4F6F9
  static const Color cardBackground = Color(0xFFFFFFFF);    // Card Containers / Surfaces: #FFFFFF
  static const Color surface = Color(0xFFFFFFFF);           // Clean Surface White: #FFFFFF
  static const Color elevatedSurface = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color mutedBackground = Color(0xFFF1F5F9);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Primary Accent: Cobalt Blue #2563EB
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color cobaltBlue = Color(0xFF2563EB);
  static const Color deepNavy = Color(0xFF2563EB);
  static const Color primaryNavy = Color(0xFF2563EB);
  static const Color navyPrimary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF2563EB);
  static const Color accentPrimary = Color(0xFF2563EB);
  static const Color accentSecondary = Color(0xFF2563EB);
  static const Color accentAnalytics = Color(0xFF2563EB);
  static const Color accentCyan = Color(0xFF2563EB);

  // Accent Tints & Interactive States
  static const Color primaryLight = Color(0xFFEFF6FF);      // Subtle Cobalt Tint
  static const Color navyLight = Color(0xFFEFF6FF);
  static const Color secondaryLight = Color(0xFFEFF6FF);
  static const Color accentCyanLight = Color(0xFFEFF6FF);
  static const Color infoLight = Color(0xFFEFF6FF);
  static const Color accentPrimaryLight = Color(0xFFEFF6FF);
  static const Color accentSecondaryLight = Color(0xFFEFF6FF);
  static const Color accentAnalyticsLight = Color(0xFFEFF6FF);

  static const Color primaryHover = Color(0xFF1D4ED8);
  static const Color navyHover = Color(0xFF1D4ED8);
  static const Color secondaryHover = Color(0xFF1D4ED8);

  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color navyPressed = Color(0xFF1E40AF);
  static const Color navyBorder = Color(0xFF3B82F6);

  // Typography (Deep Slate & Slate Grey)
  static const Color textPrimary = Color(0xFF0F172A);       // Deep Slate #0F172A
  static const Color textSecondary = Color(0xFF64748B);     // Slate Grey #64748B
  static const Color textMuted = Color(0xFF94A3B8);         // Muted Slate #94A3B8

  // Borders
  static const Color border = Color(0xFFE2E8F0);            // Subtle Slate Border #E2E8F0
  static const Color borderSubtle = Color(0xFFF1F5F9);      // Ultra Subtle Border #F1F5F9
  static const Color borderMedium = Color(0xFFCBD5E1);      // Medium Slate Border #CBD5E1
  static const Color borderFocus = Color(0xFF2563EB);

  // Status & Health Colors
  static const Color success = Color(0xFF16A34A);           // Clinical Green #16A34A
  static const Color normal = Color(0xFF16A34A);
  static const Color connection = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color normalLight = Color(0xFFF0FDF4);
  static const Color connectionLight = Color(0xFFF0FDF4);

  static const Color warning = Color(0xFFD97706);           // Warning Amber #D97706
  static const Color warningLight = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFDC2626);             // Clinical Red #DC2626
  static const Color critical = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color criticalLight = Color(0xFFFEF2F2);

  // Sensor Semantic Accents (Harmonized with Clinical Slate White)
  static const Color accentTemperature = Color(0xFFEA580C); // Warm Orange
  static const Color accentTemperatureLight = Color(0xFFFFF7ED);
  static const Color accentHumidity = Color(0xFF0284C7);    // Sky Blue
  static const Color accentHumidityLight = Color(0xFFF0F9FF);
  static const Color accentGas = Color(0xFF6366F1);         // Indigo
  static const Color accentGasLight = Color(0xFFEEF2FF);
  static const Color accentMotion = Color(0xFF0D9488);      // Teal
  static const Color accentMotionLight = Color(0xFFF0FDFA);

  // Dark Theme Aliases (Mapped to Clinical Slate White to prevent dark theme divergence)
  static const Color darkBackground = Color(0xFFF4F6F9);
  static const Color darkSurface = Color(0xFFFFFFFF);
  static const Color darkElevated = Color(0xFFFFFFFF);
  static const Color darkMuted = Color(0xFFF1F5F9);
  static const Color darkBorder = Color(0xFFE2E8F0);
  static const Color darkTextPrimary = Color(0xFF0F172A);
  static const Color darkTextSecondary = Color(0xFF64748B);
  static const Color darkPrimaryBlue = Color(0xFF2563EB);
  static const Color darkAccentCyan = Color(0xFF2563EB);

  static const Color panelBackground = surface;
  static const Color chartGrid = Color(0xFFE2E8F0);
  static const Color chartTooltipBg = Color(0xFF0F172A);
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
  // Ultra-refined, subtle slate shadows for Clinical Slate White
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x060F172A),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x040F172A),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x080F172A),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> darkCard = card;
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
        secondary: AppColors.primary,
        tertiary: AppColors.primary,
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
          backgroundColor: AppColors.primary,
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
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.borderMedium),
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
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.googleSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Preserve Clinical Slate White theme even if dark theme is requested
  static ThemeData get darkTheme => lightTheme;

  static TextTheme _buildTextTheme({required bool isDark}) {
    const primaryColor = AppColors.textPrimary;
    const secondaryColor = AppColors.textSecondary;
    const mutedColor = AppColors.textMuted;

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
