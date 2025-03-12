import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart';
import 'package:warehouse_phase_1/src/helpers/log_cat.dart';
import 'package:warehouse_phase_1/src/helpers/sql_helper.dart';
import 'package:http/http.dart' as http;
class InternetStatusChecker {
  final Connectivity _connectivity = Connectivity();
  String? userId = "";
  // Method to check the current connection status
  Future<bool> checkInternetStatus() async {
     userId = await PreferencesHelper.getUserId();
     print("user id in internet status $userId");
    final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
    
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
