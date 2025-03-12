import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/model/subs_shared_pref.dart';
import 'package:warehouse_phase_1/src/helpers/iphone_device_info.dart';
import 'package:warehouse_phase_1/src/helpers/sql_helper.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/device_manage.dart';
//import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/iphone_device_physical_info.dart';
/// The ILogcat class provides methods to manage and monitor logcat processes for iOS devices.
/// It includes functionalities to start, stop, and monitor logcat processes, handle log data,
/// and manage device progress and test results.
class ILogcat {
  static final Map<String, StreamController<int>> _progressControllers = {};
 final DeviceInfoManager _deviceInfoManager = DeviceInfoManager();

  static final Map<String, StreamController<String>> _testControllers = {};
  static final Map<String, String> _testProgress = {};
  static final Map<String, int> _deviceProgress = {};
  static Map<String, List<Map<String, dynamic>>> testResults = {};
  static Map<String, String> rom = {};
  static Map<String, String> network_lock = {};
  
  static Stream<int> getProgressStream(String deviceId) {
    if (!_progressControllers.containsKey(deviceId)) {
      _progressControllers[deviceId] = StreamController<int>.broadcast();
      _deviceProgress[deviceId] = 0;
    }
    return _progressControllers[deviceId]!.stream;
  }

  static Stream<String> getTestStream(String deviceId) {
    if (!_testControllers.containsKey(deviceId)) {
      _testControllers[deviceId] = StreamController<String>.broadcast();
      _testProgress[deviceId] = "";
    }
    return _testControllers[deviceId]!.stream;
  }

  static Future<void> clearDeviceLogs(String deviceId) async {
    try {
      // For iOS, we can restart the syslog service
      ProcessResult result = await Process.run(
        'killall',
        ['idevicesyslog'],
      );

      if (result.exitCode == 0) {
        print('Logs cleared successfully on device $deviceId');
        return;
      } else {
        print('Failed to clear logs: ${result.stderr}');
        return;
      }
    } catch (e) {
      print('Error occurred while clearing logs: $e');
    }
    return;
  }

  static Future<bool> presenceCheck(String deviceId) async {
    final items = await SqlHelper.getItems();
    return items.any((item) => item['sno'] == deviceId);
  }

  static Future<void> startLogCat(String deviceId, String? sno) async {
    print("Starting iOS logcat for device: $deviceId");
    
    try {
      final process = await Process.start('cmd', [
        '/c',
        'idevicesyslog',
        '-m',
        '39220iOS',
        '-u',
        deviceId
      ], mode: ProcessStartMode.normal);

      // Monitor process exit code
      process.exitCode.then((code) {
        if (code != 0) {
          throw Exception('idevicesyslog process exited with code $code');
        }
      });

      List<Map<String, dynamic>> deviceResult = [];
      String buffer = "";
      bool isStartCommandReceived = false;

      // Handle standard output stream
      await _setupStdoutListener(
        process: process,
        deviceId: deviceId,
        sno: sno,
        buffer: buffer,
        isStartCommandReceived: isStartCommandReceived,
        deviceResult: deviceResult,
      );

      // Handle error stream
      _setupStderrListener(process);
      _monitorProgress(deviceId);

    } catch (e) {
      print('Error in startLogCat: $e');
      // Clean up resources
      _cleanupResources(deviceId);
      rethrow;
    }
  }

  static Future<void> _setupStdoutListener({
    required Process process,
    required String deviceId,
    required String? sno,
    required String buffer,
    required bool isStartCommandReceived,
    required List<Map<String, dynamic>> deviceResult,
  }) async {
    StreamSubscription? stdoutSubscription;
    
    try {
      stdoutSubscription = process.stdout
          .transform(Utf8Decoder())
          .listen((data) async {
        await _processData(
          data: data,
          buffer: buffer,
          deviceId: deviceId,
          sno: sno,
          isStartCommandReceived: isStartCommandReceived,
          deviceResult: deviceResult,
        );
      });

      // Add error handler for stdout stream
      stdoutSubscription.onError((error) {
        print('Error in stdout stream: $error');
        _cleanupResources(deviceId);
      });

    } catch (e) {
      print('Error setting up stdout listener: $e');
      await stdoutSubscription?.cancel();
      throw e;
    }
  }

