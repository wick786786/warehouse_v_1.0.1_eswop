import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:warehouse_phase_1/GlobalVariables/singelton_class.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/device_manage.dart';
import 'package:warehouse_phase_1/service_class/current_internet_status.dart';
import 'package:warehouse_phase_1/src/helpers/sql_helper.dart';

class LogCat {
  static final Map<String, StreamController<int>> _progressControllers = {};
  static final Map<String, StreamController<String>> _testControllers = {};
  static final Map<String, String> _testProgress = {};
  static final Map<String, int> _deviceProgress =
      {}; // Track progress values separately
  // static bool device_check=false;
  static Map<String, List<Map<String, dynamic>>> testResults = {};
  // static final Map<String, StreamController<void>> _restartControllers =
  //     {}; // For restart events
  static Map<String, String> rom = {};
  static Map<String, String> network_lock = {};
  static final internetStatuschecker = InternetStatusChecker();
  static final int progressLength=GlobalUser().progressLength??3;
  static Stream<int> getProgressStream(String deviceId) {
    if (!_progressControllers.containsKey(deviceId)) {
      _progressControllers[deviceId] = StreamController<int>.broadcast();
      _deviceProgress[deviceId] = 0; // Initialize progress
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
      // Run the adb command to clear the logs
      ProcessResult result = await Process.run(
        'adb',
        ['-s', deviceId, 'logcat', '-c'],
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

  // static Stream<void> getRestartStream(String deviceId) {
  //   if (!_restartControllers.containsKey(deviceId)) {
  //     _restartControllers[deviceId] = StreamController<void>.broadcast();
  //   }
  //   return _restartControllers[deviceId]!.stream;
  // }
  static Future<bool> presenceCheck(String deviceId) async {
    final items = await SqlHelper.getItems();

    return items.any((item) => item['sno'] == deviceId);
    //print("is device present: $_isDevicePresent");
    //return device_check;
  }
   static Future<void> broadcasttestProfile(String deviceId) async {
    try {
      String? testProfile = GlobalUser().testProfile;
      if (testProfile == null || testProfile.isEmpty) {
        print('No test profile response available.');
        return;
      }

      ProcessResult result = await Process.run(
        'adb',
        [
          '-s',
          deviceId,
          'shell',
          'am',
          'broadcast',
          '-a',
          'com.getinstacash.warehouse.ACTION',
          '-n',
          'com.getinstacash.warehouse/.utils.receiver.MyReceiver',
          '--es',
          'test',
          "'$testProfile'"
        ],
      );
         print('Broadcast outside test sent to device IN LOGCAT $testProfile');
      if (result.exitCode == 0) {
        print('Broadcast sent successfully to device in launch app $deviceId');
        print('Broadcast sent to device IN LAUNCH APP $testProfile');
      } else {
        print('Failed to send broadcast: ${result.stderr}');
      }
    } catch (e) {
      print('Error occurred while sending broadcast: $e');
    }
  }


  static Future<void> broadcastPhysicalQuestion(String deviceId) async {
    try {
      String? physicalQuestionResponse = GlobalUser().physicalQuestionResponse;
      if (physicalQuestionResponse == null || physicalQuestionResponse.isEmpty) {
        print('No physical question response available.');
        return;
      }

      ProcessResult result = await Process.run(
        'adb',
        [
          '-s',
          deviceId,
          'shell',
          'am',
          'broadcast',
          '-a',
          'com.getinstacash.warehouse.ACTION',
          '-n',
          'com.getinstacash.warehouse/.utils.receiver.MyReceiver',
          '--es',
          'physical_question',
          "'$physicalQuestionResponse'"
        ],
      );
       print('Broadcast outside  sent to device IN LOGCAT $physicalQuestionResponse');
      if (result.exitCode == 0) {
        print('Broadcast sent successfully to device $deviceId');
        print('Broadcast sent to device IN LOGCAT $physicalQuestionResponse');
      } else {
        print('Failed to send broadcast: ${result.stderr}');
      }
    } catch (e) {
      print('Error occurred while sending broadcast: $e');
    }
  }

  static void startLogCat(String deviceId) {
    print('debug:logcat $deviceId');
    Process.start(
      'adb',
      ['-s', deviceId, 'logcat'],
      mode: ProcessStartMode.normal,
    ).then((process) {
      List<Map<String, dynamic>> deviceResult = [];
      Map<String, dynamic> jsonData = {};
      bool restart = false;
      String jsonString = "";
      process.stdout.transform(Utf8Decoder()).listen((data) async {
        if (data.contains('warehouse.launch')) {
          print('launch  count');
          if (!_testProgress.containsKey(deviceId) || _testProgress[deviceId] != 'launch_sent') {
            print('launch read from logs');
            if(GlobalUser().testProfile == null)
            {
              print('test profile is null');
            }
            if(GlobalUser().physicalQuestionResponse == null)
            {
                 print('physical question profile is null');
            }
            if (GlobalUser().testProfile != null && GlobalUser().testProfile!.isNotEmpty) {
              print('test profile sending :${GlobalUser().testProfile}');
              await broadcasttestProfile(deviceId);
            }
            if (GlobalUser().physicalQuestionResponse != null && GlobalUser().physicalQuestionResponse!.isNotEmpty) {
              print('physical question sending :${GlobalUser().physicalQuestionResponse}');
              await broadcastPhysicalQuestion(deviceId);
            }
            _testProgress[deviceId] = 'launch_sent'; // Mark as sent
          }
        }
        
        if (data.contains('warehouse.start') ||
            data.contains('warehouse.restart')) {
          await clearDeviceLogs(deviceId);
          bool val = await presenceCheck(deviceId);
          if (val == true) {
            await SqlHelper.deleteItemwithId(deviceId);
            await deleteJsonFile(deviceId);
            await DeviceProgressManager.deleteProgress(deviceId);
          }

          _deviceProgress[deviceId] = 0;
          _progressControllers[deviceId]?.add(0);
          print('start');
         // await broadcastPhysicalQuestion(deviceId); // Call the broadcast function
        }

        // Check for main JSON log pattern
        final regex = RegExp(r'1723263045@warehouse: ({.*})');
        final match = regex.firstMatch(data);

        // Check for retry log pattern
        final retryRegex = RegExp(r'1723263045@retry: ({.*})');
        final retryMatch = retryRegex.firstMatch(data);

        // Check for physical log pattern
        final physicalRegex = RegExp(r'1723263045@physical: ({.*})');
        final physicalMatch = physicalRegex.firstMatch(data);

        if (retryMatch != null) {
          // Handle retry JSON data and replace current results
          final retryJsonString = retryMatch.group(1)!;
          jsonData = jsonDecode(retryJsonString);
          _testProgress[deviceId] = retryJsonString;
          deviceResult.clear();
          deviceResult.add(jsonData);

          // Update progress based on new data
          if ((jsonData.length * progressLength) >= 85) {
            _deviceProgress[deviceId] = (jsonData.length * progressLength) - 15;
          } else {
            _deviceProgress[deviceId] = (jsonData.length * progressLength);
          }
          _testControllers[deviceId]?.add(_testProgress[deviceId]!);
          _progressControllers[deviceId]?.add(_deviceProgress[deviceId]!);

          // Replace test results with new retry data
          testResults[deviceId] = deviceResult;
          print('Updated test result with retry data for device: $deviceId');

          // Creating updated jsonFile
          await LogCat.createJsonFile(deviceId);

          // Marking the updated device as unsynced
          await SqlHelper.markDeviceAsUnSynced(deviceId);

          List<Map<String, dynamic>> unsyncedItems = await SqlHelper.getUnsyncedItems();

          print("unsynced items after retry : ${unsyncedItems}");

          await saveResults();

          print("after retry save result api");
        } else if (match != null) {
          // Handle main JSON log data
          final jsonString = match.group(1)!;
          jsonData = jsonDecode(jsonString);
          _testProgress[deviceId] = jsonString;
          deviceResult.add(jsonData);

          if ((jsonData.length) * progressLength >= 85) {
            _deviceProgress[deviceId] = (jsonData.length * progressLength) - 20;
          } else {
            _deviceProgress[deviceId] = (jsonData.length * progressLength);
          }
          //await broadcastPhysicalQuestion(deviceId); // Call the broadcast function
          _progressControllers[deviceId]?.add(_deviceProgress[deviceId]!);

          // Update test results with new data
          testResults[deviceId] = deviceResult;
        } else if (physicalMatch != null) {
          // Handle physical JSON log data
          final physicalJsonString = physicalMatch.group(1)!;
          final physicalData = jsonDecode(physicalJsonString);

          // Create a separate JSON file for physical data
          final String physicalFileName = '${deviceId}pq.json';
          final File physicalFile = File(physicalFileName);
          await physicalFile.writeAsString(jsonEncode(physicalData), mode: FileMode.write);

          print('Physical JSON file created: $physicalFileName');

          // Make the progress 100 percent
          _deviceProgress[deviceId] = 100;
          _progressControllers[deviceId]?.add(100);
        }
      });

      process.stderr.transform(Utf8Decoder()).listen((data) {
        print('Error: $data');
      });
    }).catchError((e) {
      print('Error starting logcat: $e');
    });
  }

  //  ---------------------- add logic for fetch and update for pqJason------------------------


  // Function to fetch data from API and update JSON file
  static Future<void> fetchDiagnosisAndUpdateFile(String diagnosesId, String deviceId) async {
    try {
      // Make the API call to fetch the diagnosis data
      final url = Uri.parse('https://getinstacash.in/warehouse/v1/public/getDataById');
      final response = await http.post(
        url,
        body: {
          'userName': 'whtest',
          'apiKey': '202cb962ac59075b964b07152d234b70',
          'diagnoseId': diagnosesId, // Replace with actual parameter if needed
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> device = data['msg'];

        if (device['serialNumber'] == deviceId) {
          // Parse diagnosisJson and store in testResults
          List<dynamic> diagnosisList = json.decode(device['diagnosisJson']);
          testResults[deviceId] = diagnosisList.cast<Map<String, dynamic>>();

          // Call createJsonFile to write the data to a JSON file
          await createJsonFile(deviceId);
          print('File created/updated successfully for device: $deviceId');

          // Parse physicalJson and create a separate JSON file
          final String physicalJsonString = device['physicalJson'];
          final Map<String, dynamic> physicalData = json.decode(physicalJsonString);
          final String physicalFileName = '${deviceId}pq.json';
          final File physicalFile = File(physicalFileName);
          await physicalFile.writeAsString(jsonEncode(physicalData), mode: FileMode.write);
          print('Physical JSON file created: $physicalFileName');
        }
      } else {
        print('Failed to load data');
      }
    } catch (e) {
      print('Error fetching diagnosis and updating file: $e');
    }
  }


  // Function to create JSON file
  static Future<void> createJsonFile(String? deviceId) async {
    try {
      if (testResults.containsKey(deviceId)) {
        final List<Map<String, dynamic>> newResults = testResults[deviceId]!;
        final String fileName = 'logcat_results_$deviceId.json';
        final File file = File(fileName);
        Map<String, dynamic> existingData = {};

        // Check if the file already exists
        if (await file.exists()) {
          // Load existing data from the file
          final String existingContent = await file.readAsString();
          List<dynamic> existingJsonList = jsonDecode(existingContent);

          // Merge existing data with new results
          for (var item in existingJsonList) {
            item.forEach((key, value) {
              existingData[key] = value;
            });
          }
        }

        // Update the existing data with new results
        for (var result in newResults) {
          result.forEach((key, value) {
            existingData[key] = value; // Update value if key exists
          });
        }

        // Convert the merged data back to a list of maps
        List<Map<String, dynamic>> finalData =
            existingData.entries.map((entry) {
          return {entry.key: entry.value};
        }).toList();
        

        // Write the merged data back to the file
        await file.writeAsString(jsonEncode(finalData), mode: FileMode.write);

        print('JSON file updated: $fileName');
      } else {
        print('No test results found for device ID: $deviceId');
      }
    } catch (e) {
      print('Error creating/updating JSON file: $e');
    }
  }

  static Future<String> getJsonFile(String? deviceId) async {
    try {
      final String fileName = 'logcat_results_$deviceId.json';
      final File file = File(fileName);

      // Check if the file exists
      if (await file.exists()) {
        // Read the content of the file
        final String content = await file.readAsString();
        
        print('JSON file read successfully: $fileName');
        return content;  // Return the content as a String
      } else {
        print('JSON file not found: $fileName');
        return '';  // Return an empty string if the file does not exist
      }
    } catch (e) {
      print('Error reading JSON file: $e');
      return '';  // Return an empty string in case of an error
    }
  }
   static Future<String> getpqJsonFile(String? deviceId) async {
    try {
      final String fileName = '${deviceId}pq.json';
      final File file = File(fileName);

      // Check if the file exists
      if (await file.exists()) {
        // Read the content of the file
        final String content = await file.readAsString();
        
        print('JSON file read successfully: $fileName');
        return content;  // Return the content as a String
      } else {
        print('JSON file not found: $fileName');
        return '';  // Return an empty string if the file does not exist
      }
    } catch (e) {
      print('Error reading JSON file: $e');
      return '';  // Return an empty string in case of an error
    }
  }

  static Future<void> deleteJsonFile(String? deviceId) async {
    try {
      final String fileName = 'logcat_results_$deviceId.json';
      final File file = File(fileName);
      final String fileName2 = '${deviceId}pq.json';
      final File file2 = File(fileName2);

      // Check if the file exists before deleting
      if (await file.exists()) {
        await file.delete();
        print('JSON file deleted: $fileName');
      } else {
        print('JSON file not found: $fileName');
      }
      if (await file2.exists()) {
        await file2.delete();
        print('JSON file deleted: $fileName2');
      } else {
        print('JSON file not found: $fileName2');
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
      if (file is File && file.path.endsWith('.json') && (file.path.contains('logcat_results_')||file.path.contains('pq'))) {
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
    // _deviceProgress.remove(deviceId);
  }

  //   this save result is for retry option 
 static Future<void> saveResults() async {
    try {
      // Get the list of unsynced devices from the database
      List<Map<String, dynamic>> unSyncedDevices =
         List.from(await SqlHelper.getUnsyncedItems());
         print("unsynced items in internet connectivity : ${unSyncedDevices}");
      //print("global userId :${GlobalUser().userId}");
       Set<String> seenSno = {};
      unSyncedDevices = unSyncedDevices.where((device) {
        // Check if the IMEI is already seen
        if (seenSno.contains(device['sno'])) {
          return false; // Skip duplicates
        } else {
          seenSno.add(device['sno']);
          return true; // Keep unique devices
        }
      }).toList();

      // Use a while loop to modify the list in place and remove items after successful sync
      int index = 0; // To track the current index
      while (index < unSyncedDevices.length) {
        var device = unSyncedDevices[index];
        final deviceId = device['sno'] ?? ''; // Assuming 'sno' is the device ID
        if (deviceId.isEmpty) {
          index++;
          continue; // Skip if IMEI is not available
        }
        print("unsynced Devices in service class :${unSyncedDevices}");
        String jsonContent=await LogCat.getJsonFile(deviceId);
        print("json String in internet Connectivity : ${jsonContent}");
        // Prepare the POST request body for the current device
        Map<String, String> requestBody = {
          'userName': 'whtest',
          'apiKey': '202cb962ac59075b964b07152d234b70',
          'userId': '1' ?? 'N/A',
          'brand': device['manufacturer'] ?? 'N/A',
          'model': device['model'] ?? 'N/A',
          'androidVersion': device['ver'] ?? 'N/A',
          'serialNumber': device['sno'] ?? 'N/A',
          'IMEINumber': device['iemi'],
          'mdmStatus': device['mdm_status'] ?? 'N/A',
          'ram': device['ram'] ?? 'N/A',
          'rom': device['rom_gb'] ?? 'N/A',
          'oem': device['oem'] ?? 'N/A',
          'diagnosisJson':
              jsonContent, // Get the JSON content
          'simLock': device['carrier_lock_status'] ?? 'N/A',
          'adminApp': 'N/A', // Adjust this as per your requirement
        };

        // Encode the body as x-www-form-urlencoded
        final String encodedBody = requestBody.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');

        // Send POST request for the current device
        var response = await http.post(
          Uri.parse(
              'https://getinstacash.in/warehouse/v1/public/saveReport'), // Replace with your actual API URL
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: encodedBody,
        );
         print("save result post current_status");

        // // Parse and handle the response for the current device
        if (response.statusCode == 200) {
          var responseData = jsonDecode(response.body);

          if (responseData['status'] == true) {
            print(
                'POST request successful for device $deviceId: ${responseData['diagnoseId']} current_status');

        //     // Mark this device as synced (update isSync to 1)
            await SqlHelper.markDeviceAsSynced(device[
                'sno']); // Assuming 'sno' is the unique device identifier

        //     // Remove the successfully synced device from the list
           unSyncedDevices.removeAt(index); // Remove at current index
          } else {
            print('Failed to sync device $deviceId: ${responseData['msg']}');
            index++; // Move to the next device if it failed
          }
        } else {
          print(
              'Failed to send POST request for device $deviceId. Status code: ${response.statusCode}');
          index++; // Move to the next device if POST request failed
        }
       index++;
      }
    } catch (e) {
      print('Error syncing devices: $e');
    }
  }
}

