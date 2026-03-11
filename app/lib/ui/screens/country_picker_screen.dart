import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/model/country.dart';
import '../../providers/pack_provider.dart';

class CountryPickerScreen extends ConsumerWidget {
  final void Function(Country country) onCountrySelected;

  const CountryPickerScreen({super.key, required this.onCountrySelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countriesAsync = ref.watch(countriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Select your country')),
      body: countriesAsync.when(
        data: (countries) {
          final enabled = countries.where((c) => c.packVersion != null).toList();
          if (enabled.isEmpty) {
            return const Center(
              child: Text('No countries available yet.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: enabled.length,
            itemBuilder: (context, index) {
              final country = enabled[index];
              return _CountryCard(
                country: country,
                onTap: () => onCountrySelected(country),
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
                const Icon(Icons.cloud_off, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Could not load countries.\n'
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

class _CountryCard extends StatelessWidget {
  final Country country;
  final VoidCallback onTap;

  const _CountryCard({required this.country, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cameraText = country.cameraCount != null
        ? '${country.cameraCount} cameras'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(country.name),
        subtitle: Text(cameraText),
        trailing: const Icon(Icons.download),
        onTap: onTap,
      ),
    );
  }
}
