import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_model.dart';
import '../repository/activity_repository.dart';

class ActivityProvider extends ChangeNotifier {
  List<Activity> activities = [];
  final ActivityRepository repository;

  ActivityProvider({required this.repository}) {
    loadOfflineActivities();
  }

  /// Add activity locally and optionally sync to API
  Future<void> addActivity(Activity activity, {bool syncApi = true}) async {
    // Add to front
    activities.insert(0, activity);

    // Keep only last 5 activities
    if (activities.length > 5) {
      activities = activities.sublist(0, 5);
    }

    notifyListeners();

    // Save offline
    await saveOfflineActivities();

    // Sync to API
    if (syncApi) {
      try {
        await repository.addActivity(activity);
      } catch (e) {
        if (kDebugMode) print('Failed to sync activity: $e');
      }
    }
  }

  /// Save last 5 activities offline
  Future<void> saveOfflineActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = activities.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('recent_activities', jsonList);
  }

  /// Load offline activities
  Future<void> loadOfflineActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('recent_activities') ?? [];
    activities = jsonList
        .map((e) => Activity.fromJson(jsonDecode(e)))
        .toList();
    notifyListeners();
  }

  /// Remove activity
  Future<void> removeActivity(String id, {bool syncApi = true}) async {
    activities.removeWhere((a) => a.id == id);
    notifyListeners();
    await saveOfflineActivities(); // update offline

    if (syncApi) {
      try {
        await repository.deleteActivity(id);
      } catch (e) {
        if (kDebugMode) print('Failed to delete activity: $e');
      }
    }
  }

  /// Fetch from API
  Future<void> fetchActivitiesFromApi() async {
    try {
      final fetched = await repository.getActivities();
      setActivities(fetched);
    } catch (e) {
      if (kDebugMode) print('Failed to fetch from API: $e');
    }
  }

  void setActivities(List<Activity> list) {
    activities = list;
    if (activities.length > 5) activities = activities.sublist(0, 5);
    notifyListeners();
    saveOfflineActivities();
  }
}
