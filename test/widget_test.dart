import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:speedex_app/app/app.dart';
import 'package:speedex_app/providers/history_provider.dart';
import 'package:speedex_app/providers/session_provider.dart';
import 'package:speedex_app/providers/settings_provider.dart';
import 'package:speedex_app/services/location_service.dart';
import 'package:speedex_app/services/settings_service.dart';
import 'package:speedex_app/services/storage_service.dart';

void main() {
  testWidgets('Speedex app smoke test — home screen renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = StorageService();
    final settingsService = SettingsService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(service: settingsService)..load(),
          ),
          ChangeNotifierProvider(
            create: (_) => SessionProvider(
              locationService: LocationService(),
              storageService: storageService,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => HistoryProvider(storage: storageService),
          ),
        ],
        child: const SpeedexApp(),
      ),
    );

    // Pump a few frames so the SettingsProvider loading future completes.
    await tester.pumpAndSettle();

    // The app title should be visible.
    expect(find.text('Speedex'), findsWidgets);
  });
}
