import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/settings_provider.dart';
import 'app_shell.dart';

/// Root [MaterialApp] — sets up Material 3 themes driven by [SettingsProvider]
/// and delegates the shell to [AppShell].
class SpeedexApp extends StatelessWidget {
  const SpeedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Speedex',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,

          // ── Dark theme ──────────────────────────────────────────────
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.dark,
            ).copyWith(
              surface: AppColors.darkSurface,
              onSurface: AppColors.textPrimary,
              primary: AppColors.primary,
            ),
            scaffoldBackgroundColor: AppColors.darkBackground,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppColors.textPrimary,
              ),
              iconTheme: IconThemeData(color: AppColors.textPrimary),
            ),
            dividerColor: AppColors.darkBorder,
            cardColor: AppColors.darkCard,
          ),

          // ── Light theme ─────────────────────────────────────────────
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ).copyWith(
              primary: AppColors.primary,
            ),
            scaffoldBackgroundColor: AppColors.lightBackground,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppColors.textLight,
              ),
              iconTheme: IconThemeData(color: AppColors.textLight),
            ),
            dividerColor: AppColors.lightBorder,
            cardColor: AppColors.lightCard,
          ),

          // Show a splash until settings are loaded, then show the shell.
          home: settings.isLoaded
              ? const _RootShell()
              : const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                ),
        );
      },
    );
  }
}

/// Manages the selected tab index and keeps the AppBar title in sync.
class _RootShell extends StatefulWidget {
  const _RootShell();

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _index = 0;

  static const List<String> _titles = ['Speedex', 'History', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedIndex: _index,
      title: _titles[_index],
      onIndexChanged: (i) => setState(() => _index = i),
    );
  }
}
