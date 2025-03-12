
import 'package:warehouse_phase_1/src/helpers/log_cat.dart';
import 'package:warehouse_phase_1/src/helpers/sql_helper.dart';

class DeviceResultSaver {
  final Map<String, Map<String, String>> connectedDevices;

  DeviceResultSaver(this.connectedDevices);

  Future<void> saveResults(String deviceId) async {
    try {
      final deviceData = connectedDevices[deviceId];
      if (deviceData == null) {
        throw Exception('Device data is null for deviceId: $deviceId');
      }

      // Save to local database
      await SqlHelper.createItem(
        deviceData['manufacturer'] ?? '',
        deviceData['model'] ?? '',
        deviceData['imeiOutput'] ?? '',
        deviceData['serialNumber'] ?? '',
        deviceData['ram'] ?? '',
        deviceData['mdm_status'] ?? '',
        deviceData['oem'] ?? '',
        deviceData['rom'] ?? '',
        deviceData['carrier_lock'] ?? '',
        deviceData['androidVersion'] ?? '',
        '0',
      );

      // Save log file
      await LogCat.createJsonFile(deviceId);
    } catch (e) {
      print('Error saving results: $e');
    }
  }
}
