import 'package:warehouse_phase_1/presentation/DeviceCard/icard/sync_result.dart';
import 'package:warehouse_phase_1/src/helpers/ilogcat.dart';
import 'package:warehouse_phase_1/src/helpers/iphone_device_info.dart';
import 'package:warehouse_phase_1/src/helpers/sql_helper.dart';

class IOSDeviceService {
  static final IOSDeviceService _instance = IOSDeviceService._internal();
  factory IOSDeviceService() => _instance;
  IOSDeviceService._internal();
  String formatBytes(int bytes) {
    if (bytes <= 0) return "0B";

    const int oneKB = 1024;
    const int oneMB = oneKB * 1024;
    const int oneGB = oneMB * 1024;

    if (bytes >= oneGB) {
      // Convert bytes to GB and round to the nearest integer
      return "${(bytes / oneGB).round()}GB";
    } else if (bytes >= oneMB) {
      return "${(bytes / oneMB).round()}MB";
    } else if (bytes >= oneKB) {
      return "${(bytes / oneKB).round()}KB";
    } else {
      return "${bytes}B";
    }
  }

  Future<void> saveResultsIphone(String deviceId, Map<String, Map<String, String>> connectedIosDevices) async {
    try {
      final deviceInfo = DeviceInfoManager();
      final ram = deviceInfo.getRam(deviceId);
      final rom = deviceInfo.getRom(deviceId);
      final adminApps = deviceInfo.getAdminApps(deviceId);
      final jailBreak = deviceInfo.getJailBreak(deviceId);
      final oemLock = deviceInfo.getOemSLockStatus(deviceId) == false
          ? 'Inactive'
          : 'Active';
      final mdm =
          deviceInfo.getMDMmanaged(deviceId) == false ? 'Inactive' : 'Active';

      String ramString = formatBytes(ram);
      String romString = "${rom} GB";

      await SqlHelper.createItem(
        'Apple',
        connectedIosDevices[deviceId]?['modelIdentifier'] ?? '',
        connectedIosDevices[deviceId]?['imei'] ?? '',
        connectedIosDevices[deviceId]?['serialNumber'] ?? '',
        ramString,
        mdm ?? '',
        oemLock ?? '',
        romString,
        connectedIosDevices[deviceId]?['carrier_lock'] ?? '',
        connectedIosDevices[deviceId]?['iOSVersion'] ?? '',
        connectedIosDevices[deviceId] != null ? '0' : '',
      );

      // await SyncResult().createJsonFile(
      //     deviceId, connectedIosDevices[deviceId]?['serialNumber']);
      print("iPhone result saved for ${connectedIosDevices[deviceId]?['serialNumber']} ");
    } catch (e) {
      print('Error saving results: $e');
    }
  }
}
