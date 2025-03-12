import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/widgets/device_header.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/widgets/device_progress.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/widgets/device_status_section.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/widgets/emptycard.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/widgets/hardware_details.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/widgets/info_section.dart';
import 'package:warehouse_phase_1/presentation/pages/view_details.dart';
import 'package:warehouse_phase_1/src/helpers/installStream.dart';
import 'package:warehouse_phase_1/src/helpers/launch_app.dart';
import 'dart:math';
import '../../src/helpers/log_cat.dart';
import '../../src/helpers/sql_helper.dart';

class DeviceCard extends StatefulWidget {
  final Map<String, String> device;
  final double? progress;

  const DeviceCard({super.key, required this.device, required this.progress});

  @override
  _DeviceCardState createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard>{
  final Map<String?, double> deviceProgress = {}; // Store progress per device
  late StreamSubscription<int> _progressSubscription;
  bool _isDevicePresent = false;
  bool _resultsSaved = false;
  bool _isConnected = true;
    StreamSubscription<String>? _statusSubscription; // Subscription for status updates
  String _statusMessage = ""; // New status message variable
  // Add these to your class state variables
bool _isHovered = false;
bool _isButtonHovered = false;

  @override
  void initState() {
    super.initState();
    presencecheck();
    _checkDevicePresence();
   // _installAndLaunchApp(); // Start app installation and launch on initialization
    _statusMessage = widget.device['status'] ?? ''; 
     print('device id in device card is : ${widget.device['id']}');
    _listenToStatusUpdates(); // Start listening to status updates
  }
  @override
void dispose() {
 _statusSubscription?.cancel(); // Cancel subscription to avoid memory leaks
    super.dispose();

}
void _listenToStatusUpdates() {
    String deviceId = widget.device['id'] ?? '';
    _statusSubscription = installationLaunchStream.getStream(deviceId).listen((status) {
      if (mounted) {
        setState(() {
          _statusMessage = status;
        });
      }
    });
  }

//   Future<void> _installAndLaunchApp() async {
//     String deviceId = widget.device['id']??'N/A';
//     String packageName = 'com.getinstacash.warehouse';
//     String mainActivity = 'com.getinstacash.warehouse.ui.activity.StartTest';

//     setState(() {
//       _statusMessage = "Installing app...";
//     });

//     final launchApp = LaunchApp();
//     final result =
//         await launchApp.launchApplication(deviceId, packageName, mainActivity);

//    if (mounted) {
//   setState(() {
//     if (result.contains('error') || result.contains('Failed')) {
//       _statusMessage = "Error: $result";
//     } else {
//       _statusMessage = "App launched successfully.";
//     }
//   });
// }
//   }

  Future<void> presencecheck() async {
    final items = await SqlHelper.getItems();
    final deviceId = widget.device['id'] ?? '';
    _isDevicePresent = items.any((item) => item['sno'] == deviceId);
    print("is device present: $_isDevicePresent");
  }

  Future<void> _loadSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = widget.device['id']!;
    final savedProgress = prefs.getInt('$deviceId-progress') ?? 0;
    print('mera saved:progress $savedProgress');
    setState(() {
      deviceProgress[widget.device['id']] = savedProgress / 100;
    });
  }

