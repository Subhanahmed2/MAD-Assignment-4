import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_model.dart';

class LocalStorage {
  static const String keyLastActivities = 'last_activities';

  /// Save last 5 activities
  static Future<void> saveLastActivities(List<Activity> activities) async {
    final prefs = await SharedPreferences.getInstance();

    // Take only the last 5
    final lastFive = activities.take(5).toList();

    // Convert each activity to JSON string
    final encoded = lastFive.map((a) => jsonEncode(a.toJson())).toList();

    await prefs.setStringList(keyLastActivities, encoded);
  }

  /// Get last activities
  static Future<List<Activity>> getLastActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getStringList(keyLastActivities) ?? [];
    return encoded
        .map((jsonStr) => Activity.fromJson(jsonDecode(jsonStr)))
        .toList();
  }
}
