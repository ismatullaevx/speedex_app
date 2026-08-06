import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// A beautiful arc-style speedometer drawn with CustomPainter.
///
/// The arc sweeps from bottom-left to bottom-right (210° to 330° total).
/// The needle and fill animate smoothly with each speed update.
class SpeedometerWidget extends StatefulWidget {
  final double currentSpeed; // in km/h
  final double maxDisplaySpeed; // top of the scale (default 200)

  const SpeedometerWidget({
    super.key,
    required this.currentSpeed,
    this.maxDisplaySpeed = 200,
  });

  @override
  State<SpeedometerWidget> createState() => _SpeedometerWidgetState();
}

class _SpeedometerWidgetState extends State<SpeedometerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _prevSpeed = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(SpeedometerWidget old) {
    super.didUpdateWidget(old);
    if (old.currentSpeed != widget.currentSpeed) {
      _prevSpeed = old.currentSpeed;
      _animation = Tween<double>(
        begin: _prevSpeed,
        end: widget.currentSpeed,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 280,
      height: 200,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final animatedSpeed = _controller.isAnimating
              ? (_animation.value)
              : widget.currentSpeed;
          return CustomPaint(
            painter: _SpeedometerPainter(
              speed: animatedSpeed,
              maxSpeed: widget.maxDisplaySpeed,
              isDark: isDark,
            ),
            child: _SpeedometerCenter(
              speed: widget.currentSpeed,
              isDark: isDark,
            ),
          );
        },
      ),
    );
  }
}

// ── Center text overlay ──────────────────────────────────────────────────────

class _SpeedometerCenter extends StatelessWidget {
  final double speed;
  final bool isDark;

  const _SpeedometerCenter({required this.speed, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            speed.toStringAsFixed(1),
            style: AppTextStyles.speedValue.copyWith(
              color: isDark ? AppColors.textPrimary : AppColors.textLight,
              shadows: [
                Shadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'KM/H',
            style: AppTextStyles.speedUnit.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── CustomPainter ────────────────────────────────────────────────────────────

class _SpeedometerPainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final bool isDark;

  _SpeedometerPainter({
    required this.speed,
    required this.maxSpeed,
    required this.isDark,
  });

  // Arc goes from 210° to 330° (total 240° sweep), opening at the bottom.
  static const double _startAngle = 150 * math.pi / 180; // degrees → radians
  static const double _sweepAngle = 240 * math.pi / 180;
  static const double _strokeWidth = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.72);
    final radius = size.width * 0.44;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // ── Track (background arc) ───────────────────────────────────────────
    final trackPaint = Paint()
      ..color =
          isDark ? AppColors.arcTrack : AppColors.arcTrackLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _startAngle, _sweepAngle, false, trackPaint);

    // ── Filled arc (gradient) ────────────────────────────────────────────
    final fraction = (speed / maxSpeed).clamp(0.0, 1.0);
    if (fraction > 0) {
      final gradient = SweepGradient(
        startAngle: _startAngle,
        endAngle: _startAngle + _sweepAngle,
        colors: const [
          AppColors.arcGradientStart,
          AppColors.arcGradientEnd,
        ],
        stops: const [0.0, 1.0],
      );

      final filledPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
          rect, _startAngle, _sweepAngle * fraction, false, filledPaint);
    }

    // ── Tick marks ───────────────────────────────────────────────────────
    _drawTicks(canvas, center, radius, size);

    // ── Needle ───────────────────────────────────────────────────────────
    _drawNeedle(canvas, center, radius, fraction);
  }

  void _drawTicks(
      Canvas canvas, Offset center, double radius, Size size) {
    const totalTicks = 20;
    final tickPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 1.5;

    for (int i = 0; i <= totalTicks; i++) {
      final angle =
          _startAngle + (_sweepAngle / totalTicks) * i;
      final isMajor = i % 4 == 0;
      final innerR = radius - (isMajor ? 22.0 : 14.0);
      final outerR = radius - 2.0;

      final cosA = math.cos(angle);
      final sinA = math.sin(angle);

      canvas.drawLine(
        Offset(center.dx + cosA * innerR, center.dy + sinA * innerR),
        Offset(center.dx + cosA * outerR, center.dy + sinA * outerR),
        tickPaint
          ..strokeWidth = isMajor ? 2 : 1
          ..color = isDark
              ? Colors.white.withValues(alpha: isMajor ? 0.3 : 0.12)
              : Colors.black.withValues(alpha: isMajor ? 0.2 : 0.08),
      );
    }
  }

  void _drawNeedle(
      Canvas canvas, Offset center, double radius, double fraction) {
    final angle = _startAngle + _sweepAngle * fraction;
    final needleLength = radius - 26;

    final tip = Offset(
      center.dx + math.cos(angle) * needleLength,
      center.dy + math.sin(angle) * needleLength,
    );

    // Glow
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.25)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Needle line
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Center dot
    canvas.drawCircle(
      center,
      6,
      Paint()..color = AppColors.primary,
    );
    canvas.drawCircle(
      center,
      3,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_SpeedometerPainter old) =>
      old.speed != speed || old.isDark != isDark;
}
