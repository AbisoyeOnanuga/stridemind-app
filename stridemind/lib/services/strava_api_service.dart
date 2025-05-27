import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stridemind/models/strava_activity.dart';
import 'package:stridemind/models/strava_athlete.dart';

class StravaApiService {
  final String _accessToken;
  final String _baseUrl = 'https://www.strava.com/api/v3';

  StravaApiService({required String accessToken}) : _accessToken = accessToken;

  Future<StravaAthlete> getAuthenticatedAthlete() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/athlete'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      return StravaAthlete.fromJson(jsonDecode(response.body));
    } else {
      // You can add more specific error handling based on status codes
      throw Exception('Failed to load athlete data: ${response.body}');
    }
  }

  Future<StravaActivity> getActivityDetails(int activityId) async {
    final uri = Uri.parse('$_baseUrl/activities/$activityId');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      return StravaActivity.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load activity details: ${response.body}');
    }
  }

  Future<List<StravaActivity>> getTodaysActivities() async {
    final now = DateTime.now();
    // Use local timezone midnight as the start time. Strava API handles this.
    final startOfToday = DateTime(now.year, now.month, now.day);
    final afterTimestamp = startOfToday.millisecondsSinceEpoch ~/ 1000;

    // perPage default is 30, which should be sufficient for a single day's activities.
    return getRecentActivities(after: afterTimestamp);
  }

  Future<List<StravaActivity>> getRecentActivities(
      {int page = 1, int perPage = 30, int? after, int? before}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (after != null) {
      queryParams['after'] = after.toString();
    }
    if (before != null) {
      queryParams['before'] = before.toString();
    }
    final uri = Uri.parse('$_baseUrl/athlete/activities').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> activitiesJson = jsonDecode(response.body);
      return activitiesJson
          .map((json) => StravaActivity.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load activities: ${response.body}');
    }
  }
}