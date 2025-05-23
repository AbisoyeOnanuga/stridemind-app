import 'package:flutter/material.dart';
import '../services/strava_auth_service.dart';

class LoginPage extends StatefulWidget {
  final StravaAuthService authService;
  const LoginPage({super.key, required this.authService});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authService.loginWithStrava();
      // The app will lose focus here. When it returns, the deep link handler in main.dart will take over.
    } catch (e) {
      // Handle cases where the URL can't be launched.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching Strava login: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect to Strava')),
      body: Center(
        child: ElevatedButton(
          onPressed: _isLoading ? null : _login,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Connect with Strava'),
        ),
      ),
    );
  }
}
