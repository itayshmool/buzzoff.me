import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/model/app_settings.dart';
import '../providers/driving_state_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/database_provider.dart';
import '../providers/pack_provider.dart';
import '../providers/simulation_provider.dart';
import '../ui/theme/racing_colors.dart';
import '../ui/widgets/racing_decorations.dart';

/// Preview-only settings screen. Identical layout to the real SettingsScreen
/// but without PackManager dependencies (sqlite3 is unavailable on web).
class PreviewSettingsScreen extends ConsumerWidget {
  const PreviewSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final cameraCount = ref.watch(cameraCountProvider);
    final activeCountry = ref.watch(activeCountryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RACE SETUP'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Alert Distance
          _SectionTitle('WARNING RANGE'),
          _RadioGroup<double>(
            value: settings.alertDistanceMeters,
            options: {500.0: '500m', 800.0: '800m', 1200.0: '1200m'},
            onChanged: notifier.updateAlertDistance,
          ),

          const SizedBox(height: 8),
          const RainbowDivider(),
          const SizedBox(height: 8),

          // Vibration
          _SectionTitle('RUMBLE'),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('Vibration'),
                  value: settings.vibrationEnabled,
                  onChanged: notifier.toggleVibration,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton(
                  onPressed: settings.vibrationEnabled
                      ? () => ref.read(alertServiceProvider).testVibration()
                      : null,
                  child: const Text('Test'),
                ),
              ),
            ],
          ),
          if (settings.vibrationEnabled) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: _RadioGroup<VibrationIntensity>(
                value: settings.vibrationIntensity,
                options: const {
                  VibrationIntensity.low: 'Low',
                  VibrationIntensity.medium: 'Medium',
                  VibrationIntensity.high: 'High',
                },
                onChanged: notifier.updateVibrationIntensity,
              ),
            ),
          ],

          const SizedBox(height: 8),
          const RainbowDivider(),
          const SizedBox(height: 8),

          // Sound
          _SectionTitle('HORN'),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('Sound'),
                  value: settings.soundEnabled,
                  onChanged: notifier.toggleSound,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton(
                  onPressed: settings.soundEnabled
                      ? () => ref.read(alertServiceProvider).testSound()
                      : null,
                  child: const Text('Test'),
                ),
              ),
            ],
          ),
          if (settings.soundEnabled) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: _RadioGroup<AlertSound>(
                value: settings.alertSound,
                options: {
                  for (final sound in AlertSound.values)
                    sound: sound.displayName,
                },
                onChanged: notifier.updateAlertSound,
              ),
            ),
          ],

          const SizedBox(height: 8),
          const RainbowDivider(),
          const SizedBox(height: 8),

          // Gauge units
          _SectionTitle('GAUGE UNITS'),
          _RadioGroup<SpeedUnit>(
            value: settings.speedUnit,
            options: const {
              SpeedUnit.kmh: 'km/h',
              SpeedUnit.mph: 'mph',
            },
            onChanged: notifier.updateSpeedUnit,
          ),

          const SizedBox(height: 8),
          const RainbowDivider(),
          const SizedBox(height: 8),

          // Activate at speed
          _SectionTitle('MIN RACE SPEED'),
          _RadioGroup<double>(
            value: settings.activateAtSpeedKmh,
            options: {30.0: '30 km/h', 40.0: '40 km/h', 50.0: '50 km/h'},
            onChanged: notifier.updateActivateAtSpeed,
          ),

          const SizedBox(height: 8),
          const RainbowDivider(),
          const SizedBox(height: 8),

          // Sleep timeout
          _SectionTitle('PIT STOP TIMER'),
          _RadioGroup<int>(
            value: settings.sleepAfterMinutes,
            options: {3: '3 min', 5: '5 min', 10: '10 min', 15: '15 min'},
            onChanged: notifier.updateSleepAfterMinutes,
          ),

          const SizedBox(height: 8),
          const RainbowDivider(),
          const SizedBox(height: 8),

          // Camera types
          _SectionTitle('ITEM TYPES'),
          SwitchListTile(
            title: const Text('Blue Shells'),
            subtitle: const Text('Speed cameras'),
            value: settings.speedCamerasEnabled,
            onChanged: notifier.toggleSpeedCameras,
          ),
          SwitchListTile(
            title: const Text('Red Shells'),
            subtitle: const Text('Red light cameras'),
            value: settings.redLightCamerasEnabled,
            onChanged: notifier.toggleRedLightCameras,
          ),
          SwitchListTile(
            title: const Text('Star Zones'),
            subtitle: const Text('Average speed zones'),
            value: settings.avgSpeedZonesEnabled,
            onChanged: notifier.toggleAvgSpeedZones,
          ),

          const SizedBox(height: 8),
          const RainbowDivider(),
          const SizedBox(height: 8),

          // Country
          _SectionTitle('RACE TRACK'),
          if (activeCountry != null) ...[
            RacingStripeCard(
              child: ListTile(
                title: Text(activeCountry),
                subtitle: Text('$cameraCount cameras loaded'),
                trailing: Icon(Icons.swap_horiz,
                    color: RacingColors.coinGold.withValues(alpha: 0.7)),
              ),
            ),
          ] else
            const RacingStripeCard(
              child: ListTile(
                title: Text('No track selected'),
                subtitle: Text('Download a camera pack to get started'),
              ),
            ),

          const SizedBox(height: 24),

          // Camera count
          Center(
            child: Text(
              'Cameras loaded: $cameraCount',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          const SizedBox(height: 24),
          const RainbowDivider(),
          const SizedBox(height: 8),

          // Debug section
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.4),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'DEBUG',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Simulation Mode'),
                  subtitle: const Text('Fake GPS along Ayalon Hwy at 80 km/h'),
                  value: ref.watch(simulationEnabledProvider),
                  activeTrackColor: Colors.purpleAccent,
                  onChanged: (_) {
                    ref.read(simulationEnabledProvider.notifier).toggle();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const RainbowDivider(),
          const SizedBox(height: 8),

          // About
          _SectionTitle('PIT CREW'),
          RacingStripeCard(
            stripeColor: RacingColors.coinGold,
            child: ListTile(
              leading: const Icon(Icons.info_outline,
                  color: RacingColors.coinGold),
              title: const Text('BuzzOff'),
              subtitle: const Text('Preview Build'),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
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