  static void _setupStderrListener(Process process) {
    process.stderr
        .transform(Utf8Decoder())
        .listen(
          (data) => print('Error: $data'),
          onError: (e) => print('Error in stderr stream: $e'),
        );
  }

  static Future<void> _processData({
    required String data,
    required String buffer,
    required String deviceId,
    required String? sno,
    required bool isStartCommandReceived,
    required List<Map<String, dynamic>> deviceResult,
  }) async {
    try {
      buffer += data;

      // Process start command
      if (!isStartCommandReceived && _checkStartCommand(buffer)) {
        await _handleStartCommand(deviceId);
        isStartCommandReceived = true;
        buffer = "";
        return;
      }

      // Process physical memory information
      if (await _processPhysicalMemory(buffer, deviceId)) {
        buffer = _updateBuffer(buffer, r'39220iOS@physicalMemory: (\{.*?\})');
      }

      // Process lock information
      if (await _processLockInfo(buffer, deviceId, sno)) {
        buffer = _updateBuffer(buffer, r'39220iOS@LOCKS: (\{.*?\})');
      }

      // Process retry data
      if (await _processRetryData(buffer, deviceId, sno, deviceResult)) {
        buffer = _updateBuffer(buffer, r'39220iOS@retry: (\{.*?\})');
        return;
      }

      // Process warehouse data
      await _processWarehouseData(buffer, deviceId, deviceResult);
      buffer = _updateBuffer(buffer, r'39220iOS@warehouse: (\{.*?\})');

    } catch (e) {
      print('Error processing data: $e');
      _cleanupResources(deviceId);
    }
  }

  static bool _checkStartCommand(String buffer) {
    return buffer.contains('warehouse.start') || buffer.contains('warehouse.restart');
  }

  static Future<bool> _processPhysicalMemory(String buffer, String deviceId) async {
    final physicalMemoryRegex = RegExp(r'39220iOS@physicalMemory: (\{.*?\})', dotAll: true);
    final physicalMemoryMatch = physicalMemoryRegex.firstMatch(buffer);

    if (physicalMemoryMatch != null) {
      try {
        final jsonData = jsonDecode(physicalMemoryMatch.group(1)!) as Map<String, dynamic>;
        DeviceInfoManager().setDeviceInfo(
          deviceId,
          jsonData['ram'] as int,
          jsonData['rom'] as int,
          jsonData['adminApps'] as String,
        );
        return true;
      } catch (e) {
        print("Failed to parse physical memory JSON: $e");
      }
    }
    return false;
  }

  static Future<bool> _processLockInfo(String buffer, String deviceId, String? sno) async {
    final lockRegex = RegExp(r'39220iOS@LOCKS: (\{.*?\})', dotAll: true);
    final lockMatch = lockRegex.firstMatch(buffer);

    if (lockMatch != null) {
      try {
        final jsonData = jsonDecode(lockMatch.group(1)!) as Map<String, dynamic>;
        print('isJailbreak in ilogcat : ${jsonData['isJailbreak']}');
        await PreferencesHelper.setJailBreak(sno, jsonData['isJailbreak']);
        DeviceInfoManager().setLockInfo(
          deviceId,
          jsonData['isJailbreak'],
          jsonData['oem_lock'],
          jsonData['isMdmManaged'],
        );
        return true;
      } catch (e) {
        print("Failed to parse Locks in ilogcat JSON: $e");
      }
    }
    return false;
  }

