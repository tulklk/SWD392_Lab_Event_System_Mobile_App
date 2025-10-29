import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Session Controller to manage user session persistently
/// Uses FlutterSecureStorage for secure session storage
class SessionController {
  SessionController._internal();

  static final SessionController _instance = SessionController._internal();
  static SessionController get instance => _instance;

  String? userId;
  String? token;
  DateTime? expiryDate;

  final _storage = const FlutterSecureStorage();

  // Storage keys
  static const String _keyUserId = 'userId';
  static const String _keyToken = 'token';
  static const String _keyExpiryDate = 'expiryDate';

  /// Save session data to secure storage
  Future<void> setSession({
    required String userId,
    required String token,
    required DateTime expiryDate,
  }) async {
    try {
      debugPrint('💾 SessionController: Saving session...');
      this.userId = userId;
      this.token = token;
      this.expiryDate = expiryDate;

      await _storage.write(key: _keyUserId, value: userId);
      await _storage.write(key: _keyToken, value: token);
      await _storage.write(key: _keyExpiryDate, value: expiryDate.toIso8601String());

      debugPrint('✅ Session saved successfully!');
      debugPrint('   User ID: $userId');
      debugPrint('   Token: ${token.substring(0, 20)}...');
      debugPrint('   Expires: ${expiryDate.toIso8601String()}');
      
      // Verify save by reading back
      final verify = await _storage.read(key: _keyUserId);
      debugPrint('✅ Verification: User ID read back = $verify');
    } catch (e) {
      debugPrint('❌ Error saving session: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
    }
  }

  /// Load session data from secure storage
  Future<bool> loadSession() async {
    try {
      debugPrint('📖 SessionController: Loading session from secure storage...');
      
      final response = await Future.wait([
        _storage.read(key: _keyUserId),
        _storage.read(key: _keyToken),
        _storage.read(key: _keyExpiryDate),
      ]);

      userId = response[0];
      token = response[1];
      final expiryDateString = response[2];

      debugPrint('📖 Raw data from storage:');
      debugPrint('   userId: ${userId ?? "NULL"}');
      debugPrint('   token: ${token != null ? "${token!.substring(0, 20)}..." : "NULL"}');
      debugPrint('   expiryDate: ${expiryDateString ?? "NULL"}');

      if (expiryDateString != null) {
        expiryDate = DateTime.parse(expiryDateString);
      }

      // Check if session is valid
      if (userId != null && token != null && expiryDate != null) {
        final now = DateTime.now();
        final isValid = expiryDate!.isAfter(now);
        
        debugPrint('📊 Session validation:');
        debugPrint('   Current time: ${now.toIso8601String()}');
        debugPrint('   Expires at: ${expiryDate!.toIso8601String()}');
        debugPrint('   Is valid: $isValid');
        
        if (isValid) {
          debugPrint('✅ Session loaded successfully: User $userId');
          return true;
        } else {
          debugPrint('⏰ Session expired, clearing...');
          await clearSession();
          return false;
        }
      }

      debugPrint('ℹ️ No valid session data found in storage');
      return false;
    } catch (e) {
      debugPrint('❌ Error loading session: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Clear session data from secure storage
  Future<void> clearSession() async {
    try {
      userId = null;
      token = null;
      expiryDate = null;

      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyExpiryDate);

      debugPrint('🗑️ Session cleared');
    } catch (e) {
      debugPrint('❌ Error clearing session: $e');
    }
  }

  /// Check if session exists and is valid
  bool get hasValidSession {
    return userId != null &&
        token != null &&
        expiryDate != null &&
        expiryDate!.isAfter(DateTime.now());
  }

  /// Check if session exists (even if expired)
  bool get hasSession {
    return userId != null && token != null;
  }

  /// Check if session is expired
  bool get isExpired {
    if (expiryDate == null) return true;
    return expiryDate!.isBefore(DateTime.now());
  }

  /// Get session info as string for debugging
  String get sessionInfo {
    if (!hasSession) return 'No session';
    return 'User: $userId, Token: ${token?.substring(0, 20)}..., Expires: $expiryDate';
  }
}

