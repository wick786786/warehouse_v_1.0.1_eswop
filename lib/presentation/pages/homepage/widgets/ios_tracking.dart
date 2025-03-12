import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:warehouse_phase_1/src/helpers/iphone_model.dart';

class IOSDeviceUtils {
  // Singleton instance
  static final IOSDeviceUtils _instance = IOSDeviceUtils._internal();
  factory IOSDeviceUtils() => _instance;
  IOSDeviceUtils._internal();

  // Stream controller for device updates
  final _deviceController = StreamController<List<String>>.broadcast();

  /// Checks if libimobiledevice tools are installed
  Future<bool> checkDependencies() async {
    try {
      final result = await Process.run('idevice_id', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      print('libimobiledevice tools not found: $e');
      return false;
    }
  }

  /// Get list of connected iOS device IDs
  Future<List<String>> getConnectedDevices() async {
    try {
      final result = await Process.run('idevice_id', ['-l']);
      if (result.exitCode == 0) {
        return (result.stdout as String)
            .split('\n')
            .where((id) => id.isNotEmpty)
            .toList();
      }
    } catch (e) {
      print('Error getting connected devices: $e');
    }
    return [];
  }

  /// Get basic device information
  Future<Map<String, String>> getBasicDeviceInfo(String deviceId) async {
  Map<String, String> deviceInfo = {};
  print('Basic info function mai device id $deviceId');
  try {
    // Get device name
    final nameResult = await Process.run('cmd', ['/c', 'idevicename', '-u', deviceId]);
    if (nameResult.exitCode == 0) {
      deviceInfo['deviceName'] = (nameResult.stdout as String).trim();
    }
    
    // Get basic device info
   final infoResult = await Process.run('cmd', ['/c', 'ideviceinfo', '-u', deviceId]);
    print('info result :${infoResult.exitCode}');
    if (infoResult.exitCode == 0) {
      final infoLines = (infoResult.stdout as String).split('\n');
      print('info lines :${infoLines}');
      // Define the key information we want to extract
      final keysToExtract = {
        'DeviceClass': 'deviceType',
        'ProductType': 'modelIdentifier',
        'ModelNumber': 'modelNumber',
        'SerialNumber': 'serialNumber',
        'ProductVersion': 'iOSVersion',
        'BuildVersion': 'buildNumber',
        'CPUArchitecture': 'cpuArchitecture',
        'DeviceColor': 'deviceColor',
        'InternationalMobileEquipmentIdentity': 'imei',
        'BasebandVersion': 'modemFirmware',
        'WiFiAddress': 'wifiMacAddress',
        'BluetoothAddress': 'bluetoothMacAddress',
        'ActivationState': 'activationStatus'
      };
      
      for (final line in infoLines) {
        if (line.contains(':')) {
          final parts = line.split(':').map((e) => e.trim()).toList();
          if (parts.length >= 2) {
            final key = parts[0];
            final value = parts[1];
            
            // Only add the keys we're interested in
            if (keysToExtract.containsKey(key)) {
              deviceInfo[keysToExtract[key]!] = value;
            }
          }
        }
      }
      String? modelName = IPhoneModelMapper.getModelName(deviceInfo['modelIdentifier'] ?? '');
      deviceInfo['modelIdentifier'] = modelName ?? deviceInfo['modelIdentifier']??'N/A';
      print('device info in ios_tracking :${deviceInfo}');
    }
    
    // Add battery info if available
    try {
      final batteryResult = await Process.run('ideviceinfo', ['-u', deviceId, '-q', 'com.apple.mobile.battery']);
      if (batteryResult.exitCode == 0) {
        final batteryLines = (batteryResult.stdout as String).split('\n');
        for (final line in batteryLines) {
          if (line.contains('BatteryCurrentCapacity:')) {
            final batteryLevel = line.split(':')[1].trim();
            deviceInfo['batteryLevel'] = '$batteryLevel%';
            break;
          }
        }
      }
    } catch (e) {
      // Battery info not available
    }
    
  } catch (e) {
    print('Error getting basic device info: $e');
  }
  
  return deviceInfo;
}

  /// Get detailed device information
  Future<Map<String, dynamic>> getDetailedDeviceInfo(String deviceId) async {
    Map<String, dynamic> detailedInfo = {};
    
    try {
      final result = await Process.run('cmd', ['/c','ideviceinfo','-u', deviceId, '-x']);
      if (result.exitCode == 0) {
        detailedInfo = json.decode(result.stdout as String);
      }
    } catch (e) {
      print('Error getting detailed device info: $e');
    }

    return detailedInfo;
  }

  /// Get device activation status
  Future<Map<String, dynamic>> getActivationStatus(String deviceId) async {
    Map<String, dynamic> activationInfo = {};
    
    try {
      final result = await Process.run('cmd', ['/c','ideviceactivation','status', '-u', deviceId]);
      if (result.exitCode == 0) {
        activationInfo = {
          'status': (result.stdout as String).contains('Activated') ? 'Activated' : 'Not Activated',
          'raw_output': result.stdout,
        };
      }
    } catch (e) {
      print('Error getting activation status: $e');
      activationInfo = {'status': 'Unknown', 'error': e.toString()};
    }

    return activationInfo;
  }
//   Future<List<Map<String, String>>> getAdminApps(String deviceId) async {
//   List<Map<String, String>> adminApps = [];
  
//   try {
//     // Use ideviceinstaller to list all applications
//     final result = await Process.run('cmd', [
//       '/c',
//       'ideviceinstaller',
//       '-u',
//       deviceId,
//       '-list',
//       '-o',
//       'list_system'
//     ]);

//     if (result.exitCode == 0) {
//       final output = result.stdout as String;
//       print('output of admin apps:${output}');
//       final lines = output.split('\n');
      
//       // Parse each line containing app info
//       for (var line in lines) {
//         if (line.isNotEmpty) {
//           // Split the line into app ID and name
//           // Format is typically: com.apple.AppName, AppName, SystemApplication
//           final parts = line.split(',').map((e) => e.trim()).toList();
//           if (parts.length >= 2 && parts.contains('SystemApplication')) {
//             adminApps.add({
//               'bundleId': parts[0],
//               'name': parts[1],
//               'type': 'SystemApplication'
//             });
//           }
//         }
//       }
//     }
//   } catch (e) {
//     print('Error getting admin apps: $e');
//   }
  
//   return adminApps;
// }

  /// Get device diagnostics information
  Future<Map<String, dynamic>> getDiagnostics(String deviceId) async {
    Map<String, dynamic> diagnostics = {};
    
    try {
      final result = await Process.run('cmd', ['/c','idevicediagnostics','diagnostics', '-u', deviceId]);
      if (result.exitCode == 0) {
        diagnostics = json.decode(result.stdout as String);
      }
    } catch (e) {
      print('Error getting diagnostics: $e');
    }

    return diagnostics;
  }

  /// Get device battery information
  Future<Map<String, dynamic>> getBatteryInfo(String deviceId) async {
    Map<String, dynamic> batteryInfo = {};
    
    try {
      final result = await Process.run('cmd', ['/c','idevicediagnostics','ioreg', '-u', deviceId]);
      if (result.exitCode == 0) {
        // Parse battery information from ioreg output
        final output = result.stdout as String;
        if (output.contains('BatteryLevel')) {
          batteryInfo['level'] = RegExp(r'BatteryLevel\D+(\d+)').firstMatch(output)?.group(1);
        }
        if (output.contains('ExternalChargeCapable')) {
          batteryInfo['charging'] = output.contains('ExternalChargeCapable = Yes');
        }
      }
    } catch (e) {
      print('Error getting battery info: $e');
    }

    return batteryInfo;
  }
  Future<String> getICloudLockStatus(String deviceId) async {
  try {
    // Execute the command to check ActivationState
    ProcessResult result = await Process.run('cmd',['/c'
      'ideviceinfo','-u',deviceId,
      '-k', 'ActivationState'],
    );

    // Check if the command executed successfully
    if (result.exitCode == 0) {
      String output = result.stdout.toString().trim();

      // Parse the output to determine lock status
      if (output.contains('Activated')) {
        return 'Unlocked';
      } else if (output.contains('Locked')) {
        return 'Locked';
      } else {
        return 'Unknown Status: $output';
      }
    } else {
      // If the command fails, return an error message
      return 'Error: ${result.stderr.toString().trim()}';
    }
  } catch (e) {
    // Handle exceptions, such as command not found or permission issues
    return 'Error executing command: $e';
  }
}

  Future<bool> isDeviceCarrierLocked(String id) async {
  try {
    // Run the `ideviceinfo` command with the specific UDID and capture the output
    final result = await Process.run('ideviceinfo', ['-u', id]);
    
    if (result.exitCode != 0) {
      print('Error running ideviceinfo for device $id: ${result.stderr}');
      return false; // Return false if we can't determine lock status
    }

    // Get the command output
    final output = result.stdout as String;

    // Check relevant fields in the output to determine lock status
    final activationState = _getFieldValue(output, 'ActivationState');
    final simStatus = _getFieldValue(output, 'SIMStatus');
    final postponementStatus = _getFieldValue(output, 'kCTPostponementStatus');

    // Determine carrier lock based on field values
    if (activationState == 'Activated' && 
        simStatus == 'kCTSIMSupportSIMStatusReady' &&
        postponementStatus == 'kCTPostponementStatusActivated') {
      return false; // Device is likely unlocked
    } else {
      return true; // Device is likely carrier locked
    }
  } catch (e) {
    print('Exception while checking carrier lock status for device $id: $e');
    return false;
  }
}
// Helper function to extract the value of a specific field from the output
String? _getFieldValue(String output, String fieldName) {
  final regex = RegExp('$fieldName: (.+)');
  final match = regex.firstMatch(output);
  return match?.group(1)?.trim();
}

  /// Get formatted device specifications
  Future<Map<String, String>> getDeviceSpecifications(String deviceId) async {
    Map<String, String> specs = {};
    
    try {
      final basicInfo = await getBasicDeviceInfo(deviceId);
      final detailedInfo = await getDetailedDeviceInfo(deviceId);
      final activationInfo = await getActivationStatus(deviceId);
      final batteryInfo=await getBatteryInfo(deviceId);
      print('basic info:$basicInfo');
      print('detailed info : ${detailedInfo}');
      print('activation info :${activationInfo}');
      print('battery info of IOS : ${batteryInfo}');
      specs = {
        'id': deviceId,
        'manufacturer': 'Apple',
        'model': basicInfo['deviceName'] ?? 'Unknown',
        'serialNumber': basicInfo['SerialNumber'] ?? 'Unknown',
        'imeiOutput': basicInfo['UniqueDeviceID'] ?? 'Unknown',
        'iOSVersion': basicInfo['ProductVersion'] ?? 'Unknown',
        'activation_status': activationInfo['status'] ?? 'Unknown',
        'deviceType': basicInfo['DeviceClass'] ?? 'Unknown',
        'capacity': _formatStorage(detailedInfo['TotalDiskCapacity']),
        'freeSpace': _formatStorage(detailedInfo['AvailableDiskCapacity']),
        'mdm_status': detailedInfo['MDMEnabled'] == true ? 'Enabled' : 'Disabled',
        'carrier_lock': detailedInfo['CarrierLocked'] == true ? 'Locked' : 'Unlocked',
      };
    } catch (e) {
      print('Error getting device specifications: $e');
    }

    return specs;
  }

  /// Helper function to format storage size
  String _formatStorage(dynamic bytes) {
    if (bytes == null) return 'Unknown';
    
    final gb = (bytes as int) / (1024 * 1024 * 1024);
    return '${gb.toStringAsFixed(2)} GB';
  }

  /// Start monitoring for device connections/disconnections
  Stream<List<String>> startDeviceMonitoring() {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      final devices = await getConnectedDevices();
      _deviceController.add(devices);
    });

