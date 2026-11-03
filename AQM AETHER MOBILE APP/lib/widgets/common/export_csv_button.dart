import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// Professional, responsive Action Button for CSV Telemetry Export.
///
/// Features:
/// - Download icon perfectly aligned with "Export CSV" text.
/// - Modern rounded rectangular button with navy-blue IoT theme.
/// - Animated hover elevation & color transitions on desktop/laptop.
/// - Responsive padding & typography preventing clipping across phones, tablets & desktops.
/// - Built-in loading state with progress indicator during export operations.
class ExportCsvButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isExporting;
  final String label;
  final String loadingLabel;

  const ExportCsvButton({
    super.key,
    required this.onPressed,
    this.isExporting = false,
    this.label = 'Export CSV',
    this.loadingLabel = 'Exporting…',
  });

  @override
  State<ExportCsvButton> createState() => _ExportCsvButtonState();
}

class _ExportCsvButtonState extends State<ExportCsvButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;
    final isInteractive = widget.onPressed != null && !widget.isExporting;

    // Responsive padding
    final horizontalPadding = isCompact ? 10.0 : 13.0;
    final verticalPadding = isCompact ? 6.0 : 7.5;
    final iconSize = isCompact ? 15.0 : 16.0;
    final fontSize = isCompact ? 11.5 : 12.5;

    // Dynamic navy color state resolution
    Color backgroundColor;
    if (widget.isExporting) {
      backgroundColor = AppColors.navyPrimary.withOpacity(0.75);
    } else if (!isInteractive) {
      backgroundColor = AppColors.navyPrimary.withOpacity(0.5);
    } else if (_isPressed) {
      backgroundColor = AppColors.navyPressed;
    } else if (_isHovered) {
      backgroundColor = AppColors.navyHover;
    } else {
      backgroundColor = AppColors.navyPrimary;
    }

    // Dynamic elevation and shadow
    final List<BoxShadow> shadows = (!isInteractive || widget.isExporting)
        ? const []
        : _isHovered
            ? [
                BoxShadow(
                  color: AppColors.navyPrimary.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.navyPrimary.withOpacity(0.20),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ];

    return MouseRegion(
      cursor: isInteractive
          ? SystemMouseCursors.click
          : (widget.isExporting
              ? SystemMouseCursors.wait
              : SystemMouseCursors.basic),
      onEnter: (_) {
        if (isInteractive && mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      child: Tooltip(
        message: widget.isExporting
            ? 'Preparing CSV report…'
            : 'Export sensor telemetry records as CSV',
        waitDuration: const Duration(milliseconds: 600),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: _isHovered && isInteractive
                  ? AppColors.navyBorder
                  : AppColors.navyBorder.withOpacity(0.4),
              width: 1.0,
            ),
            boxShadow: shadows,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              splashColor: Colors.white.withOpacity(0.18),
              highlightColor: Colors.white.withOpacity(0.08),
              onHighlightChanged: (highlighted) {
                if (mounted && isInteractive) {
                  setState(() => _isPressed = highlighted);
                }
              },
              onTap: isInteractive
                  ? () {
                      HapticFeedback.selectionClick();
                      widget.onPressed?.call();
                    }
                  : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.isExporting) ...[
                      SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.loadingLabel,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: Colors.white,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.file_download_outlined,
                        size: iconSize,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

