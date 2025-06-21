import 'package:flutter/material.dart';
import 'package:stridemind/pages/home_page.dart';
import 'package:stridemind/pages/login_page.dart';
import 'package:stridemind/services/strava_auth_service.dart';
import 'package:stridemind/services/firebase_auth_service.dart';
import 'package:stridemind/services/fcm_service.dart';

class SplashPage extends StatefulWidget {
  final StravaAuthService authService;
  final FirebaseAuthService firebaseAuthService = FirebaseAuthService();
  final FcmService fcmService = FcmService();

  SplashPage({super.key, required this.authService});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // A small delay can make the transition feel smoother
    await Future.delayed(const Duration(milliseconds: 500));

    // This is a more robust check. It ensures we can get a valid token,
    // refreshing it if necessary, before proceeding.
    final accessToken = await widget.authService.getValidAccessToken();
    
    bool proceedToHome = false;
    if (accessToken != null) {
      // If Strava login is valid, also sign into Firebase anonymously.
      final firebaseUser = await widget.firebaseAuthService.signInAnonymously();
      if (firebaseUser != null) {
        // Only proceed if both Strava and Firebase logins are successful.
        // Initialize FCM to get token and set up listeners
        await widget.fcmService.initialize();
        proceedToHome = true;
      }
    }
    
    if (!mounted) return;

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => proceedToHome
          ? HomePage(authService: widget.authService)
          : LoginPage(authService: widget.authService),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}