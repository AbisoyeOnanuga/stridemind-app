import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stridemind/services/firebase_auth_service.dart';

class NotificationApiService {
  // Replace with your actual Vercel deployment URL
  static const String _baseUrl = 'https://strava-webhook-server-pcdcqz00y-stridemind-projects.vercel.app';

  final FirebaseAuthService _authService = FirebaseAuthService();

  Future<void> registerDevice(String fcmToken) async {
    final idToken = await _authService.getIdToken();
    if (idToken == null) {
      print('NotificationApiService: Cannot register device, user not logged in.');
      return;
    }

    final url = Uri.parse('$_baseUrl/api/register-device');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'token': fcmToken}),
      );

      if (response.statusCode == 200) {
        print('Device registered successfully with Vercel backend.');
      } else {
        print('Failed to register device. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Error registering device with Vercel backend: $e');
    }
  }
}