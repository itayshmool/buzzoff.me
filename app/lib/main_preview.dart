import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preview/mock_camera_dao.dart';
import 'preview/mock_pack_storage.dart';
import 'preview/preview_map_screen.dart';
import 'preview/preview_settings_screen.dart';
import 'providers/database_provider.dart';
import 'providers/pack_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/simulation_provider.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final storage = MockPackStorage(prefs);
  final mockDao = MockCameraDao();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        packStorageProvider.overrideWithValue(storage),
        cameraDaoProvider.overrideWith((ref) => mockDao),
        simulationEnabledProvider.overrideWith(
          (ref) => SimulationNotifier(prefs)..toggle(),
        ),
      ],
      child: const PreviewApp(),
    ),
  );
}

class PreviewApp extends StatefulWidget {
  const PreviewApp({super.key});

  @override
  State<PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<PreviewApp> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuzzOff Preview',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: IndexedStack(
          index: _tabIndex,
          children: [
            PreviewMapScreen(
              onOpenSettings: () => setState(() => _tabIndex = 1),
            ),
            const PreviewSettingsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (i) => setState(() => _tabIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
