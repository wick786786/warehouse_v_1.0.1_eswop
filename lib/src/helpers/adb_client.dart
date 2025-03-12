import 'dart:async';
import 'dart:convert';
import 'dart:io';

class AdbClient {
  Future<List<String>> listDevices() async {
    ProcessResult result = await Process.run('adb', ['devices']);
    if (result.exitCode != 0) {
      return [];
    }

    List<String> lines = LineSplitter.split(result.stdout.toString()).toList();
    lines.removeAt(0); // Remove the first line 'List of devices attached'

    List<String> devices = [];
    for (String line in lines) {
      if (line.trim().isEmpty) {
        continue;
      }
      devices.add(line.split('\t')[0]);
    }
    return devices;
  }
  Future<String> getApproximateRom(String deviceId) async {
    final storageInfo = await executeShellCommand(deviceId, 'df -h | grep /data');
    if (storageInfo.isEmpty) {
      return 'Unknown';
    }
  
    final sizeParts = storageInfo.split(RegExp(r'\s+'));
    if (sizeParts.length < 4) {
      return 'Unknown';
    }

    final totalSizeStr = sizeParts[1].replaceAll(RegExp(r'[A-Za-z]'), '');
    final totalSizeGB = _parseSizeToGB(totalSizeStr, sizeParts[1]);

    final formattedSize = _formatSizeInGB(totalSizeGB);

    return '$formattedSize GB';
  }

  double _parseSizeToGB(String size, String sizeWithUnit) {
    final unit = sizeWithUnit.replaceAll(RegExp(r'[0-9]'), '');
    final value = double.tryParse(size) ?? 0.0;
  
    switch (unit) {
      case 'T':
        return value * 1024; // Terabytes to GB
      case 'G':
        return value; // Gigabytes
      case 'M':
        return value / 1024; // Megabytes to GB
      case 'K':
        return value / (1024 * 1024); // Kilobytes to GB
      default:
        return value; // Assume GB if unit is not specified
    }
  }
  // -------  credits to ajay sir -------------------------
  Future<String?> getImei(String deviceId) async {
    try {
      // Construct the ADB command with the specific device ID
      final Process process = await Process.start(
        'adb',
        [
          '-s', 
          deviceId, 
          'shell', 
          'service call iphonesubinfo 1 s16 com.android.shell'
        ],
        runInShell: Platform.isWindows
      );

      // Capture the output
      final output = await process.stdout
          .transform(const SystemEncoding().decoder)
          .join();

      // Process the output to extract the relevant information
      final RegExp regex = RegExp(r"'(.*?)'");
      final matches = regex.allMatches(output);

      if (matches.isNotEmpty) {
        // Combine and clean the matched groups
        String processedOutput = matches
            .map((match) => match.group(1))
            .where((m) => m != null)
            .join('')
            .replaceAll('.', '')
            .replaceAll(' ', '');

        return processedOutput;
      }

      return null;
    } catch (e) {
      // Log or handle any errors during command execution
      print('Error retrieving device info: $e');
      return null;
    }
  }



  // Implementing the formatSize logic in Dart
  int _formatSizeInGB(double size) {
    int totalSize = size.round(); // Converting double size to an integer value in GB
    
    // Logic to approximate the size based on standard values
    if (totalSize == 0) {
      totalSize = 0;
    } else if (totalSize <= 4) {
      totalSize = 4;
    } else if (totalSize <= 8) {
      totalSize = 8;
    } else if (totalSize <= 16) {
      totalSize = 16;
    } else if (totalSize <= 32) {
      totalSize = 32;
    } else if (totalSize <= 64) {
      totalSize = 64;
    } else if (totalSize <= 128) {
      totalSize = 128;
    } else if (totalSize <= 256) {
      totalSize = 256;
    } else if (totalSize <= 512) {
      totalSize = 512;
    } else if (totalSize <= 1024) {
      totalSize = 1024;
    }

    return totalSize;
  }

  Future<void> requestPermissions(String deviceId) async {
    // Implement the method to request necessary permissions
    // Example implementation:
    await Process.run('adb', ['-s', deviceId, 'shell', 'pm', 'grant', 'com.getinstacash.warehouse', 'android.permission.READ_EXTERNAL_STORAGE']);
    await Process.run('adb', ['-s', deviceId, 'shell', 'pm', 'grant', 'com.getinstacash.warehouse', 'android.permission.WRITE_EXTERNAL_STORAGE']);
  }

  Future<String> executeShellCommand(String deviceId, String command) async {
    ProcessResult result = await Process.run('adb', ['-s', deviceId, 'shell', command]);
    if (result.exitCode != 0) {
      return '';
    }
    return result.stdout.toString().trim();
  }






// Example usage


