import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:warehouse_phase_1/GlobalVariables/singelton_class.dart';
import 'dart:convert';

import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart';
import 'package:warehouse_phase_1/src/helpers/log_cat.dart';
import 'package:warehouse_phase_1/src/helpers/sql_helper.dart';

class ApiServices {
  
  Future<int> fetchCount() async {
    String? userId = await PreferencesHelper.getUserId();
    print("user id in api services class : $userId");
    final url = Uri.parse('https://getinstacash.in/warehouse/v1/public/getDCount');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'userName': 'whtest',
        'apiKey': '202cb962ac59075b964b07152d234b70',
        'userId': userId, // Replace with actual userId
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('count in api services class : ${data}');
      return data['count']; // Adjust according to the actual response structure
    } else {
      throw Exception('Failed to fetch count');
    }
  }

  Future<void> saveResults() async {
    try {
      // Fetch the userId
      String? userId = await PreferencesHelper.getUserId();
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
       String jsonContent=await LogCat.getJsonFile(deviceId);
        String jsonContent2=await LogCat.getpqJsonFile(deviceId);

        print("json String in internet Connectivity : ${jsonContent}");
        print("json String 2 in internet Connectivity : ${jsonContent2}");
        // Prepare the POST request body for the current device
        Map<String, String> requestBody = {
          'userName': 'whtest',
          'apiKey': '202cb962ac59075b964b07152d234b70',
          'userId': userId ?? 'N/A',
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
              'physicalJson':jsonContent2,
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
                'POST request successful for device $deviceId: ${responseData['diagnoseId']} api services');

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
  Future<bool> blacklistCheck(String imeiNumber) async {
    try {
      final url = Uri.parse('https://getinstacash.in/warehouse/v1/public/checkBlacklist');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'userName': 'whtest',
          'apiKey': '202cb962ac59075b964b07152d234b70',
          'IMEINumber': imeiNumber,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Blacklist check response: ${data}');
        return data['isBlacklist'] == 1;
      } else {
        print('Failed to check blacklist status. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error checking blacklist status: $e');
      return false;
    }
  }

  Future<String> downloadReport(String userId, String type, String startDate, String endDate, List<String> ids) async {
    try {
      final url = Uri.parse('https://getinstacash.in/warehouse/v1/public/getReport');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'userName': 'whtest',
          'apiKey': '202cb962ac59075b964b07152d234b70',
          'userId': userId,
          'type': type,
          'startDate': startDate,
          'endDate': endDate,
          'ids': ids.join(','), // Join the list of IDs into a comma-separated string
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Download report response: ${data}');
        if (data['status'] == true) {
          final reportUrl = data['msg'];
          print('Opening report URL: $reportUrl');
          return reportUrl; // Return the report URL on success
        } else {
          print('Failed to download report: ${data['msg']}');
          return 'Failed to download report: ${data['msg']}'; // Return the failure message
        }
      } else {
        print('Failed to download report. Status code: ${response.statusCode}');
        return 'Failed to download report. Status code: ${response.statusCode}'; // Return the status code message
      }
    } catch (e) {
      print('Error downloading report: $e');
      return 'Error downloading report: $e'; // Return the error message
    }
  }
  Future<Map<String, dynamic>> viewHistory(String imeiNumber) async {
    try {
      final url = Uri.parse('https://getinstacash.in/warehouse/v1/public/getIMEIHistory');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'userName': 'whtest',
          'apiKey': '202cb962ac59075b964b07152d234b70',
          'userId': await PreferencesHelper.getUserId() ?? 'N/A',
          'IMEINumber': imeiNumber,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('IMEI history response: ${data}');
        return data;
      } else {
        print('Failed to fetch IMEI history. Status code: ${response.statusCode}');
        Fluttertoast.showToast(
          msg: "Failed to fetch IMEI history. Status code: ${response.statusCode}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
        );
        return {};
      }
    } catch (e) {
      print('Error fetching IMEI history: $e');
      Fluttertoast.showToast(
        msg: "Error fetching IMEI history: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
      );
      return {};
    }
  }
  //String physicalQuestionResponse = '';

  Future<void> fetchPhysicalQuestion() async {
    try {
      final url = Uri.parse('https://getinstacash.in/warehouse/v1/public/getPhysicalQuestion');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'userName': 'whtest',
          'apiKey': '202cb962ac59075b964b07152d234b70',
          'userId': await PreferencesHelper.getUserId() ?? 'N/A',
        },
      );

      if (response.statusCode == 200) {
        GlobalUser().physicalQuestionResponse = response.body;
        print('Physical question response: ${GlobalUser().physicalQuestionResponse}');
      } else {
        print('Failed to fetch physical questions. Status code: ${response.statusCode}');
        // Show toaster message
        Fluttertoast.showToast(
          msg: "Failed to fetch physical questions. Status code: ${response.statusCode}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
        );
      }
    } catch (e) {
      print('Error fetching physical questions: $e');
      // Show toaster message
      Fluttertoast.showToast(
        msg: "Error fetching physical questions: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
      );
    }
  }

  Future<void> fetchTestProfiles() async {
    try {
      final url = Uri.parse('https://sbox.getinstacash.in/ic-web/warehouse/v1/public/getTestProfile');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'userName': 'whtest',
          'apiKey': '202cb962ac59075b964b07152d234b70',
          'userId': await PreferencesHelper.getUserId() ?? 'N/A',
        },
      );

      if (response.statusCode == 200) {
        GlobalUser().testProfile = response.body;
        print('Test profiles response: ${GlobalUser().testProfile}');
      } else {
        print('Failed to fetch test profiles. Status code: ${response.statusCode}');
        // Show toaster message
        Fluttertoast.showToast(
          msg: "Failed to fetch test profiles. Status code: ${response.statusCode}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
        );
      }
    } catch (e) {
      print('Error fetching test profiles: $e');
      // Show toaster message
      Fluttertoast.showToast(
        msg: "Error fetching test profiles: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
      );
    }
  }

  
}