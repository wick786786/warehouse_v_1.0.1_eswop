import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:warehouse_phase_1/presentation/DeviceCard/icard/saveresultIphone.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/model/globels.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/home_page.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/model/subs_shared_pref.dart';
import 'package:warehouse_phase_1/src/helpers/iphone_device_info.dart';
import 'package:warehouse_phase_1/src/helpers/sql_helper.dart';

class SyncResult {
  Process? _process;
  bool _isProcessing = false;
  final Map<String, String> _testProgress = {};
  final Map<String, int> _deviceProgress = {};
  final Map<String, List<Map<String, dynamic>>> testResults = {};
  String? _errorSegment;
  MyHomePage homePage=MyHomePage(
              title: 'Warehouse Application',
             // onLocaleChange: _setLocale,
              onThemeToggle: () {},);

  String? get errorSegment => _errorSegment;

  Future<bool> syncResult(String udid) async {
    if (_isProcessing) {
      await killExistingProcess();
    }

    try {
      _isProcessing = true;
      _errorSegment = null;
      bool physicalMemoryProcessed = false;
      bool locksProcessed = false;
      bool warehouseProcessed = false;
      
      List<Map<String, dynamic>> deviceResult = [];
      String buffer = '';

      await _killExistingIdevicesyslog();

      _process = await Process.start('cmd', [
        '/c',
        'idevicesyslog',
        '-m',
        '39220iOS',
        '-u',
        udid,
      ], mode: ProcessStartMode.normal);

      DateTime startTime = DateTime.now();
      
      await for (final data in _process!.stdout.transform(SystemEncoding().decoder)) {
        print('Syncing result: $data');
        buffer += data;

        // Process Physical Memory
        if (!physicalMemoryProcessed) {
          physicalMemoryProcessed = await _processPhysicalMemory(buffer, udid);
          if (!physicalMemoryProcessed && buffer.contains('39220iOS@physicalMemory:')) {
            _errorSegment = 'Failed to process Physical Memory data';
          }
        }

        // Process Locks
        if (!locksProcessed) {
          locksProcessed = await _processLockInfo(buffer, udid, udid);
          if (!locksProcessed && buffer.contains('39220iOS@LOCKS:')) {
            _errorSegment = 'Failed to process Locks data';
          }
        }

        // Process Warehouse Data
        if (!warehouseProcessed && buffer.contains('39220iOS@warehouse:')) {
          await _processWarehouseData(buffer, udid, deviceResult);
          warehouseProcessed = deviceResult.isNotEmpty;
          if (!warehouseProcessed) {
            _errorSegment = 'Failed to process Warehouse data';
          }
        }

        // Process Retry Data if present
        if (buffer.contains('39220iOS@retry:')) {
          bool retryProcessed = await _processRetryData(buffer, udid, udid, deviceResult);
          if (!retryProcessed) {
            _errorSegment = 'Failed to process Retry data';
          }
        }

        // Check if all required data is processed
        if (physicalMemoryProcessed && locksProcessed && warehouseProcessed) {
          print('All required data processed successfully');
         await  IOSDeviceService().saveResultsIphone(udid, connectedIosDevices);

          await saveResults();
          break;
        }

        // Check timeout
        if (DateTime.now().difference(startTime).inSeconds > 30) {
          _errorSegment = 'Timeout: Failed to receive all required data within 30 seconds';
          break;
        }
      }

      await killExistingProcess();
      
      // Only proceed with saving if all data was processed successfully
      if (physicalMemoryProcessed && locksProcessed && warehouseProcessed) {
        try {
          await saveResults();
          return true;
        } catch (e) {
          _errorSegment = 'Error saving results: $e';
          return false;
        }
      }
      
      return false;
    } catch (e) {
      _errorSegment = 'Process error: $e';
      return false;
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _processPhysicalMemory(String buffer, String deviceId) async {
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
        return false;
      }
    }
    return false;
  }

  Future<bool> _processLockInfo(String buffer, String deviceId, String? sno) async {
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
        return false;
      }
    }
    return false;
  }

  Future<void> _processWarehouseData(
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
        int progress = (deviceResult.length * 5);
        if (progress >= 85) {
          _deviceProgress[deviceId] = progress - 10;
        } else {
          _deviceProgress[deviceId] = progress;
        }
      } catch (e) {
        print("Failed to parse warehouse JSON: $e");
      }
    }
    print('device result in syncRESULT : $deviceResult');
    testResults[deviceId] = deviceResult;
    print('test result in syncRESULT in processwarehouse : $testResults');
    await createJsonFile(deviceId, connectedIosDevices[deviceId]?['serialNumber']);
  }

  Future<bool> _processRetryData(
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
        
        _testProgress[deviceId] = retryJsonString;
        deviceResult.clear();
        deviceResult.add(jsonData);

        int progress = (jsonData.length * 5);
        _deviceProgress[deviceId] = progress >= 85 ? progress - 10 : progress;

        testResults[deviceId] = deviceResult;

        // Create updated JSON file and mark device as unsynced
        await createJsonFile(deviceId, sno);
        await SqlHelper.markDeviceAsUnSynced(sno ?? deviceId);

        // Handle subscription count
        String? userId = await PreferencesHelper.getUserId();
        int currentCount = await SubscriptionSharedPref.getSubscription(userId ?? 'n/a') ?? 0;
        await SubscriptionSharedPref.saveSubscription(userId ?? 'n/a', currentCount + 1);

        return true;
      } catch (e) {
        print('Error processing retry data: $e');
        return false;
      }
    }
    return false;
  }

  Future<void> _killExistingIdevicesyslog() async {
    if (Platform.isWindows) {
      await Process.run('taskkill', ['/F', '/IM', 'idevicesyslog.exe']);
    } else {
      await Process.run('pkill', ['-f', 'idevicesyslog']);
    }
  }

  Future<void> killExistingProcess() async {
    try {
      if (_process != null) {
        _process!.kill(ProcessSignal.sigterm);
        await _process!.exitCode.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            _process!.kill(ProcessSignal.sigkill);
            return -1;
          },
        );
        _process = null;
      }
      
      await _killExistingIdevicesyslog();
    } catch (e) {
      print('Error killing process: $e');
    }
  }

  static Future<void> saveResults() async {
    try {
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

      for (var device in unSyncedDevices) {
        final deviceId = device['sno'] ?? '';
        if (deviceId.isEmpty) continue;

        String jsonContent = await getJsonFile(deviceId);
        
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
            throw Exception('Failed to sync device $deviceId: ${responseData['msg']}');
          }
        } else {
          throw Exception('Failed to send POST request for device $deviceId. Status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error syncing devices: $e');
      throw e;
    }
  }
  Future<void> createJsonFile(String? deviceId,String ?sno) async {
  try {
    if (deviceId == null) {
      print('Device ID is null');
      return;
    }
       print('test result in SYncResult  : $testResults');
    if (testResults.containsKey(deviceId)) {
      // Sanitize the device ID for use in filename
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

  Future<void> dispose() async {
    await killExistingProcess();
  }
}