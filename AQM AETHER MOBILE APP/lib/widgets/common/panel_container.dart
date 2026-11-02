// AQM AETHER — Reusable Panel Container Widget

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PanelContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;

  const PanelContainer({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.panelBackground,
        borderRadius:
            BorderRadius.circular(borderRadius ?? AppRadius.lg),
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
