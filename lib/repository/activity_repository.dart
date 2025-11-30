import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity_model.dart';

class ActivityRepository {
  final String baseUrl;

  ActivityRepository({required this.baseUrl});

  // Add activity
  Future<bool> addActivity(Activity activity) async {
    final url = Uri.parse('$baseUrl/activities');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(activity.toJson()), // corrected here
    );

    return response.statusCode == 201;
  }

  // Get all activities
  Future<List<Activity>> getActivities() async {
    final url = Uri.parse('$baseUrl/activities');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Activity.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  // Delete activity
  Future<bool> deleteActivity(String id) async {
    final url = Uri.parse('$baseUrl/activities/$id');
    final response = await http.delete(url);
    return response.statusCode == 200;
  }
}
