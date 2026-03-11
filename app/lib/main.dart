import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/database/camera_dao.dart';
import 'data/database/pack_loader.dart';
import 'providers/database_provider.dart';
import 'providers/pack_provider.dart';
import 'providers/settings_provider.dart';
import 'services/foreground_task.dart';
import 'services/pack_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize foreground task (notification channel + options)
  await ForegroundTaskService.init();

  final prefs = await SharedPreferences.getInstance();
  final appDir = await getApplicationDocumentsDirectory();
  final storage = PackStorage(baseDir: appDir.path, prefs: prefs);

  // Load active pack if one is installed
  CameraDao? initialDao;
  final activePackPath = storage.getActivePackPath();
  if (activePackPath != null) {
    try {
      initialDao = PackLoader.openPack(activePackPath);
    } catch (_) {
      // Pack file may be corrupt — user will re-download via setup
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        packStorageProvider.overrideWithValue(storage),
        if (initialDao != null)
          cameraDaoProvider.overrideWith((ref) => initialDao),
      ],
      child: const BuzzOffApp(),
    ),
  );
}
