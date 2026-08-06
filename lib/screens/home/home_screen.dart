import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatter.dart';
import '../../providers/history_provider.dart';
import '../../providers/session_provider.dart';
import 'widgets/action_buttons.dart';
import 'widgets/speedometer_widget.dart';
import 'widgets/stats_card.dart';

/// The main Home screen — shows the live speedometer and session controls.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        // Show error snackbar if permission was denied
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (session.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(session.errorMessage!),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
            session.clearError();
          }
        });

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final stats = session.stats;

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // ── Status badge ──────────────────────────────────────
                  _StatusBadge(isTracking: session.isTracking),
                  const SizedBox(height: 16),

                  // ── Speedometer ───────────────────────────────────────
                  SpeedometerWidget(
                    currentSpeed: stats.currentSpeedKmh,
                  ),
                  const SizedBox(height: 24),

                  // ── Stats grid ────────────────────────────────────────
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    children: [
                      StatCard(
                        icon: Icons.speed_rounded,
                        value: '${Formatter.speed(stats.maxSpeedKmh)} km/h',
                        label: 'MAX SPEED',
                        accentColor: AppColors.danger,
                      ),
                      StatCard(
                        icon: Icons.show_chart_rounded,
                        value: '${Formatter.speed(stats.avgSpeedKmh)} km/h',
                        label: 'AVG SPEED',
                        accentColor: AppColors.secondary,
                      ),
                      StatCard(
                        icon: Icons.route_rounded,
                        value: Formatter.distance(stats.distanceMeters),
                        label: 'DISTANCE',
                        accentColor: AppColors.primary,
                      ),
                      StatCard(
                        icon: Icons.timer_rounded,
                        value: Formatter.duration(stats.elapsedSeconds),
                        label: 'TIME',
                        accentColor: AppColors.warning,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Action button ─────────────────────────────────────
                  ActionButtons(
                    isTracking: session.isTracking,
                    onStart: () => session.startTracking(),
                    onStop: () async {
                      await session.stopTracking();
                      // Refresh history after session is saved
                      if (context.mounted) {
                        context.read<HistoryProvider>().refresh();
                      }
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isTracking;

  const _StatusBadge({required this.isTracking});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: (isTracking ? AppColors.success : AppColors.textSecondary)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isTracking ? AppColors.success : AppColors.textSecondary)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot
          _PulsingDot(isTracking: isTracking),
          const SizedBox(width: 6),
          Text(
            isTracking ? 'TRACKING' : 'READY',
            style: AppTextStyles.statLabel.copyWith(
              color: isTracking ? AppColors.success : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final bool isTracking;

  const _PulsingDot({required this.isTracking});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.7, end: 1.3)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isTracking ? AppColors.success : AppColors.textSecondary;
    return ScaleTransition(
      scale: widget.isTracking ? _scale : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
