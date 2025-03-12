import 'package:flutter/material.dart';

class DeviceHeader extends StatelessWidget {
  final String? manufacturer;
  final String? model;
  final String? deviceId;
  final VoidCallback onBlinkScreen; // Add callback

  const DeviceHeader({
    super.key,
    required this.manufacturer,
    required this.model,
    required this.deviceId,
    required this.onBlinkScreen, // Require callback
  });

  @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Device Info Section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$manufacturer $model",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                deviceId??'N/A',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Track Me Button
        ElevatedButton.icon(
          onPressed: onBlinkScreen,
          icon: const Icon(Icons.track_changes, size: 16),
          label: const Text('Track Me'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),

        // Online Indicator
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
      ],
    ),
  );
}

}
