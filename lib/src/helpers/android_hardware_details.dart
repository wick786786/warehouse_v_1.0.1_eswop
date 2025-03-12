import 'dart:io';

class AndroidHardwareDetails {
    Map<String, Map<String,String>> hardwareInfo = {};
  static Future<String> _executeAdbCommand(List<String> command, String deviceId) async {
    try {
      final result = await Process.run('adb', ['-s', deviceId, ...command]);
      if (result.exitCode == 0) {
        return result.stdout.toString();
      }
      print('Error executing ${command.join(' ')}: ${result.stderr}');
      return 'Error executing command';
    } catch (e) {
      print('Exception executing ${command.join(' ')}: $e');
      return 'Error: $e';
    }
  }

  Future<Map<String, Map<String,String>>> fetchHardwareDetails(String deviceId) async {
    try {
      // Fetch CPU Info
      String processorInfo = await _executeAdbCommand(['shell', 'cat /proc/cpuinfo'], deviceId);

      // Fetch ABI
      String abi = await _executeAdbCommand(['shell', 'getprop ro.product.cpu.abi'], deviceId);

      // Fetch Supported ABI
      String supportedAbi = await _executeAdbCommand(['shell', 'getprop ro.product.cpu.abilist'], deviceId);

      // Battery Info
      String batteryInfo = await _executeAdbCommand(['shell', 'dumpsys battery'], deviceId);

      // Display Info
      String displayInfo = await _executeAdbCommand(['shell', 'dumpsys display'], deviceId);

      // Refresh Rate Info
      String refreshRateInfo = await _executeAdbCommand(['shell', 'dumpsys display | grep -E "DisplayDeviceInfo|refreshRate"'], deviceId);

      // GPU Info
      String gpuInfo = await _executeAdbCommand(['shell', 'getprop ro.hardware.vulkan && getprop ro.opengles.version'], deviceId);

      // Sensors List
      String sensorsInfo = await _executeAdbCommand(['shell', 'dumpsys sensorservice | grep "Sensor"'], deviceId);

      String formattedProcessorInfo = _formatProcessorInfo(processorInfo, abi.trim(), supportedAbi.trim());
      String formattedBatteryInfo = _formatBatteryInfo(batteryInfo);
      String formattedDisplayInfo = _formatDisplayInfo(displayInfo);
      String formattedGpuInfo = _formatGpuInfo(gpuInfo);
      String formattedSensorsInfo = _formatSensorsInfo(sensorsInfo);
       print('Display Info: $formattedDisplayInfo');
       hardwareInfo[deviceId]={
        'Processor': formattedProcessorInfo,
        'Battery': formattedBatteryInfo,
        'Display': formattedDisplayInfo,
        'GPU': formattedGpuInfo,
        'Sensors': formattedSensorsInfo,
       };
     return hardwareInfo;
    
    } catch (e) {
      print('Error fetching hardware details: $e');
      
    }
    return {};
  }

 
  

   static String _formatProcessorInfo(String raw, String abi, String supportedAbi) {
  List<String> parts = raw.trim().split('\n');
  
  // Variables to store extracted data
  String hardware = 'Unknown';
  int cores = 0;
  String cpuDetails = '';
  String process = 'Unknown';

  // Loop through each line of the raw string
  for (String line in parts) {
    if (line.startsWith('Hardware')) {
      hardware = line.split(':').last.trim();
    } else if (line.startsWith('processor')) {
      cores++; // Count the number of processors to determine the number of cores
    } else if (line.startsWith('CPU part')) {
      // For simplicity, assuming part represents a portion of the CPU details
      cpuDetails += ' ${line.split(':').last.trim()}';
    }
  }
  Map<String, String> processorInfo = {
    'hardware': hardware,
    'cores': cores.toString(),
    'abi': abi,
    'supportedAbi': supportedAbi,
  };

  return processorInfo.toString();
}

  // String _formatTemperature(String raw) {
  //   try {
  //     int temp = int.parse(raw.trim().split('\n').first) ~/ 1000;
  //     return '$temp°C';
  //   } catch (e) {
  //     return 'Unknown';
  //   }
  // }

  // String _formatMemoryInfo(String raw) {
  //   List<String> lines = raw.split('\n');
  //   return lines.take(4).join('\n');
  // }

