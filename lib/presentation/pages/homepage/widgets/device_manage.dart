import 'package:shared_preferences/shared_preferences.dart';

class DeviceProgressManager {
  static const String _progressPrefix = 'device_progress_';

  static Future<void> saveProgress(String deviceId, double progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$_progressPrefix$deviceId', progress);
  }

  static Future<double> getProgress(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('$_progressPrefix$deviceId') ?? 0.0;
  }

  static Future<void> deleteProgress(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_progressPrefix$deviceId';

    if (prefs.containsKey(key)) {
      await prefs.remove(key);
      print('Progress for device "$deviceId" deleted.');
    } else {
      print('No progress found for device "$deviceId".');
    }
    return;
  }
}
