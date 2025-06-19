import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app_links/app_links.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stridemind/firebase_options.dart';
import 'package:stridemind/services/strava_auth_service.dart';
import 'package:stridemind/pages/splash_page.dart';
import 'package:stridemind/pages/home_page.dart';
import 'package:stridemind/strava_config.dart';

// Must be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, like Firestore,
  // make sure you call `initializeApp` before using them.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

Future<void> saveFcmToken(String stravaAthleteId) async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(stravaAthleteId)
        .set({'fcmToken': fcmToken}, SetOptions(merge: true));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // --- Temporary Debugging ---
  // Use this to verify that your .env variables are loaded correctly.
  // You can remove this once you've confirmed it's working.
  debugPrint('Strava Client ID Loaded: ${dotenv.env['STRAVA_CLIENT_ID']}');
  // -------------------------
  runApp(StrideMindApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

class StrideMindApp extends StatefulWidget {
  const StrideMindApp({super.key});

  @override
  State<StrideMindApp> createState() => _StrideMindAppState();
}

class _StrideMindAppState extends State<StrideMindApp> {
  late final AppLinks _appLinks;
  final StravaAuthService _stravaAuthService = StravaAuthService(
      clientId: stravaClientId,
      clientSecret: stravaClientSecret,
      redirectUri: stravaRedirectUri);

  @override
  void initState() {
    super.initState();
    // The logic for handling redirects is different for mobile and web.
    if (kIsWeb) {
      // On the web, the redirect URL is the current page URL.
      handleIncomingUri(Uri.base);
    } else {
      initAppLinks();
    }
  }

  void initAppLinks() async {
    _appLinks = AppLinks();

    try {
      // Handles cold start
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        handleIncomingUri(initialUri);
      }

      // Handles runtime deep links
      _appLinks.uriLinkStream.listen((Uri uri) {
        handleIncomingUri(uri);
      }, onError: (err) => print('onLinkError: $err'));
    } catch (e) {
      print("Error handling deep link: $e");
    }
  }

  void handleIncomingUri(Uri? uri) async {
    if (uri != null && uri.queryParameters.containsKey('code')) {
      final code = uri.queryParameters['code']!;
      print("Received Strava code: $code");
      final success = await _stravaAuthService.exchangeCodeForToken(code);

      if (success) {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
              builder: (context) => HomePage(authService: _stravaAuthService)),
        );
      } else {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(content: Text('Login failed. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'StrideMind',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashPage(authService: _stravaAuthService),
    );
  }
}