 static String _formatBatteryInfo(String raw) {
  Map<String, String> batteryStats = {};
  
  // Splitting the input and parsing key-value pairs
  for (String line in raw.split('\n')) {
    if (line.contains(':')) {
      List<String> parts = line.split(':');
      if (parts.length == 2) {
        batteryStats[parts[0].trim()] = parts[1].trim();
      }
    }
  }
  
  // Convert health status into human-readable format
  String healthStatus;
  switch (batteryStats['health']) {
    case '1':
      healthStatus = 'Good';
      break;
    case '2':
      healthStatus = 'Overheat';
      break;
    case '3':
      healthStatus = 'Dead';
      break;
    case '4':
      healthStatus = 'Over Voltage';
      break;
    case '5':
      healthStatus = 'Unspecified Failure';
      break;
    case '6':
      healthStatus = 'Cold';
      break;
    default:
      healthStatus = 'Unknown';
  }

  // Convert charging status into human-readable format
  String chargingStatus;
  switch (batteryStats['status']) {
    case '1':
      chargingStatus = 'Charging';
      break;
    case '2':
      chargingStatus = 'Discharging';
      break;
    case '3':
      chargingStatus = 'Not charging';
      break;
    case '4':
      chargingStatus = 'Full';
      break;
    case '5':
      chargingStatus = 'Charging (completed)';
      break;
    default:
      chargingStatus = 'Unknown';
  }
  Map<String,String> batteryInfo = {
    'level': batteryStats['level'] ?? 'Unknown',
    'status': chargingStatus,
    'health': healthStatus,
    'temperature': batteryStats['temperature'] != null ? '${int.parse(batteryStats['temperature']!) / 10}°C' : 'Unknown',
    'voltage': batteryStats['voltage'] != null ? '${int.parse(batteryStats['voltage']!)} mV' : 'Unknown',
    'technology': batteryStats['technology'] ?? 'Unknown',
  };
  
  return batteryInfo.toString();
}



  // String _formatCameraInfo(String raw) {
  //   return raw.replaceAll('feature:', '')
  //            .replaceAll('android.hardware.camera', 'Camera:')
  //            .trim();
  // }

  static String _formatDisplayInfo(String raw) {
  // Extract the relevant details using regex or string manipulation.
  RegExp resolutionPattern = RegExp(r'\d+ x \d+'); 
  RegExp densityPattern = RegExp(r'density (\d+)'); 
  RegExp refreshRatePattern = RegExp(r'renderFrameRate ([\d.]+)');
  RegExp supportedFpsPattern = RegExp(r'fps=([\d.]+), alternativeRefreshRates=\[([\d.]+)\]');
  RegExp hdrPattern = RegExp(r'supportedHdrTypes=\[([\d, ]+)\]');
  RegExp brightnessPattern = RegExp(r'brightnessMinimum ([\d.]+), brightnessMaximum ([\d.]+), brightnessDefault ([\d.]+)');
  RegExp roundedCornersPattern = RegExp(r'RoundedCorner\{position=TopLeft, radius=(\d+)');

  String resolution = resolutionPattern.firstMatch(raw)?.group(0) ?? 'Unknown';
  String density = densityPattern.firstMatch(raw)?.group(1) ?? 'Unknown';
  String renderFrameRate = refreshRatePattern.firstMatch(raw)?.group(1) ?? 'Unknown';
  String fps = supportedFpsPattern.firstMatch(raw)?.group(1) ?? 'Unknown';
  String alternativeFps = supportedFpsPattern.firstMatch(raw)?.group(2) ?? 'Unknown';
  String hdrCapabilities = hdrPattern.firstMatch(raw)?.group(1) ?? 'Unknown';
  String brightnessMin = brightnessPattern.firstMatch(raw)?.group(1) ?? 'Unknown';
  String brightnessMax = brightnessPattern.firstMatch(raw)?.group(2) ?? 'Unknown';
  String brightnessDefault = brightnessPattern.firstMatch(raw)?.group(3) ?? 'Unknown';
  String roundedCorners = roundedCornersPattern.firstMatch(raw)?.group(1) ?? 'Unknown';

  // Calculate the aspect ratio based on resolution
  List<String> resolutionParts = resolution.split('x');
  String aspectRatio = (int.parse(resolutionParts[0]) / int.parse(resolutionParts[1])).toStringAsFixed(2) ;

  Map<String,String> displayInfo = {
    'resolution': resolution,
    'density': density,
    'aspectRatio': aspectRatio,
    'renderFrameRate': renderFrameRate,
    'fps': fps,
    'alternativeFps': alternativeFps,
    'hdrCapabilities': hdrCapabilities,
    'brightnessMin': brightnessMin,
    'brightnessMax': brightnessMax,
    'brightnessDefault': brightnessDefault,
    'roundedCorners': roundedCorners,
  };

  return displayInfo.toString();
}



  // String _formatStorageInfo(String raw) {
  //   List<String> lines = raw.split('\n');
  //   return lines.length > 1 ? lines[1] : 'Unknown';
  // }

  static String _formatGpuInfo(String raw) {
    List<String> parts = raw.trim().split('\n');
    return '''
Vulkan: ${parts.isNotEmpty ? parts[0] : 'Unknown'}
OpenGL ES: ${parts.length > 1 ? parts[1] : 'Unknown'}
''';
  }

  static String _formatSensorsInfo(String raw) {
    List<String> sensorNames = [];
    
    // Process each line
    for (String line in raw.split('\n')) {
      // Look for lines containing sensor names
      if (line.contains(')')) {
        // Extract the sensor name
        try {
          String name = line.split(')')[1];  // Get part after )
          name = name.split('|')[0];         // Get part before first |
          name = name.trim();                // Remove extra spaces
          
          if (name.isNotEmpty) {
            sensorNames.add(name);
          }
        } catch (e) {
          continue;  // Skip malformed lines
        }
      }
    }
    
    // Join all sensor names with newlines
    return sensorNames.join('\n');
  }
}