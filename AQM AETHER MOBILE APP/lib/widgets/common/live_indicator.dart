// AQM AETHER — Animated Live Indicator Widget

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LiveIndicator extends StatefulWidget {
  final bool isLive;
  final double size;

  const LiveIndicator({
    super.key,
    required this.isLive,
    this.size = 8.0,
  });

  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isLive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LiveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive && !oldWidget.isLive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isLive && oldWidget.isLive) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.isLive
            ? AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success
                          .withOpacity(_pulseAnimation.value),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success
                              .withOpacity(_pulseAnimation.value * 0.6),
                          blurRadius: widget.size * 1.5,
                          spreadRadius: widget.size * 0.3,
                        ),
                      ],
                    ),
                  );
                },
              )
            : Container(
                width: widget.size,
                height: widget.size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textMuted,
                ),
              ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'LIVE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: widget.isLive ? AppColors.success : AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
