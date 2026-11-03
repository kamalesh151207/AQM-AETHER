// AQM AETHER — Environmental Intelligence & Sensor Monitoring Platform
// Unified Design System: Deep Navy & Blue Modern IoT Interface

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  // ── Palette Specification ─────────────────────────────────────────────────
  // Primary: Deep Navy #142B4A
  static const Color primary = Color(0xFF142B4A);
  static const Color navyPrimary = Color(0xFF142B4A);
  static const Color navyHover = Color(0xFF1E3A63);
  static const Color navyPressed = Color(0xFF0F2038);
  static const Color navyLight = Color(0xFFEDF2F9);
  static const Color navyBorder = Color(0xFF1E3A63);

  // Secondary: Blue #2563EB
  static const Color secondary = Color(0xFF2563EB);
  static const Color secondaryHover = Color(0xFF1D4ED8);
  static const Color secondaryLight = Color(0xFFEFF6FF);

  // Background & Surface: #F5F7FA & #FFFFFF
  static const Color backgroundPrimary = Color(0xFFF5F7FA);
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F4F9);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color panelBackground = Color(0xFFFFFFFF);
  static const Color elevatedSurface = Color(0xFFF8FAFC);

  // Typography: Primary #172033 & Secondary #667085
  static const Color textPrimary = Color(0xFF172033);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status & Telemetry
  // Success: #16A34A
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color normal = Color(0xFF16A34A);
  static const Color normalLight = Color(0xFFF0FDF4);
  static const Color connection = Color(0xFF16A34A);
  static const Color connectionLight = Color(0xFFF0FDF4);

  // Warning: #D97706
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);

  // Error / Critical: #DC2626
  static const Color critical = Color(0xFFDC2626);
  static const Color criticalLight = Color(0xFFFEF2F2);
  static const Color error = Color(0xFFDC2626);

  // Border: #E5E7EB
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color borderMedium = Color(0xFFD1D5DB);
  static const Color borderFocus = Color(0xFF2563EB);

  // Sensor Accents (Consistent Semantic Highlights)
  static const Color accentTemperature = Color(0xFFEA580C);      // Amber / Orange
  static const Color accentTemperatureLight = Color(0xFFFFF7ED);
  static const Color accentHumidity = Color(0xFF0284C7);         // Blue / Cyan
  static const Color accentHumidityLight = Color(0xFFF0F9FF);
  static const Color accentGas = Color(0xFF7C3AED);              // Purple / Violet
  static const Color accentGasLight = Color(0xFFF5F3FF);
  static const Color accentAnalytics = Color(0xFF2563EB);
  static const Color accentAnalyticsLight = Color(0xFFEFF6FF);

  // Backward Compatibility Aliases
  static const Color accentPrimary = Color(0xFF142B4A);
  static const Color accentPrimaryLight = Color(0xFFEDF2F9);
  static const Color accentSecondary = Color(0xFF2563EB);
  static const Color accentSecondaryLight = Color(0xFFEFF6FF);

  // Visualizations
  static const Color chartGrid = Color(0xFFE2E8F0);
  static const Color chartTooltipBg = Color(0xFF172033);
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
      color: Color(0x06000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x04000000),
      offset: Offset(0, 4),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 4),
      blurRadius: 16,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> activePill = [
    BoxShadow(
      color: Color(0x12142B4A),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];
}

abstract class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = _buildTextTheme();
    final googleSansTheme = GoogleFonts.googleSansTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.googleSans().fontFamily,
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.cardBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        error: AppColors.critical,
      ),
      textTheme: googleSansTheme,
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

  // Backward compatibility alias
  static ThemeData get darkTheme => lightTheme;

  /// Typography hierarchy defined strictly in accordance with specification:
  /// - Display headings: Google Sans, bold (w700), 28–32px
  /// - Page headings: Google Sans, semibold (w600), 22–26px
  /// - Section headings: Google Sans, semibold (w600), 16–20px
  /// - Body: Google Sans, regular (w400), 14–16px
  /// - Supporting text: Google Sans, regular (w400), 12–13px
  /// - Buttons: Google Sans, medium/semibold (w500/w600), 14–16px
  /// - Small labels: Google Sans, medium (w500), 11–12px
  static TextTheme _buildTextTheme() {
    return TextTheme(
      // Display Headings: bold, 28–32px
      displayLarge: GoogleFonts.googleSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.8,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.googleSans(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.6,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.googleSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.25,
      ),

      // Page Headings: semibold, 22–26px
      headlineLarge: GoogleFonts.googleSans(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.googleSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.googleSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
        height: 1.3,
      ),

      // Section Headings: semibold, 16–20px
      titleLarge: GoogleFonts.googleSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
        height: 1.35,
      ),
      titleMedium: GoogleFonts.googleSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.1,
        height: 1.35,
      ),
      titleSmall: GoogleFonts.googleSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.4,
      ),

      // Body: regular, 14–16px
      bodyLarge: GoogleFonts.googleSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.googleSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      ),

      // Supporting Text: regular, 12–13px
      bodySmall: GoogleFonts.googleSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.45,
      ),

      // Buttons: medium/semibold, 14–16px
      labelLarge: GoogleFonts.googleSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ),

      // Small Labels: medium, 11–12px
      labelMedium: GoogleFonts.googleSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
      labelSmall: GoogleFonts.googleSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0.4,
      ),
    );
  }
}
