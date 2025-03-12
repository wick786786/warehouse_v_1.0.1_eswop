import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:warehouse_phase_1/GlobalVariables/singelton_class.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart';
import 'package:warehouse_phase_1/src/helpers/log_cat.dart';
import 'package:warehouse_phase_1/src/helpers/sql_helper.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  String? userId = "";
  bool isSyncing = false; // Flag to track ongoing sync process
  Stream<bool> get connectionStream => _controller.stream;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen(_checkConnectivity);
    //checkCurrentInternetStatus();
  }

  void _checkConnectivity(List<ConnectivityResult> result) async {
    if (result.contains(ConnectivityResult.none)) {
      _controller.add(false);
    } else {
      // Delay the execution of saveResults by 1 second
      //await Future.delayed(const Duration(seconds: 2));
      // Check if the userId is not null before calling saveResults

      _controller.add(true);

      userId = await PreferencesHelper.getUserId();
      print("userId in service Class $userId");
      if (userId != null) {
        if (!isSyncing) {
          isSyncing = true; // Set the flag to true before starting the sync
          await saveResults();
          isSyncing = false; // Reset the flag after the sync is done
        } else {
          print("Sync process is already ongoing, skipping this request.");
        }
      }
    }
  }

  Future<bool> checkCurrentInternetStatus() async {
    final List<ConnectivityResult> result =
        await _connectivity.checkConnectivity();
    userId = await PreferencesHelper.getUserId();
    if (result.contains(ConnectivityResult.none)) {
      print('No internet connection');
      return false;
    } else if (result.contains(ConnectivityResult.wifi)) {
      print('Connected to Wi-Fi');
      return true;
    } else if (result.contains(ConnectivityResult.mobile)) {
      print('Connected to mobile data');
      return true;
    } else {
      print('Unknown connection status');
      return false;
    }
  }

  Future<void> saveResults() async {
    try {
      // Get the list of unsynced devices from the database
      List<Map<String, dynamic>> unSyncedDevices =
          await SqlHelper.getUnsyncedItems();

      // Filter duplicates by IMEI (or 'sno')
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

      print("unsynced Devices in service class :${unSyncedDevices}");
      //print("global userId :${GlobalUser().userId}");
      //await Future.delayed(const Duration(seconds: 10));
      // Use a while loop to modify the list in place and remove items after successful sync
      int index = 0; // To track the current index
      while (index < unSyncedDevices.length) {
        var device = unSyncedDevices[index];
        final deviceId = device['sno'] ?? ''; // Assuming 'sno' is the device ID
        if (deviceId.isEmpty) {
          index++;
          continue; // Skip if deviceId is not available
        }
        
            String jsonContent2=await LogCat.getpqJsonFile(deviceId);
            String jsonContent=await LogCat.getJsonFile(deviceId);
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
        print("save result post in connectivity_check");

        // // Parse and handle the response for the current device
        if (response.statusCode == 200) {
          var responseData = jsonDecode(response.body);

          if (responseData['status'] == true) {
            print(
                'POST request successful for device $deviceId: ${responseData['diagnoseId']} in connectivity_check');

            //     // Mark this device as synced (update isSync to 1)
            await SqlHelper.markDeviceAsSynced(device[
                'sno']); // Assuming 'sno' is the unique device identifier

            //     // Remove the successfully synced device from the list
            // unSyncedDevices.removeAt(index); // Remove at current index
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

  Future<bool> checkInitialConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    print("result in connectivity  $result");
    return result != ConnectivityResult.none;
  }

  void dispose() {
    _controller.close();
  }
}
