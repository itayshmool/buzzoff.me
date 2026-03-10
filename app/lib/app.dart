import 'package:flutter/material.dart';

import 'ui/theme/app_theme.dart';
import 'ui/screens/map_screen.dart';

class BuzzOffApp extends StatelessWidget {
  const BuzzOffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuzzOff',
      theme: AppTheme.dark,
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
