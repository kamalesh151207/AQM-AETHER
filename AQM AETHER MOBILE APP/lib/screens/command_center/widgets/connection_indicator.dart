// AQM AETHER — Connection Indicator Widget
// Animated BLE connection status indicator

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../models/device_model.dart';
import '../../../core/theme/app_theme.dart';

class ConnectionIndicator extends StatefulWidget {
  final DeviceConnectionStatus status;
  final double size;

  const ConnectionIndicator({
    super.key,
    required this.status,
    this.size = 12.0,
  });

  @override
  State<ConnectionIndicator> createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _updateAnimations();
  }

  @override
  void didUpdateWidget(ConnectionIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    _pulseController.stop();
    _rotateController.stop();

    switch (widget.status) {
      case DeviceConnectionStatus.connected:
        _pulseController.repeat();
        break;
      case DeviceConnectionStatus.scanning:
      case DeviceConnectionStatus.connecting:
      case DeviceConnectionStatus.discoveringServices:
      case DeviceConnectionStatus.subscribingNotifications:
      case DeviceConnectionStatus.reconnecting:
        _rotateController.repeat();
        break;
      case DeviceConnectionStatus.disconnected:
      case DeviceConnectionStatus.idle:
      case DeviceConnectionStatus.error:
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Color get _dotColor {
    switch (widget.status) {
      case DeviceConnectionStatus.connected:
        return AppColors.success;
      case DeviceConnectionStatus.reconnecting:
        return AppColors.warning;
      case DeviceConnectionStatus.scanning:
      case DeviceConnectionStatus.connecting:
      case DeviceConnectionStatus.discoveringServices:
      case DeviceConnectionStatus.subscribingNotifications:
        return AppColors.accentSecondary;
      case DeviceConnectionStatus.error:
        return AppColors.critical;
      case DeviceConnectionStatus.disconnected:
      case DeviceConnectionStatus.idle:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _dotColor;
    final totalSize = widget.size * 2.5;

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing ring for connected state
          if (widget.status == DeviceConnectionStatus.connected)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: (1.0 - _pulseAnimation.value).clamp(0.0, 1.0),
                  child: Container(
                    width: widget.size + (_pulseAnimation.value * widget.size * 1.8),
                    height: widget.size + (_pulseAnimation.value * widget.size * 1.8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color,
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Rotating arc for active/connecting states
          if (widget.status != DeviceConnectionStatus.connected &&
              widget.status != DeviceConnectionStatus.disconnected &&
              widget.status != DeviceConnectionStatus.error)
            AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateController.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size(widget.size * 2.0, widget.size * 2.0),
                    painter: _ArcPainter(color: color),
                  ),
                );
              },
            ),

          // Core dot
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: widget.status == DeviceConnectionStatus.connected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: widget.size * 0.8,
                        spreadRadius: widget.size * 0.1,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;

  _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, 0, math.pi * 1.2, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => oldDelegate.color != color;
}
