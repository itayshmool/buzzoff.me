import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/model/country.dart';
import '../../providers/database_provider.dart';
import '../../providers/pack_manager_provider.dart';
import '../../providers/pack_provider.dart';
import '../widgets/download_progress.dart';
import 'country_picker_screen.dart';
import 'map_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  bool _downloading = false;
  String _downloadingCountry = '';

  @override
  Widget build(BuildContext context) {
    if (_downloading) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: DownloadProgress(
              countryName: _downloadingCountry,
              progress: 0,
            ),
          ),
        ),
      );
    }

    return CountryPickerScreen(
      onCountrySelected: _onCountrySelected,
    );
  }

  Future<void> _onCountrySelected(Country country) async {
    setState(() {
      _downloading = true;
      _downloadingCountry = country.name;
    });

    try {
      final manager = ref.read(packManagerProvider);
      final dao = await manager.downloadAndInstall(country.code);

      ref.read(activeCountryProvider.notifier).setCountry(country.code);
      ref.read(cameraDaoProvider.notifier).state = dao;

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MapScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      setState(() {
        _downloading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }
}
