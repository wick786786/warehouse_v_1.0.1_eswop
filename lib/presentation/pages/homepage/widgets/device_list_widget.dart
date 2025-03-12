import 'package:flutter/material.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/device_card.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/icard/icard.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/widgets/blacklist_devic_card.dart';
//import 'package:warehouse_phase_1/presentation/DeviceCard/widgets/icard.dart'; // Add this import
import 'package:lucide_icons/lucide_icons.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/widgets/info_row.dart';

class DeviceListWidget extends StatelessWidget {
  final Map<String, Map<String, String>> connectedDevices;
  final Map<String, Map<String, String>> connectedIosDevices;
  final Map<String?, double> deviceProgress;
  final Map<String?, int> blacklist;
  final BoxConstraints constraints;
//   final Map<String, Map<String, String>> connectedIosDevices = {
//   'device1': {
//     'modelIdentifier': 'iPhone 14',
//     'modelNumber': 'A2649',
//     'imei': '123456789012345',
//     'activationStatus': 'Activated',
//     'buildNumber': '16B92',
//     'serialNumber': 'F3K8P9WJLDQJ',
//     'udid': '123e4567-e89b-12d3-a456-426614174000',
//   },
//   'device2': {
//     'modelIdentifier': 'Samsung Galaxy S21',
//     'modelNumber': 'SM-G991B',
//     'imei': '987654321098765',
//     'activationStatus': 'Activated',
//     'buildNumber': 'G991BXXU3AUI1',
//     'serialNumber': 'R58M40LFN8J2',
//     'udid': '789e4567-e89b-12d3-a456-426614174111',
//   },
//   'device3': {
//     'modelIdentifier': 'OnePlus 9 Pro',
//     'modelNumber': 'LE2123',
//     'imei': '564738291234567',
//     'activationStatus': 'Not Activated',
//     'buildNumber': 'LE2123_11.A.13',
//     'serialNumber': 'PCA92K5F200013',
//     'udid': '456e4567-e89b-12d3-a456-426614174222',
//   },
//   'device4': {
//     'modelIdentifier': 'Google Pixel 6',
//     'modelNumber': 'GLU0G',
//     'imei': '654321098765432',
//     'activationStatus': 'Activated',
//     'buildNumber': 'SD1A.210817.037',
//     'serialNumber': 'GM02D930N5DX',
//     'udid': '321e4567-e89b-12d3-a456-426614174333',
//   },
// };

  DeviceListWidget({
    super.key,
    required this.connectedDevices,
    required this.connectedIosDevices,
    required this.deviceProgress,
    required this.blacklist,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Combine both Android and iOS devices
    final totalDevices = {...connectedDevices, ...connectedIosDevices};

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
          margin: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          width: constraints.maxWidth * 0.75,
          child: Row(
            children: [
              Text(
                'Connected Devices',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(width: 6),
              Icon(Icons.smartphone, color: theme.colorScheme.primary),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: theme.primaryColor,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.5),
                  spreadRadius: 3,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            width: constraints.maxWidth * 0.75,
            height: 550,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth < 600
                    ? 1
                    : constraints.maxWidth < 1200
                        ? 2
                        : constraints.maxWidth < 1470
                            ? 2
                            : 3,
                crossAxisSpacing: 0.0,
                mainAxisSpacing: 0.0,
                childAspectRatio: 0.7,
              ),
              itemCount: totalDevices.length,
              itemBuilder: (context, index) {
                String deviceId = totalDevices.keys.elementAt(index);
                Map<String, String> deviceDetails = totalDevices[deviceId]!;
                print('total devices details in device list ${deviceDetails}');
                bool isBlacklisted = blacklist[deviceId] == 1;
                //   print("device lsit main deviceDetails devices :${connectedIosDevices}");
                // Check if the device is an iOS device
                bool isIosDevice = connectedIosDevices.containsKey(deviceId);
                // print("device lsit main ios devices :${connectedIosDevices}");
                return SizedBox(
                  width: double.infinity,
                  child: isIosDevice
                      ? Icard(
                          title:
                              deviceDetails['modelIdentifier'] ?? 'iOS Device',
                          subtitle: 'Apple',
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               const Divider(thickness: 1.0, height: 24),
                              InfoRow(
                                  label: 'Manufacturer',
                                  value: deviceDetails['modelNumber'] ?? 'N/A',
                                  theme: theme),
                                  SizedBox(height: 5),
                              InfoRow(
                                  label: 'IMEI',
                                  value: deviceDetails['imei'] ?? 'N/A',
                                  theme: theme),
                                  SizedBox(height:5),
                           InfoRow(
                                  label: 'Activation Status',
                                  value: deviceDetails['activationStatus'] ?? 'N/A',
                                  theme: theme),
                                  SizedBox(height: 5),
                             InfoRow(
                                  label: 'Build No.',
                                  value: deviceDetails['buildNumber'] ?? 'N/A',
                                  theme: theme),
                                  SizedBox(height: 5),
                              InfoRow(
                                  label: 'Serial Number',
                                  value: deviceDetails['serialNumber'] ?? 'N/A',
                                  theme: theme),
                                  SizedBox(height: 5),
                             InfoRow(
                                  label: 'UDID',
                                  value: deviceDetails['udid'] ?? 'N/A',
                                  theme: theme),
                            ],
                          ),
                          udid: deviceDetails['udid'] ?? 'N/A',
                          progress: deviceProgress[deviceId],
                        )
                      : isBlacklisted
                          ? BlacklistDeviceCard(device: deviceDetails)
                          : DeviceCard(
                              device: deviceDetails,
                              progress: deviceProgress[deviceId],
                            ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    IconData getIconForLabel(String label) {
      switch (label.toLowerCase().trim()) {
        case 'model no.':
          return LucideIcons.smartphone;
        case 'imei':
          return LucideIcons.smartphone;
        case 'activation status':
          return LucideIcons.toggleLeft;
        case 'build no.':
          return LucideIcons.layers;
        case 'serial no.':
          return LucideIcons.key;
        case 'udid':
          return LucideIcons.fingerprint;
        default:
          return LucideIcons.info;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon with subtle background
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              getIconForLabel(label),
              size: 14,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 8),
          // Label
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Value
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
