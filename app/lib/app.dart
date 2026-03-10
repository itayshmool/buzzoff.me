import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/pack_provider.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/map_screen.dart';
import 'ui/screens/setup_screen.dart';

class BuzzOffApp extends ConsumerWidget {
  const BuzzOffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCountry = ref.watch(activeCountryProvider);

    return MaterialApp(
      title: 'BuzzOff',
      theme: AppTheme.dark,
      home: activeCountry != null ? const MapScreen() : const SetupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
