import 'package:flutter/material.dart';

import '../../services/orchestrator.dart';

class StatusBar extends StatelessWidget {
  final DrivingState state;

  const StatusBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (state) {
      DrivingState.driving => ('Active', Colors.green),
      DrivingState.stopping => ('Stopping...', Colors.orange),
      DrivingState.idle => ('Waiting for driving...', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
