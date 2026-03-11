import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/model/country.dart';
import '../../providers/pack_provider.dart';
import '../theme/racing_colors.dart';
import '../widgets/racing_decorations.dart';

class CountryPickerScreen extends ConsumerWidget {
  final void Function(Country country) onCountrySelected;

  const CountryPickerScreen({super.key, required this.onCountrySelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countriesAsync = ref.watch(countriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SELECT YOUR TRACK')),
      body: countriesAsync.when(
        data: (countries) {
          final enabled = countries.where((c) => c.packVersion != null).toList();
          if (enabled.isEmpty) {
            return const Center(
              child: Text('No tracks available yet.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: enabled.length,
            itemBuilder: (context, index) {
              final country = enabled[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RacingStripeCard(
                  stripeColor: RacingColors.shellBlue,
                  child: ListTile(
                    title: Text(country.name),
                    subtitle: Text(country.cameraCount != null
                        ? '${country.cameraCount} cameras'
                        : ''),
                    trailing: Icon(Icons.download,
                        color: RacingColors.coinGold.withValues(alpha: 0.7)),
                    onTap: () => onCountrySelected(country),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off,
                    size: 48,
                    color: RacingColors.coinGold.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  'Could not load tracks.\n'
                  'If you just opened the app, the server may be starting—tap Retry in a few seconds.\n'
                  'Otherwise check your internet connection.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(countriesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