    return _deviceController.stream;
  }
  Future<Map<String, Map<String, String>>> getAllConnectedDevicesDetails() async {
  final deviceUtils = IOSDeviceUtils();
  final Map<String, Map<String, String>> connectedDevices = {};
  
  try {
    // Check if dependencies are installed
    final hasDependencies = await deviceUtils.checkDependencies();
    if (!hasDependencies) {
      print('Required libimobiledevice tools are not installed');
      return {};
    }
    
    // Get list of connected device IDs
    final deviceIds = await deviceUtils.getConnectedDevices();
    
    // Get specifications for each device
    for (final deviceId in deviceIds) {
      final specs = await deviceUtils.getDeviceSpecifications(deviceId);
      
      // Add battery information
      final batteryInfo = await deviceUtils.getBatteryInfo(deviceId);
      if (batteryInfo.containsKey('level')) {
        specs['batteryLevel'] = '${batteryInfo['level']}%';
      }
      if (batteryInfo.containsKey('charging')) {
        specs['chargingStatus'] = batteryInfo['charging'] ? 'Charging' : 'Not Charging';
      }
      
      connectedDevices[deviceId] = specs;
    }
  } catch (e) {
    print('Error getting connected devices details: $e');
  }
  
  return connectedDevices;
}

  /// Stop device monitoring
  void stopDeviceMonitoring() {
    _deviceController.close();
  }
}

// Example usage:
/*
void main() async {
  final iosUtils = IOSDeviceUtils();
  
  // Check if required tools are installed
  final hasTools = await iosUtils.checkDependencies();
  if (!hasTools) {
    print('Please install libimobiledevice tools');
    return;
  }

  // Get connected devices
  final devices = await iosUtils.getConnectedDevices();
  for (final deviceId in devices) {
    // Get device specifications
    final specs = await iosUtils.getDeviceSpecifications(deviceId);
    print('Device Specifications:');
    specs.forEach((key, value) => print('$key: $value'));

    // Get battery information
    final batteryInfo = await iosUtils.getBatteryInfo(deviceId);
    print('\nBattery Information:');
    batteryInfo.forEach((key, value) => print('$key: $value'));
  }

  // Start monitoring for device connections
  final subscription = iosUtils.startDeviceMonitoring().listen((devices) {
    print('Connected devices: ${devices.join(", ")}');
  });

  // Remember to stop monitoring when done
  // subscription.cancel();
  // iosUtils.stopDeviceMonitoring();
}
*/