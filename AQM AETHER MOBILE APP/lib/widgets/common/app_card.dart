// AQM AETHER — Premium Card Surface Component
// Clean surface, hairline border, subtle shadow, light & dark mode adaptive

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double? borderRadius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppRadius.lg;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = isDark ? AppColors.darkSurface : AppColors.cardBackground;
    final defaultBorder = isDark ? AppColors.darkBorder : AppColors.border;

    Color? effectiveCardColor = color;
    if (color == AppColors.backgroundSecondary || color == AppColors.cardBackground || color == Colors.white) {
      effectiveCardColor = defaultBg;
    }

    final container = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: effectiveCardColor ?? defaultBg,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(
          color: borderColor ?? defaultBorder,
          width: 1,
        ),
        boxShadow: isDark ? const [] : AppShadows.card,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: container,
        ),
      );
    }

    return container;
  }
}