  Future<void> _blinkScreen() async {
    String deviceId = widget.device['id']!;
    try {
      setState(() {
        _statusMessage = "Blinking screen...";
      });

      final result = await Process.run(
        'adb',
        [
          '-s',
          deviceId,
          'shell',
          'for i in 1 2 3; do input keyevent 26; sleep 1; input keyevent 26; sleep 1; done'
        ],
      );

      if (result.exitCode == 0) {
        setState(() {
          _statusMessage = "Screen blink completed";
        });
      } else {
        setState(() {
          _statusMessage = "Failed to blink screen: ${result.stderr}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error executing command: $e";
      });
    }
  }

  void _resetPercent() {
    setState(() {
      deviceProgress[widget.device['id']] = 0;
    });
  }

  Future<void> rebootDeviceToBootloader() async {
  String deviceId = widget.device['id']!;
  String packageName = 'com.getinstacash.warehouse';
  String receiverClass = '.utils.receiver.MyDeviceAdminReceiver';

  try {
    // Set device owner
    final deviceOwnerResult = await Process.run(
      'adb',
      [
        '-s', 
        deviceId, 
        'shell', 
        'dpm', 
        'set-device-owner', 
        '$packageName/$receiverClass'
      ],
    );

    if (deviceOwnerResult.exitCode == 0) {
      setState(() {
        _statusMessage = "Device owner set successfully.";
      });

      // Open WipeDataActivity
      final launchResult = await Process.run(
        'adb',
        [
          '-s', 
          deviceId, 
          'shell', 
          'am', 
          'start', 
          '-n', 
          '$packageName/.ui.activity.WipeDataActivity'
        ],
      );

      if (launchResult.exitCode == 0) {
        setState(() {
          _statusMessage = "WipeDataActivity launched successfully.";
        });
      } else {
        setState(() {
          _statusMessage = "Failed to launch WipeDataActivity: ${launchResult.stderr}";
        });
      }
    } else {
      setState(() {
        _statusMessage = "Failed to set device owner: ${deviceOwnerResult.stderr}";
      });
    }
  } catch (e) {
    setState(() {
      _statusMessage = "Error executing command: $e";
    });
  }
}
  Future<void> _checkDevicePresence() async {
    final items = await SqlHelper.getItems();
    final deviceId = widget.device['id'] ?? '';
    _isDevicePresent = items.any((item) => item['sno'] == deviceId);
    print("is device present: $_isDevicePresent");

    if (!_isDevicePresent) {
      LogCat.startLogCat(deviceId);
    }
  }

  Future<void> _loadHardwareChecks(BuildContext context) async {
    final deviceId = widget.device['id'] ?? '';
    final fileName = 'logcat_results_$deviceId.json';
    final file = File(fileName);

    if (await file.exists()) {
      final jsonContent = await file.readAsString();
      List<Map<String, dynamic>> hardwareChecks =
          List<Map<String, dynamic>>.from(jsonDecode(jsonContent));

      Map<String, dynamic>? details =
          await SqlHelper.getItemDetails(widget.device['id']);
      print("details in homepage ${details}");
      if (details != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceDetails(
              details: details,
              hardwareChecks: hardwareChecks,
              pqchecks: [], // Add the required pqchecks argument
            ),
          ),
        );
      } else {
        print('No details found for id: ${widget.device['id']}');
      }
    } else {
      print("No hardware checks found.");
    }
  }

  String safeSubstring(String? value, int length) {
    if (value == null || value.length < length) {
      return value ?? 'N/A';
    }
    return value.substring(0, min(length, 6));
  }

  
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return SingleChildScrollView(
    child: Container(
      constraints: const BoxConstraints(minHeight: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Header Section
              DeviceHeader(
                manufacturer: widget.device['manufacturer'],
                model: widget.device['model'],
                deviceId: widget.device['id'],
                onBlinkScreen: _blinkScreen,
              ),
              const SizedBox(height:4),

              // Divider Section
              const Divider(thickness: 1.0, height: 24),

              // Information Section
              InfoSection(device: widget.device),
              const Divider(thickness: 1.0, height: 24),

              // Device Status Section
              DeviceStatusSection(device: widget.device),
              const SizedBox(height: 8),

              // Device Progress Section
              DeviceProgressSection(
                progress: widget.progress,
                isDevicePresent: _isDevicePresent,
                onViewDetailsPressed: () => _loadHardwareChecks(context),
                onResetPressed: _resetPercent,
                onDataWipe: () async {
                  await rebootDeviceToBootloader();
                },
                manufacturer: widget.device['manufacturer'],
                model: widget.device['model'],
                imei: widget.device['imeiOutput'],
                deviceId: widget.device['id'],
              ),
              const SizedBox(height: 8),

              // Hardware Info Button
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HardwareDetailsPage(
                            deviceId: widget.device['id']!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.hardware, color: Colors.blueAccent),
                  label: const Text('Hardware Info'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    foregroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Status Message
              Text(
                _statusMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.blueAccent,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}


// class DeviceCard extends StatefulWidget {
//   final Map<String, String> device;

//   DeviceCard({required this.device});

//   @override
//   _DeviceCardState createState() => _DeviceCardState();
// }

// class _DeviceCardState extends State<DeviceCard> {
//   double percent = 0;
//   late StreamSubscription<int> _progressSubscription;
//   bool _isDevicePresent = false;
//   bool _resultsSaved = false;

//   @override
//   void initState() {
//     super.initState();
//     _startLogCat();
//     _checkDevicePresence();
//   }

//   Future<void> _checkDevicePresence() async {
//     final items = await SqlHelper.getItems();
//     final deviceId = widget.device['id'] ?? '';
//     _isDevicePresent = items.any((item) => item['sno'] == deviceId);
//     if (!_isDevicePresent) {
//       _startLogCat();
//     } else {
//       setState(() {});
//     }
//     }  
//     void _resetPercent() {
//     setState(() {
//       percent = 0;
//     });
//   }

//   void _startLogCat() async {
//     String? id = widget.device['id'];
//     if (id != null) {
//       try {
//         LogCat.startLogCat(id);

//         _progressSubscription =
//             LogCat.getProgressStream(id).listen((progress) async {
//           setState(() {
//             percent = progress / 100;
//             _isDevicePresent = false;
//           });

//           if (percent == 1.0 && !_resultsSaved) {
//             _resultsSaved = true;
//             await _saveResults();
//           }
//         });
//       } catch (e) {
//         print('Error starting LogCat: $e');
//       }
//     }
//   }
//   Future<void> _loadHardwareChecks(BuildContext context) async {
//     final deviceId = widget.device['id'] ?? '';
//     final fileName = 'logcat_results_$deviceId.json';
//     final file = File(fileName);

//     if (await file.exists()) {
//       final jsonContent = await file.readAsString();
//       List<Map<String, dynamic>> hardwareChecks =
//           List<Map<String, dynamic>>.from(jsonDecode(jsonContent));

//       // Fetch the details from the database
//       Map<String, dynamic>? details = await SqlHelper.getItemDetails(widget.device['id']);
      

//       if (details != null) {
//         // Pass the details to the DeviceDetails widget
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DeviceDetails(
//               details: details,
//               hardwareChecks:
//                   hardwareChecks, // Make sure hardwareChecks is defined
//             ),
//           ),
//         );
//       } else {
//         // Handle the case where no details are found
//         print('No details found for iemiOrSno: ${widget.device['id']}');
//       }
//     } else {
//       print("No hardware checks found.");
//     }
//   }


//   Future<void> _saveResults() async {
//     try {
//       await SqlHelper.createItem(
//         widget.device['manufacturer'] ?? '',
//         widget.device['model'] ?? '',
//         widget.device['imeiOutput'] ?? '',
//         widget.device['serialNumber'] ?? '',
//       );
//       await LogCat.createJsonFile(widget.device['id']);
//     } catch (e) {
//       print('Error saving results: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _progressSubscription.cancel();
//     LogCat.stopLogCat(widget.device['id']!);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Card(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20.0),
//         ),
//         elevation: 6,
//         child: Padding(
//           padding: const EdgeInsets.all(15.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               DeviceHeader(
//                 manufacturer: widget.device['manufacturer'],
//                 model: widget.device['model'],
//               ),
//               const SizedBox(height: 12),
//               const Divider(thickness: 1.0),
//               InfoSection(device: widget.device),
//               const Divider(thickness: 1.0),
//               const SizedBox(height: 12),
//               DeviceStatusSection(device: widget.device),
//               const SizedBox(height: 15),
//               DeviceProgressSection(
//                 percent: percent,
//                 isDevicePresent: _isDevicePresent,
//                 onViewDetailsPressed: () => _loadHardwareChecks(context),
//                 onResetPressed: _resetPercent,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }