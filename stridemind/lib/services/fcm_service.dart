 import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:stridemind/services/notification_api_service.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationApiService _notificationApiService = NotificationApiService();

  Future<void> initialize() async {
    // Request permissions for iOS/web
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Handle messages while the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Here you could show a local notification using a package like flutter_local_notifications
      }
    });

    // Get the token and save it to Firestore
    await _saveToken();

    // Listen for token refreshes and save the new one
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _notificationApiService.registerDevice(token);
    });
  }

  Future<void> _saveToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _notificationApiService.registerDevice(token);
    }
  }
}