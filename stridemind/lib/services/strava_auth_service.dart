import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StravaAuthService {
  final String _clientId;
  final String _clientSecret;
  final String _redirectUri = 'stridemind://callback';
  final _secureStorage = const FlutterSecureStorage();

  // Keys for secure storage
  static const _accessTokenKey = 'strava_access_token';
  static const _refreshTokenKey = 'strava_refresh_token';

  StravaAuthService({
    required String clientId,
    required String clientSecret,
  })  : _clientId = clientId,
        _clientSecret = clientSecret;

  Future<void> loginWithStrava() async {
    final authUrl = Uri.parse(
      'https://www.strava.com/oauth/mobile/authorize'
      '?client_id=$_clientId'
      '&redirect_uri=$_redirectUri'
      '&response_type=code'
      '&approval_prompt=auto'
      '&scope=read,activity:read_all', // Request desired scopes
    );

    if (!await canLaunchUrl(authUrl)) {
      throw 'Could not launch $authUrl';
    }
    await launchUrl(
      authUrl,
      mode: LaunchMode.externalApplication, // Correct mode for OAuth
    );
  }

  Future<bool> exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse('https://www.strava.com/oauth/token'),
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String? accessToken = data['access_token'];
        final String? refreshToken = data['refresh_token'];

        if (accessToken != null && refreshToken != null) {
          await _storeTokens(
              accessToken: accessToken, refreshToken: refreshToken);
          debugPrint('Successfully received and stored tokens!');
          return true;
        } else {
          debugPrint('Token exchange response did not contain tokens.');
          return false;
        }
      } else {
        debugPrint('Failed to exchange code for token: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error exchanging code for token: $e');
      return false;
    }
  }

  Future<void> _storeTokens(
      {required String accessToken, required String refreshToken}) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _secureStorage.deleteAll();
  }
}