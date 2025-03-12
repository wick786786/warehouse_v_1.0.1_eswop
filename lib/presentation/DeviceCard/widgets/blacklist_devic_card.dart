import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/widgets/device_progress.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/widgets/device_status_section.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/widgets/info_section.dart';
import 'package:warehouse_phase_1/presentation/pages/view_details.dart';
import 'package:warehouse_phase_1/src/helpers/sql_helper.dart';

class BlacklistDeviceCard extends StatelessWidget {
  final Map<String, String> device;
  //final double? progress;

  const BlacklistDeviceCard({
    super.key,
    required this.device,
    //required this.progress,
  });
  Future<void> _loadHardwareChecks(BuildContext context) async {
    final deviceId = device['id'] ?? '';
    print("blacklist mai device details $device");

    // Save the device details into the database
    final int result = await SqlHelper.createItem(
        device['manufacturer'],
        device['model'],
        device['imeiOutput'],
        device['serialNumber'],
        device['ram'],
        device['mdm_status'].toString(),
        device['oem'].toString(),
        device['rom'],
        device['carrier_lock'],
        device['androidVersion'],
        '0',
        
        );

    if (result != 0) {
      print("Device details saved successfully with ID: $result");

      // Get device details from the database
      Map<String, dynamic>? details = await SqlHelper.getItemDetails(deviceId);

      // Create the JSON file with the message
      final fileName = 'logcat_results_$deviceId.json';
      final file = File(fileName);

      // Write the message to the JSON file
      final hardwareChecks = [
        {'Blacklist':'1'}
      ];
      await file.writeAsString(jsonEncode(hardwareChecks));
      
      // Navigate to DeviceDetails if the details are found
      if (details != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceDetails(
             
              details: details,
              hardwareChecks: hardwareChecks, // Pass the hardware checks message
              pqchecks: [], // Add the required pqchecks argument
            ),
          ),
        );
      } else {
        print('No details found for id: $deviceId');
      }
    } else {
      print('Failed to save device details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        constraints: const BoxConstraints(minHeight: 200), // Set minimum height
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 6,
          color: Colors.red.withOpacity(0.7),

          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with red background
                Container(
                    decoration: BoxDecoration(
                      //color: Colors.red, // Red color header
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Aligns text to the start of the column
                      children: [
                        Text(
                          'Blacklisted device',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8), // Add some vertical spacing
                        Row(
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // Ensures that the content starts at the top
                          children: [
                            Expanded(
                              // Wrap this part in Expanded to avoid overflow
                              child: Text(
                                device['manufacturer'] ??
                                    'Unknown Manufacturer',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow
                                    .visible, // Ensures text wraps instead of overflowing
                              ),
                            ),
                            const SizedBox(
                                width:
                                    3), // Add spacing between manufacturer and model
                            Flexible(
                              // Ensures model text can wrap if necessary
                              child: Text(
                                device['model'] ?? 'Unknown Model',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow
                                    .visible, // Makes sure the text wraps instead of overflowing
                              ),
                            ),
                          ],
                        ),
                      ],
                    )),
                const SizedBox(height: 12),
                const Divider(thickness: 1.0),
                // Info Section (Same as original DeviceCard)
                InfoSection(device: device),
                const Divider(thickness: 1.0),
                const SizedBox(height: 12),
                // Status Section
                DeviceStatusSection(device: device),
                const SizedBox(height: 15),
                // Progress Section (can be the same as DeviceCard)
                DeviceProgressSection(
                  progress: 100,
                  isDevicePresent: true, // Adjust based on your blacklist logic
                  onViewDetailsPressed: () async {
                    // Navigate to view details page
                    _loadHardwareChecks(context);
                  },
                  onResetPressed: () {
                    // Handle reset percent
                  },
                  manufacturer: device['manufacturer'],
                  model: device['model'],
                  imei: device['imeiOutput'],
                  deviceId: device['id'],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
