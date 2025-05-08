import 'package:flutter/material.dart';
import '../services/strava_auth_service.dart';
import 'package:app_links/app_links.dart';

void initDeepLinkListener() {
  final appLinks = AppLinks();

  appLinks.uriLinkStream.listen((Uri? uri) {
    if (uri != null && uri.scheme == 'myapp') {
      final code = uri.queryParameters['code'];
      if (code != null) {
        StravaAuthService().exchangeCodeForToken(code);
      }
    }
  });
}

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final StravaAuthService _authService = StravaAuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connect to Strava')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _authService.loginWithStrava();
          },
          child: Text('Connect to Strava'),
        ),
      ),
    );
  }
}
