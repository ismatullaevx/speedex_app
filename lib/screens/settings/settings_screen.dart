import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/settings_provider.dart';

/// Settings screen — theme selection and app info.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── Appearance section ────────────────────────────────
                  _SectionHeader(label: 'APPEARANCE', isDark: isDark),
                  const SizedBox(height: 10),

                  _SettingsCard(
                    isDark: isDark,
                    child: Column(
                      children: ThemeMode.values.map((mode) {
                        final isSelected = settings.themeMode == mode;
                        return _ThemeTile(
                          mode: mode,
                          isSelected: isSelected,
                          isDark: isDark,
                          onTap: () => settings.setThemeMode(mode),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── About section ─────────────────────────────────────
                  _SectionHeader(label: 'ABOUT', isDark: isDark),
                  const SizedBox(height: 10),

                  _SettingsCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.speed_rounded,
                          label: 'App Name',
                          value: 'Speedex',
                          isDark: isDark,
                        ),
                        const Divider(height: 1, indent: 54),
                        _InfoTile(
                          icon: Icons.tag_rounded,
                          label: 'Version',
                          value: '1.0.0',
                          isDark: isDark,
                        ),
                        const Divider(height: 1, indent: 54),
                        _InfoTile(
                          icon: Icons.gps_fixed_rounded,
                          label: 'Technology',
                          value: 'GPS · Flutter · Material 3',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: AppTextStyles.sectionHeading.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _SettingsCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: child,
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final ThemeMode mode;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.mode,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  IconData get _icon {
    return switch (mode) {
      ThemeMode.system => Icons.brightness_auto_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
    };
  }

  String get _label {
    return switch (mode) {
      ThemeMode.system => 'System Default',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (isSelected ? AppColors.primary : AppColors.textSecondary)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          size: 20,
        ),
      ),
      title: Text(
        _label,
        style: AppTextStyles.body.copyWith(
          color: isDark ? AppColors.textPrimary : AppColors.textLight,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            width: 2,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 13)
            : null,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(
        label,
        style: AppTextStyles.statLabel.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      subtitle: Text(
        value,
        style: AppTextStyles.body.copyWith(
          color: isDark ? AppColors.textPrimary : AppColors.textLight,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
