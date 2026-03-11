import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:buzzoff/ui/screens/settings_screen.dart';
import 'package:buzzoff/providers/settings_provider.dart';
import 'package:buzzoff/providers/pack_provider.dart';
import 'package:buzzoff/services/pack_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('widget_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  List<Override> buildOverrides(SharedPreferences prefs) {
    final storage = PackStorage(baseDir: tempDir.path, prefs: prefs);
    return [
      sharedPreferencesProvider.overrideWithValue(prefs),
      packStorageProvider.overrideWithValue(storage),
    ];
  }

  testWidgets('Settings screen renders with default values', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: buildOverrides(prefs),
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Alert Distance'), findsOneWidget);
    expect(find.text('Alert Type'), findsOneWidget);
    expect(find.text('Activate at speed'), findsOneWidget);
    expect(find.text('Vibration'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);

    // Scroll to reveal sleep and camera sections
    await tester.scrollUntilVisible(
      find.text('Sleep when stopped'),
      200,
    );
    expect(find.text('Sleep when stopped'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Camera types'),
      200,
    );
    expect(find.text('Camera types'), findsOneWidget);
    expect(find.text('Speed cameras'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Average speed zones'),
      200,
    );
    expect(find.text('Red light cameras'), findsOneWidget);
    expect(find.text('Average speed zones'), findsOneWidget);

    // Scroll down to find camera count
    await tester.scrollUntilVisible(
      find.text('Cameras loaded: 0'),
      200,
    );
    expect(find.text('Cameras loaded: 0'), findsOneWidget);
  });

  testWidgets('Settings screen allows toggling sound', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: buildOverrides(prefs),
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    // Find the Sound switch and tap it
    final soundSwitch = find.widgetWithText(SwitchListTile, 'Sound');
    expect(soundSwitch, findsOneWidget);
    await tester.tap(soundSwitch);
    await tester.pump();

    // Verify the preference was saved
    expect(prefs.getBool('sound_enabled'), isTrue);
  });

  testWidgets('Settings screen allows changing alert distance', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: buildOverrides(prefs),
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    // Tap "500m" choice chip
    final chip500 = find.text('500m');
    expect(chip500, findsOneWidget);
    await tester.tap(chip500);
    await tester.pump();

    expect(prefs.getDouble('alert_distance'), 500.0);
  });
}
