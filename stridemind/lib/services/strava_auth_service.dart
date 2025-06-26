import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StravaAuthService {
  final String _clientId;
  final String _clientSecret;
  final String _redirectUri;
  final _secureStorage = const FlutterSecureStorage();

  // Keys for secure storage
  static const _accessTokenKey = 'strava_access_token';
  static const _refreshTokenKey = 'strava_refresh_token';
  static const _expiresAtKey = 'strava_expires_at';

  StravaAuthService(
      {required String clientId,
      required String clientSecret,
      required String redirectUri})
      : _clientId = clientId,
        _clientSecret = clientSecret,
        _redirectUri = redirectUri;

  Future<void> loginWithStrava() async {
    final authUrl = Uri(
      scheme: 'https',
      host: 'www.strava.com',
      path: '/oauth/mobile/authorize',
      queryParameters: {
        'client_id': _clientId,
        'redirect_uri': _redirectUri,
        'response_type': 'code',
        'approval_prompt': 'auto',
        'scope': 'read,activity:read_all',
      },
    );

    // --- IMPORTANT DEBUGGING STEP ---
    // Print the exact URL being launched to the console.
    if (kDebugMode) {
      print('Launching Strava Auth URL: $authUrl');
    }
    // --------------------------------

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
        final int? expiresAt = data['expires_at']; // Unix timestamp in seconds

        if (accessToken != null &&
            refreshToken != null &&
            expiresAt != null) {
          await _storeTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
          );
          if (kDebugMode) {
            print('Successfully received and stored tokens!');
          }
          return true;
        } else {
          if (kDebugMode) {
            print('Token exchange response did not contain tokens.');
          }
          return false;
        }
      } else {
        if (kDebugMode) {
          print('Failed to exchange code for token: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error exchanging code for token: $e');
      }
      return false;
    }
  }

  Future<void> _storeTokens(
      {required String accessToken,
      required String refreshToken,
      required int expiresAt}) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    await _secureStorage.write(
        key: _expiresAtKey, value: expiresAt.toString());
  }

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _secureStorage.deleteAll();
  }

  /// Gets a valid access token, refreshing it if it's expired.
  Future<String?> getValidAccessToken() async {
    final expiresAtStr = await _secureStorage.read(key: _expiresAtKey);
    if (expiresAtStr == null) {
      if (kDebugMode) {
        print('User not logged in, no expiration time found.');
      }
      return null; // Not logged in
    }

    final expiresAt = int.tryParse(expiresAtStr) ?? 0;
    final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Check if the token is expired or will expire in the next 5 minutes
    if (nowInSeconds >= expiresAt - 300) {
      if (kDebugMode) {
        print('Access token expired or expiring soon, refreshing...');
      }
      return await _refreshToken();
    }

    if (kDebugMode) {
      print('Access token is valid.');
    }
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> _refreshToken() async {
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (refreshToken == null) {
      if (kDebugMode) {
        print('No refresh token found. Logging out.');
      }
      await logout(); // Can't refresh without a refresh token
      return null;
    }

    final response = await http.post(
      Uri.parse('https://www.strava.com/oauth/token'),
      body: {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _storeTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresAt: data['expires_at']);
      if (kDebugMode) {
        print('Token refreshed successfully.');
      }
      return data['access_token'];
    } else {
      if (kDebugMode) {
        print('Failed to refresh token: ${response.body}');
      }
      await logout(); // If refresh fails, log the user out.
      return null;
    }
  }
}