  Future<Map<String, String>> getDeviceDetails(String deviceId) async {
    final model = await executeShellCommand(deviceId, 'getprop ro.product.model');
    final manufacturer = await executeShellCommand(deviceId, 'getprop ro.product.manufacturer');
    final androidVersion = await executeShellCommand(deviceId, 'getprop ro.build.version.release');
    final serialNumber = await executeShellCommand(deviceId, 'getprop ro.serialno');
    final imeiOutput = await getImei(deviceId);
    
    final mdmStatus=await checkMdmStatus(deviceId);
    final batterylevel=await executeShellCommand(deviceId, 'dumpsys battery | grep level');
    final ram = await getApproximateRam(deviceId);
    final rom = await getApproximateRom(deviceId);
    final oem=await executeShellCommand(deviceId, 'getprop sys.oem_unlock_allowed');
    final carrier_status=await executeShellCommand(deviceId, 'getprop ro.carrier')=='locked'?'locked':'unlocked';
    print('carrier status :$carrier_status');

    /*
    final rom=await getROM();
    final network_lock=await get networkLock();


    */
    return {
      'model': model,
      'manufacturer': manufacturer,
      'androidVersion': androidVersion,
      'serialNumber': serialNumber,
      'imeiOutput': imeiOutput??'n/a',
      'mdm_status': mdmStatus,
      'batterylevel': batterylevel,
      'ram': ram,
      'rom': rom,
      'oem':oem,
      'carrier_lock':carrier_status
    };
  }

  Future<bool> checkDeviceOwner(String deviceId) async {
    final owner = await executeShellCommand(deviceId, 'dpm list-owners | grep "Device Owner"');
    if (owner.isNotEmpty) {
      print("Device Owner: Found");
      return true;
    } else {
      print("Device Owner: Not Found");
      return false;
    }
  }

  Future<bool> checkActiveAdmins(String deviceId) async {
    final admins = await executeShellCommand(deviceId, 'dumpsys device_policy | grep "Active admin"');
    if (admins.isNotEmpty) {
      print("Active Admins: Found");
      return true;
    } else {
      print("Active Admins: Not Found");
      return false;
    }
  }

  Future<bool> checkManagedProfiles(String deviceId) async {
    final profiles = await executeShellCommand(deviceId, 'pm list packages -e');
    if (profiles.isNotEmpty) {
      print("Managed Profiles: Found");
      return true;
    } else {
      print("Managed Profiles: Not Found");
      return false;
    }
  }

  Future<String> checkMdmStatus(String deviceId) async {
    print("Checking MDM Status...");

    final deviceOwnerStatus = await checkDeviceOwner(deviceId);
    final activeAdminsStatus = await checkActiveAdmins(deviceId);
    final managedProfilesStatus = await checkManagedProfiles(deviceId);

    if (deviceOwnerStatus || activeAdminsStatus || managedProfilesStatus) {
      return "true";
    } else {
      return "false";
    }
  }

  Future<String> getApproximateRam(String deviceId) async {
    final memInfo = await executeShellCommand(deviceId, 'cat /proc/meminfo | grep MemTotal');
    if (memInfo.isEmpty) {
      return 'Unknown';
    }
    final memTotalKb = int.tryParse(memInfo.split(RegExp(r'\s+'))[1] ?? '0') ?? 0;
    final memTotalGb = (memTotalKb / (1024 * 1024)).toStringAsFixed(2);
    final approximateRam = _roundToStandardSize(double.parse(memTotalGb));
    return '$approximateRam GB';
  }

//   Future<String> getApproximateRom(String deviceId) async {
//   final storageInfo = await executeShellCommand(deviceId, 'df -h | grep /data');
//   if ((storageInfo).isEmpty) {
//     return 'Unknown';
//   }
  
//   final sizeParts = storageInfo.split(RegExp(r'\s+'));
//   if (sizeParts.length < 4) {
//     return 'Unknown';
//   }

//   final totalSizeStr = sizeParts[1].replaceAll(RegExp(r'[A-Za-z]'), '');
//   final usedSizeStr = sizeParts[2].replaceAll(RegExp(r'[A-Za-z]'), '');
//   final availableSizeStr = sizeParts[3].replaceAll(RegExp(r'[A-Za-z]'), '');

//   final totalSizeGB = _parseSizeToGB(totalSizeStr, sizeParts[1]);
//   final usedSizeGB = _parseSizeToGB(usedSizeStr, sizeParts[2]);
//   final availableSizeGB = _parseSizeToGB(availableSizeStr, sizeParts[3]);

//   final combinedSizeGB = totalSizeGB + usedSizeGB + availableSizeGB;

//   return _approximateSize(combinedSizeGB);
// }

// double _parseSizeToGB(String size, String sizeWithUnit) {
//   final unit = sizeWithUnit.replaceAll(RegExp(r'[0-9]'), '');
//   final value = double.tryParse(size) ?? 0.0;
  
//   switch (unit) {
//     case 'T':
//       return value * 1024; // Terabytes to GB
//     case 'G':
//       return value; // Gigabytes
//     case 'M':
//       return value / 1024; // Megabytes to GB
//     case 'K':
//       return value / (1024 * 1024); // Kilobytes to GB
//     default:
//       return value; // Assume GB if unit is not specified
//   }
// }

String _approximateSize(double sizeGB) {
  const sizes = [32, 64, 128, 256, 512, 1024]; // Sizes in GB
  for (var standardSize in sizes) {
    if (sizeGB <= standardSize) {
      return '${standardSize}GB';
    }
  }
  return '> ${sizes.last}GB'; // For sizes larger than the largest standard size
}

  double _roundToStandardSize(double sizeInGb) {
    const standardSizes = [2, 3, 4, 6, 8, 12, 16, 32, 64, 128, 256, 512, 1024];
    for (var size in standardSizes) {
      if (sizeInGb <= size) {
        return size.toDouble();
      }
    }
    return sizeInGb;
  }
}
