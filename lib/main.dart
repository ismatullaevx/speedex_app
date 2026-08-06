import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'providers/history_provider.dart';
import 'providers/session_provider.dart';
import 'providers/settings_provider.dart';
import 'services/location_service.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait on mobile.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Instantiate services (singletons) ────────────────────────────────────
  final locationService = LocationService();
  final storageService = StorageService();
  final settingsService = SettingsService();

  runApp(
    MultiProvider(
      providers: [
        // Settings (theme) — loaded first so the splash resolves quickly.
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(service: settingsService)..load(),
        ),

        // Session tracking — drives the live speedometer.
        ChangeNotifierProvider(
          create: (_) => SessionProvider(
            locationService: locationService,
            storageService: storageService,
          ),
        ),

        // History — lazy-loaded when the History tab is opened.
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(storage: storageService),
        ),
      ],
      child: const SpeedexApp(),
    ),
  );
}
