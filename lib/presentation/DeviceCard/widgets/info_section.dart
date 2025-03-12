import 'package:flutter/material.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/widgets/info_row.dart';

class InfoSection extends StatelessWidget {
  final Map<String, dynamic> device;

  const InfoSection({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        InfoRow(label: 'Model', value: device['model'] ?? 'N/A', theme: theme),
        InfoRow(
            label: 'Manufacturer',
            value: device['manufacturer'] ?? 'N/A',
            theme: theme),
        InfoRow(
            label: 'Version',
            value: device['androidVersion'] ?? 'N/A',
            theme: theme),
        InfoRow(
            label: 'Serial No.',
            value: device['serialNumber'] ?? 'N/A',
            theme: theme),
        InfoRow(label: 'IMEI', value: device['imeiOutput'] ?? 'N/A', theme: theme),
      ],
    );
  }
}
