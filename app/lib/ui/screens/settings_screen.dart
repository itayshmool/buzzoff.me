import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';
import '../../providers/database_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final cameraCount = ref.watch(cameraCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Alert Distance
          _SectionTitle('Alert Distance'),
          _RadioGroup<double>(
            value: settings.alertDistanceMeters,
            options: {500.0: '500m', 800.0: '800m', 1200.0: '1200m'},
            onChanged: notifier.updateAlertDistance,
          ),

          const SizedBox(height: 24),

          // Alert Type
          _SectionTitle('Alert Type'),
          SwitchListTile(
            title: const Text('Vibration'),
            value: settings.vibrationEnabled,
            onChanged: notifier.toggleVibration,
          ),
          SwitchListTile(
            title: const Text('Sound'),
            value: settings.soundEnabled,
            onChanged: notifier.toggleSound,
          ),

          const SizedBox(height: 24),

          // Activate at speed
          _SectionTitle('Activate at speed'),
          _RadioGroup<double>(
            value: settings.activateAtSpeedKmh,
            options: {30.0: '30 km/h', 40.0: '40 km/h', 50.0: '50 km/h'},
            onChanged: notifier.updateActivateAtSpeed,
          ),

          const SizedBox(height: 24),

          // Camera types
          _SectionTitle('Camera types'),
          SwitchListTile(
            title: const Text('Speed cameras'),
            value: settings.speedCamerasEnabled,
            onChanged: notifier.toggleSpeedCameras,
          ),
          SwitchListTile(
            title: const Text('Red light cameras'),
            value: settings.redLightCamerasEnabled,
            onChanged: notifier.toggleRedLightCameras,
          ),
          SwitchListTile(
            title: const Text('Average speed zones'),
            value: settings.avgSpeedZonesEnabled,
            onChanged: notifier.toggleAvgSpeedZones,
          ),

          const SizedBox(height: 24),

          // Camera count
          Center(
            child: Text(
              'Cameras loaded: $cameraCount',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _RadioGroup<T> extends StatelessWidget {
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _RadioGroup({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: options.entries.map((entry) {
        final selected = entry.key == value;
        return ChoiceChip(
          label: Text(entry.value),
          selected: selected,
          onSelected: (_) => onChanged(entry.key),
        );
      }).toList(),
    );
  }
}
