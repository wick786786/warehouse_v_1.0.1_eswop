import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
 static const String _keyUserId = 'userId';
  static const String _keySessionTimestamp = 'sessionTimestamp';

  // Save userId and sessionTimestamp when logging in
  static Future<void> saveLoginSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    await prefs.setString(_keyUserId, userId); // Save userId
    await prefs.setInt(_keySessionTimestamp, currentTime); // Save session timestamp
  }

  // Get userId from SharedPreferences
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  // Get session timestamp from SharedPreferences
  static Future<int?> getSessionTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySessionTimestamp);
  }

  // Check if the session is still valid (within 24 hours)
  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionTimestamp = prefs.getInt(_keySessionTimestamp);
    if (sessionTimestamp == null) return false;

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    return (currentTime - sessionTimestamp) < 24 * 60 * 60 * 1000; // 24 hours in milliseconds
  }

  //set jailbreak
  static Future<void> setJailBreak(String? deviceId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    print("DEVICEiD IN SET JAIL BREAK :${deviceId}");
    print("jail break in shared pref ${value}");
    await prefs.setBool(deviceId!, value);
  }

  // Get the boolean value for a specific deviceId
  static Future<bool?> getJailBreak(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    print("value in get Jail Break ${prefs.getBool(deviceId)}");
    return prefs.getBool(deviceId);
  }

  // Clear session when logging out
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId); // Remove userId
    await prefs.remove(_keySessionTimestamp); // Remove session timestamp
  }
}
