import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionSharedPref {
  // Save subscription count with userId as the key
  static Future<void> saveSubscription(String userId, int subscriptionCount) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(userId, subscriptionCount);
  }

  // Retrieve subscription count based on userId
  static Future<int?> getSubscription(String?userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(userId??'N/A');
  }
   static Future<void> deleteSubscription(String userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(userId);
  }
}
