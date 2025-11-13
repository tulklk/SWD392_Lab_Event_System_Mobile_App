import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:jose/jose.dart';

/// Service to send FCM notifications using HTTP v1 API with Service Account
class FCMV1Service {
  // Service Account credentials (from JSON file)
  static const String _projectId = 'lab-system-system';
  static const String _clientEmail = 'firebase-adminsdk-fbsvc@lab-system-system.iam.gserviceaccount.com';
  static const String _privateKeyId = 'b28114a0a6268f66e994ea4316e47bf160b80595';
  static const String _privateKey = '''-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC9sr/Ph7iCvOvr
JMXA2zaoDXhS8oe1oJ3z1XLyeEFATWBPJ+Qk6A+MxD3E60QxbPoQg591Pwv95qCW
2OpxAW8YVv7MrOKIHrW72UqYpKEmfCwsuM3SdnhEcs+QH7Zi5iOtyDSRjVAAI2xK
ltrvyB21F/IiEMzp9eskRd2CdXtzy97lfY5XVIyTeTpzyt/olDMENBawTSITIfDh
iNDImId4d5saFDgPOaW+puxS2GuGojmYB+0LiiMMeePP99O7ELAFiQy+fncl+0QD
W7+N9mjBJpmacQHJGygfRFk3y0Iq1LE7TJREUArw5cr1LyVsM7Hz19EuxWvys9Hv
OyTtfUmLAgMBAAECggEARIEvuY9Gt5foDpPKAlpnw4qRwEqrbZDiWbLkfuGklsca
l5tNTXKsYuZfdCSODNdQ+vO9ewbYmslVhwQwrbyZ1Q1dmKZ6bDPC52KSCMuzEoXX
IhNe6Lk1t2pKwL5jDBYWHmTlbwa8NECWk90klWEMMWDDZT/x8C+JyiCc3Mb2XRtL
9M94E4SyAq/3pbPemJyuK/3WiY3kUe5vhyEvM+n1HNEPbATeZLzOhJZnEhxg7+58
nVZtKPjxEeOtsoSd2xfa/Adxvx4nbriHCcNi6rh4s2E9BQWDZ2rOJTV2P9GBzdkn
MOkEoqmLx94vkYt5oZPwDvL3SCyfNbW7QvLj586z0QKBgQDtwNGSyfrn49RKGJGc
ne60yfrjK/MhfINI/EFvslDaFB5ouiw3NAdnlU4QlsZYLK5ckH7Tj1rTD77eAd6o
xSciuF4M130tcanEy2BEDFgdqW2y8TT9JPQ9SpriGYR6H2oUw7+xQxFCW4Plt+Au
lHkCXz9GPOdJ7+Ut8aRzxFLy+QKBgQDMQckwZyXbmT44LBx0YjPM8ciX2VLEaqyH
XRENzs0aBCc4h0w3T9/WiynwYNZYUMwKgURMtXrjfHqlVtRWOEw+PjmztsNuiWii
9wMqccdF/+TE+ZNTihIRPadRkf8oMNqK4NabmJzlMHkrG5eYx5hmlFYEalW6wC04
+R6jdZF9owKBgQCU2sxb4ym8VeBsI8XHEPqLJop2AOZQaOypnYY6sKH+Z+pCF43n
YiPgrpIZwMyeGBtyyOUe//oVex49UV5evFEsY9I+qAwvj6KDG/JBqJjiuVl9V5ed
hq2EUll2hhNzgoegSI6UJTGBIlsKUH2DrGG3InszNp54pEIQ6eHUuW5VwQKBgQDF
gALSW5peiQGBfR2SZ3Yg/9TvBwMhyufCB3o6+LCXLFbkMObAQOp136AQvwHi6VUx
/yYUahJGLpHEl32/VLZcJPzUSa8UjabwlJmqC9QcWj9ROuV6jHHF2/CSTfIDYaGf
UaIRV3K1pbYzuX1PDAfPgDTgFhWI+tN/WFqIwWCJswKBgFATGlsR9OgIn/KELI/I
TeYq1YNwH+ThZ/sOfVIX/2pgypotIbesqVOuIBlBU61Cq8CBaKBwP9qyMhEfJRuh
T9rv1AHVlP4KZAUtx1kEcoCaEv12SBv65yJEqwAT98s7gVcwqRkpuhghH1mldpIl
hSRov3NUU/twdqDFUbeCtqWW
-----END PRIVATE KEY-----''';

