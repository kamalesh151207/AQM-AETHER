// AQM AETHER — Live Value Display Widget
// Animated live sensor value with pulsing LIVE badge

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LiveValueDisplay extends StatefulWidget {
  final double? value;
  final String unit;
  final Color color;
  final bool isLive;

  const LiveValueDisplay({
    super.key,
    required this.value,
    required this.unit,
    required this.color,
    required this.isLive,
  });

  @override
  State<LiveValueDisplay> createState() => _LiveValueDisplayState();
}

class _LiveValueDisplayState extends State<LiveValueDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  double? _previousValue;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(LiveValueDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
    }
    if (widget.isLive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isLive && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Animated value
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: _previousValue ?? widget.value ?? 0.0,
                end: widget.value ?? 0.0,
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, child) {
                final displayText = widget.value == null
                    ? '—'
                    : animatedValue.toStringAsFixed(1);
                return Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: widget.value == null
                        ? AppColors.textMuted
                        : widget.color,
                    height: 1.0,
                    letterSpacing: -1.5,
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
            if (widget.value != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  widget.unit,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: widget.color.withOpacity(0.7),
                  ),
                ),
              ),
            const Spacer(),
            // LIVE badge
            _LiveBadge(
              isLive: widget.isLive,
              pulseAnimation: _pulseAnimation,
            ),
          ],
        ),
      ],
    );
  }
}

class _LiveBadge extends StatelessWidget {
  final bool isLive;
  final Animation<double> pulseAnimation;

  const _LiveBadge({
    required this.isLive,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLive
            ? AppColors.success.withOpacity(0.12)
            : AppColors.textMuted.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isLive
              ? AppColors.success.withOpacity(0.3)
              : AppColors.textMuted.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLive
                      ? AppColors.success.withOpacity(pulseAnimation.value)
                      : AppColors.textMuted.withOpacity(0.4),
                  boxShadow: isLive
                      ? [
                          BoxShadow(
                            color: AppColors.success
                                .withOpacity(0.5 * pulseAnimation.value),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
          const SizedBox(width: 5),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isLive ? AppColors.success : AppColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