  static Future<bool> _processRetryData(
      String buffer,
      String deviceId,
      String? sno,
      List<Map<String, dynamic>> deviceResult,
    ) async {
      final retryRegex = RegExp(r'39220iOS@retry: (\{.*?\})', dotAll: true);
      final retryMatch = retryRegex.firstMatch(buffer);

      if (retryMatch != null) {
        try {
          final retryJsonString = retryMatch.group(1)!;
          final jsonData = jsonDecode(retryJsonString) as Map<String, dynamic>;
          
          // Clear existing results and add retry data
          _testProgress[deviceId] = retryJsonString;
          deviceResult.clear();
          deviceResult.add(jsonData);

          // Update progress based on new data
          int progress = (jsonData.length * 5);
          if (progress >= 85) {
            _deviceProgress[deviceId] = progress - 10;
          } else {
            _deviceProgress[deviceId] = progress;
          }

          // Update controllers
          _testControllers[deviceId]?.add(_testProgress[deviceId]!);
          _progressControllers[deviceId]?.add(_deviceProgress[deviceId]!);

          // Replace test results with new retry data
          testResults[deviceId] = deviceResult;
          print('Updated test result with retry data for iOS device: $deviceId');

          // Create updated JSON file
          await createJsonFile(deviceId, sno);

          // Mark device as unsynced
          await SqlHelper.markDeviceAsUnSynced(sno ?? deviceId);

          // Get unsynced items for verification
          List<Map<String, dynamic>> unsyncedItems = await SqlHelper.getUnsyncedItems();
          print("unsynced items after retry : $unsyncedItems");

          // Increase 1 subscription to counter for retry
          String? userId = await PreferencesHelper.getUserId();
          int currentCount =
            await SubscriptionSharedPref.getSubscription(userId ?? 'n/a') ?? 0;
          int newCount = currentCount > 0 ? currentCount + 1 : 0;
          await SubscriptionSharedPref.saveSubscription(userId ?? 'n/a', newCount);

          // Save results
          await saveResults();
          print("after retry save result api for iOS");
          int cc =
            await SubscriptionSharedPref.getSubscription(userId ?? 'n/a') ?? 0;
            print("after retry save result api for iOS $cc");
          return true;
        } catch (e) {
          print('Error processing retry data: $e');
        }
      }
      return false;
    }

  static Future<void> _monitorProgress(String deviceId) async {
    try {
      int previousProgress = _deviceProgress[deviceId] ?? 0;

      await Future.delayed(Duration(seconds: 12));

      int currentProgress = _deviceProgress[deviceId] ?? 0;

      if (currentProgress == previousProgress) {
        print('No progress detected for device $deviceId, reconnecting log monitoring...');
        
        // Terminate current log process
        await clearDeviceLogs(deviceId);

        // Restart logcat
        await Future.delayed(Duration(seconds: 2));
        await startLogCat(deviceId, null);
      } else if (currentProgress >= 100) {
        print('Progress reached 100% for device $deviceId, stopping monitoring...');
        _cleanupResources(deviceId);
      } else {
        // Continue monitoring if progress is detected
        _monitorProgress(deviceId);
      }
    } catch (e) {
      print('Error monitoring progress: $e');
    }
  }

  static Future<void> _reconnectLogCat(String deviceId) async {
    try {
      // Stop the current logcat process
      stopLogCat(deviceId);

      // Restart the logcat process
      await startLogCat(deviceId, null);
    } catch (e) {
      print('Error reconnecting logcat: $e');
    }
  }

