import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/history_provider.dart';
import 'widgets/session_card.dart';

/// History screen showing past completed sessions.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load sessions when screen first opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Consumer<HistoryProvider>(
            builder: (context, history, _) {
              if (history.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              final sessions = history.sessions;

              if (sessions.isEmpty) {
                return _EmptyState(isDark: isDark);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── Header ─────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${sessions.length} Session${sessions.length != 1 ? 's' : ''}',
                          style: AppTextStyles.cardSubtitle.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _confirmClearAll(context, history),
                        icon: const Icon(Icons.delete_sweep_rounded,
                            size: 18, color: AppColors.danger),
                        label: Text(
                          'Clear All',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ── Session list ───────────────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      itemCount: sessions.length,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return SessionCard(
                          session: session,
                          onDelete: () => history.deleteSession(session.id),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(
      BuildContext context, HistoryProvider history) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Sessions?'),
        content: const Text(
            'This will permanently delete all your ride history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await history.clearAll();
    }
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.primary,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Sessions Yet',
            style: AppTextStyles.cardTitle.copyWith(
              color: isDark ? AppColors.textPrimary : AppColors.textLight,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking to record\nyour first ride.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
