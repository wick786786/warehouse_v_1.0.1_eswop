import 'dart:math';
import 'package:flutter/material.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/widgets/mdm_status.dart';

class DeviceStatusSection extends StatelessWidget {
  final Map<String, dynamic> device;

  const DeviceStatusSection({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [

        
        
        // MDM Status Section
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
          child: Container(
            padding: const EdgeInsets.all(5),
            // width: 50.0,
            color: theme.colorScheme.primary.withOpacity(0.2),
            child: Column(
              children: [
                MdmStatus(status: device['mdm_status']),
                Text(
                  'MDM',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Battery Level Section
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
          child: Container(
            padding: const EdgeInsets.all(5),
            //width: 50.0,
            color: theme.colorScheme.primary.withOpacity(0.2),
            child: Column(
              children: [
                Text(
                  '${device['rom']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'ROM',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // RAM Section
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
          child: Container(
            padding: const EdgeInsets.all(5),
            // width: 50.0,
            color: theme.colorScheme.primary.withOpacity(0.2),
            child: Column(
              children: [
                Text(
                  '${device['ram']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'RAM',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // OEM Section
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
          child: Container(
            padding: const EdgeInsets.all(5),
            //  width: 50.0,
            color: theme.colorScheme.primary.withOpacity(0.2),
            child: Column(
              children: [
                Icon(
                  const IconData(0xe596, fontFamily: 'MaterialIcons'),
                  color: device['oem'] == '0'
                      ? theme.colorScheme.primary
                      : Colors.red,
                ),
                Text(
                  'OEM',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
