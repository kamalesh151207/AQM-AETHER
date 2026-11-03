// AQM AETHER — Environmental Intelligence & Sensor Monitoring Platform
// Clean Modern Industrial White Design System

import 'package:flutter/material.dart';

abstract class AppColors {
  // Backgrounds & Surfaces (Predominantly White System)
  static const Color backgroundPrimary = Color(0xFFF6F7F9);   // #F6F7F9 Canvas
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);       // #FFFFFF Primary Card
  static const Color panelBackground = Color(0xFFFFFFFF);
  static const Color elevatedSurface = Color(0xFFF1F3F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F6);

  // Exact Accents from AQM AETHER Specification
  static const Color accentTemperature = Color(0xFFF47B45);   // Coral / Orange (#F47B45)
  static const Color accentTemperatureLight = Color(0xFFFEF2EC);
  static const Color accentHumidity = Color(0xFF16B8A6);      // Teal / Cyan (#16B8A6)
  static const Color accentHumidityLight = Color(0xFFE8F8F6);
  static const Color accentAnalytics = Color(0xFF8065D9);     // Purple (#8065D9)
  static const Color accentAnalyticsLight = Color(0xFFF3F0FB);
  static const Color connection = Color(0xFF20A36B);          // Green (#20A36B)
  static const Color connectionLight = Color(0xFFE9F6F0);

  // Status & Telemetry
  static const Color normal = Color(0xFF20A36B);              // Emerald Green (#20A36B)
  static const Color normalLight = Color(0xFFE9F6F0);
  static const Color success = Color(0xFF20A36B);             // Emerald Green (#20A36B)
  static const Color successLight = Color(0xFFE9F6F0);
  static const Color warning = Color(0xFFF2A93B);             // Amber (#F2A93B)
  static const Color warningLight = Color(0xFFFEF6EB);
  static const Color critical = Color(0xFFE74C3C);            // Red (#E74C3C)
  static const Color criticalLight = Color(0xFFFDEDEC);

  // Brand / Default Accents
  static const Color accentPrimary = Color(0xFF20A36B);       // Emerald Green (#20A36B)
  static const Color accentPrimaryLight = Color(0xFFE9F6F0);
  static const Color accentSecondary = Color(0xFF16B8A6);     // Teal / Cyan (#16B8A6)
  static const Color accentSecondaryLight = Color(0xFFE8F8F6);

  // Navy / Blue Action Theme (Professional IoT Controls)
  static const Color navyPrimary = Color(0xFF1B365D);       // Deep Navy Blue (#1B365D)
  static const Color navyHover = Color(0xFF24487A);         // Lighter Navy Hover (#24487A)
  static const Color navyPressed = Color(0xFF132742);       // Dark Navy Pressed (#132742)
  static const Color navyLight = Color(0xFFEBF1F8);         // Navy Tint Background (#EBF1F8)
  static const Color navyBorder = Color(0xFF2D507F);        // Navy Border Highlight

  // Typography
  static const Color textPrimary = Color(0xFF20242B);         // #20242B Primary Text
  static const Color textSecondary = Color(0xFF7B8491);       // #7B8491 Secondary Text
  static const Color textMuted = Color(0xFF9EA7B4);           // Muted Slate

  // Dividers & Hairlines
  static const Color border = Color(0xFFE8EBEF);              // #E8EBEF Clean hairline border
  static const Color borderSubtle = Color(0xFFF0F2F6);
  static const Color borderMedium = Color(0xFFD6DBE1);
  static const Color borderFocus = Color(0xFFCBD5E1);

  // Visualizations
  static const Color chartGrid = Color(0xFFEDF1F5);
  static const Color chartTooltipBg = Color(0xFF20242B);
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
      color: Color(0x08000000),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x04000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x0C000000),
      offset: Offset(0, 6),
      blurRadius: 16,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> activePill = [
    BoxShadow(
      color: Color(0x1510B981),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];
}

abstract class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentPrimary,
        secondary: AppColors.accentSecondary,
        surface: AppColors.cardBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        error: AppColors.critical,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
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
          backgroundColor: AppColors.accentPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  // Alias for backward compatibility if referenced
  static ThemeData get darkTheme => lightTheme;

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.8,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.4,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