  static Future<void> _handleStartCommand(String deviceId) async {
    try {
      await clearDeviceLogs(deviceId);
      bool val = await presenceCheck(deviceId);

      if (val) {
        await Future.wait([
          SqlHelper.deleteItemwithId(deviceId),
          deleteJsonFile(deviceId),
          DeviceProgressManager.deleteProgress(deviceId),
        ]);
      }

      _deviceProgress[deviceId] = 0;
      _progressControllers[deviceId]?.add(0);
      print('Log monitoring started for device: $deviceId');

      // Start monitoring progress
      _monitorProgress(deviceId);
    } catch (e) {
      print('Error handling start command: $e');
      throw e;
    }
  }
  static Future<void> saveResults() async {
    try {
      // Get unsynced devices
      List<Map<String, dynamic>> unSyncedDevices = List.from(await SqlHelper.getUnsyncedItems());
      print("unsynced items in internet connectivity : $unSyncedDevices");

      // Remove duplicates based on serial number
      Set<String> seenSno = {};
      unSyncedDevices = unSyncedDevices.where((device) {
        if (seenSno.contains(device['sno'])) {
          return false;
        } else {
          seenSno.add(device['sno']);
          return true;
        }
      }).toList();

      // Process each device
      for (var device in unSyncedDevices) {
        final deviceId = device['sno'] ?? '';
        if (deviceId.isEmpty) continue;

        String jsonContent = await getJsonFile(deviceId);
        
        // Prepare request body
        Map<String, String> requestBody = {
          'userName': 'whtest',
          'apiKey': '202cb962ac59075b964b07152d234b70',
          'userId': '1',
          'brand': device['manufacturer'] ?? 'N/A',
          'model': device['model'] ?? 'N/A',
          'androidVersion': device['ver'] ?? 'N/A',
          'serialNumber': deviceId,
          'IMEINumber': device['iemi'] ?? 'N/A',
          'mdmStatus': device['mdm_status'] ?? 'N/A',
          'ram': device['ram'] ?? 'N/A',
          'rom': device['rom_gb'] ?? 'N/A',
          'oem': device['oem'] ?? 'N/A',
          'diagnosisJson': jsonContent,
          'simLock': device['carrier_lock_status'] ?? 'N/A',
          'adminApp': 'N/A',
        };

        // Send request
        final response = await http.post(
          Uri.parse('https://sbox.getinstacash.in/ic-web/warehouse/v1/public/saveReport'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: Uri.encodeFull(requestBody.entries.map((e) => 
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')),
        );

        if (response.statusCode == 200) {
          var responseData = jsonDecode(response.body);
          if (responseData['status'] == true) {
            print('POST request successful for device $deviceId: ${responseData['diagnoseId']}');
            await SqlHelper.markDeviceAsSynced(deviceId);
          } else {
            print('Failed to sync device $deviceId: ${responseData['msg']}');
          }
        } else {
          print('Failed to send POST request for device $deviceId. Status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error syncing devices: $e');
    }
  }


static Future<void> _processWarehouseData(
  String buffer,
  String deviceId,
  List<Map<String, dynamic>> deviceResult,
) async {
  final regex = RegExp(r'39220iOS@warehouse: (\{.*?\})', dotAll: true);
  final matches = regex.allMatches(buffer);

  for (final match in matches) {
    try {
      final jsonData = jsonDecode(match.group(1)!) as Map<String, dynamic>;
      
      _testProgress[deviceId] = match.group(1)!;
      deviceResult.add(jsonData);
      
      // Calculate and update progress
      int progress = _calculateProgress(jsonData);
      _updateProgress(deviceId, progress);
      
      // Update controllers
      _updateControllers(deviceId);
      
    } catch (e) {
      print("Failed to parse warehouse JSON: $e");
    }
  }
  
  testResults[deviceId] = deviceResult;
}

static int _calculateProgress(Map<String, dynamic> jsonData) {
  int progress = jsonData.length * 5;
  return (progress >= 85) ? progress - 10 : progress;
}

static void _updateProgress(String deviceId, int progress) {
  _deviceProgress[deviceId] = progress;
  print("progress of ios ${_deviceProgress[deviceId]}");
}

static void _updateControllers(String deviceId) {
  _testControllers[deviceId]?.add(_testProgress[deviceId]!);
  _progressControllers[deviceId]?.add(_deviceProgress[deviceId]!);
}

static String _updateBuffer(String buffer, String pattern) {
  final regex = RegExp(pattern, dotAll: true);
  final match = regex.firstMatch(buffer);
  return match != null ? buffer.substring(match.end) : buffer;
}

static void _cleanupResources(String deviceId) {
  _progressControllers[deviceId]?.close();
  _testControllers[deviceId]?.close();
  _progressControllers.remove(deviceId);
  _testControllers.remove(deviceId);
  _deviceProgress.remove(deviceId);
  _testProgress.remove(deviceId);
}

  static Future<void> fetchDiagnosisAndUpdateFile(String userId, String deviceId) async {
    try {
      final url = Uri.parse('https://sbox.getinstacash.in/ic-web/warehouse/v1/public/getDData');
      final response = await http.post(
        url,
        body: {
          'userName': 'whtest',
          'apiKey': '202cb962ac59075b964b07152d234b70',
          'userId': userId,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> devices = data['msg'];
        
        for (var device in devices) {
          if (device['serialNumber'] == deviceId) {
            List<dynamic> diagnosisList = json.decode(device['diagnosisJson']);
            testResults[deviceId] = diagnosisList.cast<Map<String, dynamic>>();
            //await createJsonFile(deviceId);
            print('File created/updated successfully for device: $deviceId');
          }
        }
      } else {
        print('Failed to load data');
      }
    } catch (e) {
      print('Error fetching diagnosis and updating file: $e');
    }
  }

  static Future<void> createJsonFile(String? deviceId,String ?sno) async {
  try {
    if (deviceId == null) {
      print('Device ID is null');
      return;
    }

    if (testResults.containsKey(deviceId)) {
      // Sanitize the device ID for use in filename
      print("test results in create json file : $testResults");
      final String sanitizedDeviceId = deviceId
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') // Replace invalid characters
          .replaceAll(RegExp(r'\s+'), '_');         // Replace whitespace
      
      final String fileName = 'logcat_results_$sno.json';
      final File file = File(fileName);
      Map<String, dynamic> existingData = {};

      try {
        if (await file.exists()) {
          final String existingContent = await file.readAsString();
          if (existingContent.isNotEmpty) {
            try {
              List<dynamic> existingJsonList = jsonDecode(existingContent);
              for (var item in existingJsonList) {
                item.forEach((key, value) {
                  existingData[key] = value;
                });
              }
            } catch (e) {
              print('Error parsing existing JSON content: $e');
              // Continue with empty existingData if parsing fails
            }
          }
        }

        final List<Map<String, dynamic>> newResults = testResults[deviceId]!;
        for (var result in newResults) {
          result.forEach((key, value) {
            existingData[key] = value;
          });
        }

        List<Map<String, dynamic>> finalData = existingData.entries.map((entry) {
          return {entry.key: entry.value};
        }).toList();

        await file.writeAsString(
          jsonEncode(finalData),
          mode: FileMode.write,
        );
        print('JSON file updated successfully: $fileName');
      } catch (e) {
        print('Error handling file operations: $e');
        rethrow;
      }
    } else {
      print('No test results found for device ID: $deviceId');
    }
  } catch (e) {
    print('Error creating/updating JSON file: $e');
    rethrow; // Rethrow to allow caller to handle the error if needed
  }
}

  static Future<String> getJsonFile(String? deviceId) async {
    try {
      final String fileName = 'logcat_results_$deviceId.json';
      final File file = File(fileName);

      if (await file.exists()) {
        final String content = await file.readAsString();
        print('JSON file read successfully: $fileName');
        return content;
      } else {
        print('JSON file not found: $fileName');
        return '';
      }
    } catch (e) {
      print('Error reading JSON file: $e');
      return '';
    }
  }

  static Future<void> deleteJsonFile(String? deviceId) async {
    try {
      final String fileName = 'logcat_results_$deviceId.json';
      final File file = File(fileName);

      if (await file.exists()) {
        await file.delete();
        print('JSON file deleted: $fileName');
      } else {
        print('JSON file not found: $fileName');
      }
    } catch (e) {
      print('Error deleting JSON file: $e');
    }
  }

  static Future<void> deleteAllJsonFiles() async {
    try {
      final directory = Directory.current;
      final List<FileSystemEntity> files = directory.listSync();

      for (var file in files) {
        if (file is File && file.path.endsWith('.json') && file.path.contains('logcat_results_')) {
          await file.delete();
          print('Deleted file: ${file.path}');
        }
      }

      print('All matching JSON files deleted successfully.');
    } catch (e) {
      print('Error deleting all JSON files: $e');
    }
  }

  static void stopLogCat(String? deviceId) {
    if (deviceId == null) return;

    print("removed device id in log $deviceId");
    _progressControllers[deviceId]?.close();
    _progressControllers.remove(deviceId);
  }
}