  String? _accessToken;
  DateTime? _tokenExpiry;

  /// Get or refresh access token for FCM v1 API
  Future<String> _getAccessToken() async {
    // Check if we have a valid cached token
    if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    debugPrint('🔑 FCMV1Service: Generating new access token...');

    try {
      // Create JWT for service account
      final now = DateTime.now();
      final expiry = now.add(const Duration(hours: 1));

      final claims = {
        'iss': _clientEmail,
        'sub': _clientEmail,
        'aud': 'https://oauth2.googleapis.com/token',
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'exp': expiry.millisecondsSinceEpoch ~/ 1000,
        'scope': 'https://www.googleapis.com/auth/firebase.messaging',
      };

      // Create JWT using jose package
      final builder = JsonWebSignatureBuilder()
        ..jsonContent = claims
        ..addRecipient(
          JsonWebKey.fromPem(_privateKey),
          algorithm: 'RS256',
        );

      final jwt = builder.build();
      final signedJwt = jwt.toCompactSerialization();
      
      debugPrint('   JWT created (length: ${signedJwt.length})');

      // Exchange JWT for access token
      debugPrint('   Requesting access token from Google OAuth2...');
      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': signedJwt,
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokenData = jsonDecode(tokenResponse.body);
        _accessToken = tokenData['access_token'] as String;
        final expiresIn = tokenData['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60)); // Refresh 1 min early

        debugPrint('✅ FCMV1Service: Access token obtained (expires in ${expiresIn}s)');
        return _accessToken!;
      } else {
        debugPrint('❌ FCMV1Service: Failed to get access token: ${tokenResponse.statusCode}');
        debugPrint('   Response: ${tokenResponse.body}');
        throw Exception('Failed to get access token: ${tokenResponse.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ FCMV1Service: Error getting access token: $e');
      debugPrint('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Send notification using FCM HTTP v1 API
  /// Returns a map with 'success' (bool) and 'errorCode' (String?) if failed
  Future<Map<String, dynamic>> sendNotificationWithErrorCode({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('📤 FCMV1Service: Sending notification via FCM v1 API...');
      debugPrint('   Token (first 20 chars): ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      debugPrint('   Title: $title');
      debugPrint('   Body: $body');

      // Get access token
      final accessToken = await _getAccessToken();

      // Build FCM v1 API message
      final message = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data?.map((key, value) => MapEntry(key, value.toString())),
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'high_importance_channel',
              'priority': 'high',
              'default_sound': true,
              'default_vibrate_timings': true,
            },
            'ttl': '86400s', // 24 hours time to live
          },
          'apns': {
            'headers': {
              'apns-priority': '10',
            },
            'payload': {
              'aps': {
                'sound': 'default',
                'content-available': 1,
              },
            },
          },
        },
      };

      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      debugPrint('📥 FCMV1Service: Response received');
      debugPrint('   Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('✅ FCMV1Service: Notification sent successfully');
        debugPrint('   Response: $responseData');
        return {'success': true};
      } else {
        debugPrint('❌ FCMV1Service: Failed to send notification: ${response.statusCode}');
        debugPrint('   Response body: ${response.body}');
        
        String? errorCode;
        // Parse error details
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            final error = errorData['error'];
            errorCode = error['details']?[0]?['errorCode'];
            final errorMessage = error['message'];
            
            debugPrint('   Error Code: $errorCode');
            debugPrint('   Error Message: $errorMessage');
            
            // Handle UNREGISTERED token - token is invalid or expired
            if (errorCode == 'UNREGISTERED') {
              debugPrint('   ⚠️ FCM Token is UNREGISTERED (invalid or expired)');
              debugPrint('   This token should be removed from database');
              debugPrint('   User needs to login again to get a new token');
            }
          }
        } catch (e) {
          debugPrint('   Could not parse error response: $e');
        }
        
        return {'success': false, 'errorCode': errorCode};
      }
    } catch (e, stackTrace) {
      debugPrint('❌ FCMV1Service: Error sending notification: $e');
      debugPrint('   Stack trace: $stackTrace');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Send notification using FCM HTTP v1 API (backward compatibility)
  Future<bool> sendNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final result = await sendNotificationWithErrorCode(
      token: token,
      title: title,
      body: body,
      data: data,
    );
    return result['success'] == true;
  }
}

