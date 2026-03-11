import 'package:flutter/material.dart';

import '../theme/racing_colors.dart';

class DownloadProgress extends StatelessWidget {
  final String countryName;
  final double progress;
  final int? totalBytes;

  const DownloadProgress({
    super.key,
    required this.countryName,
    required this.progress,
    this.totalBytes,
  });

  @override
  Widget build(BuildContext context) {
    final sizeText = totalBytes != null
        ? ' (${_formatBytes(totalBytes!)})'
        : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Loading track: $countryName$sizeText',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: progress > 0 ? progress : null,
          backgroundColor: RacingColors.trackSurface,
          valueColor:
              const AlwaysStoppedAnimation<Color>(RacingColors.racingRed),
        ),
        const SizedBox(height: 8),
        if (progress > 0)
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
