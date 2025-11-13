import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../routes/app_router.dart';

/// Top-level function to handle background messages
/// Must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background message received: ${message.messageId}');
  debugPrint('   Title: ${message.notification?.title}');
  debugPrint('   Body: ${message.notification?.body}');
  debugPrint('   Data: ${message.data}');
}

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  String? _fcmToken;
  
  /// Create high importance notification channel for Android (8.0+)
  Future<void> _createNotificationChannel() async {
    try {
      // This is handled by the Android native side via AndroidManifest.xml
      // and the FirebaseMessaging plugin automatically creates the channel
      // But we can also create it programmatically if needed
      debugPrint('📢 FCM: Notification channel configured');
    } catch (e) {
      debugPrint('⚠️ FCM: Failed to create notification channel: $e');
    }
  }
  
  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      // Create high importance notification channel for Android
      await _createNotificationChannel();
      
      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      debugPrint('📱 FCM Permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ FCM: User granted notification permission');
        
        // Get FCM token
        await _getToken();
        
        // Setup foreground message handler
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        // Setup background message handler
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
        
        // Handle notification taps
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
        
        // Check if app was opened from notification
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
        
        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          debugPrint('🔄 FCM Token refreshed: $newToken');
          _fcmToken = newToken;
          _saveTokenToSupabase(newToken);
        });
      } else {
        debugPrint('❌ FCM: User denied notification permission');
      }
    } catch (e) {
      debugPrint('❌ FCM initialization error: $e');
    }
  }
  
  /// Get FCM token
  Future<String?> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('✅ FCM Token obtained: $_fcmToken');
        await _saveTokenToSupabase(_fcmToken!);
      }
      return _fcmToken;
    } catch (e) {
      debugPrint('❌ FCM: Failed to get token: $e');
      return null;
    }
  }
  
  /// Save FCM token to Supabase
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ FCM: No user logged in, cannot save token');
        return;
      }
      
      debugPrint('💾 FCM: Saving token for user: $userId');
      debugPrint('   Token (first 30 chars): ${token.substring(0, token.length > 30 ? 30 : token.length)}...');
      
      // First, check if this exact token already exists (with any userId)
      final existingToken = await _supabase
          .from('tbl_fcm_tokens')
          .select('Id, UserId')
          .eq('Id', token) // Token is the primary key
          .maybeSingle();
      
      if (existingToken != null) {
        final existingUserId = existingToken['UserId'] as String;
        
        // If token belongs to different user, update it to current user
        if (existingUserId != userId) {
          debugPrint('⚠️ FCM: Token exists for different user ($existingUserId), updating to current user ($userId)');
          await _supabase
              .from('tbl_fcm_tokens')
              .update({
                'UserId': userId,
                'LastUpdatedAt': DateTime.now().toIso8601String(),
              })
              .eq('Id', token);
          debugPrint('✅ FCM: Token updated to current user');
        } else {
          // Token exists and belongs to current user, just update timestamp
          debugPrint('ℹ️ FCM: Token already exists for this user, updating timestamp');
          await _supabase
              .from('tbl_fcm_tokens')
              .update({
                'LastUpdatedAt': DateTime.now().toIso8601String(),
              })
              .eq('Id', token);
          debugPrint('✅ FCM: Token timestamp updated');
        }
        return;
      }
      
      // Check if user has any existing tokens (for other devices)
      final userTokens = await _supabase
          .from('tbl_fcm_tokens')
          .select('Id, Token')
          .eq('UserId', userId);
      
      if (userTokens.isNotEmpty && userTokens.length > 0) {
        debugPrint('ℹ️ FCM: User has ${userTokens.length} existing token(s) from other devices');
        // We'll keep all tokens (user can have multiple devices)
      }
      
      // Insert new token
      try {
        await _supabase.from('tbl_fcm_tokens').insert({
          'Id': token, // Use token as ID for simplicity
          'UserId': userId,
          'Token': token,
          'CreatedAt': DateTime.now().toIso8601String(),
          'LastUpdatedAt': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ FCM: New token saved to Supabase');
      } catch (insertError) {
        // If insert fails due to duplicate key, try update instead
        if (insertError.toString().contains('duplicate key') || 
            insertError.toString().contains('23505')) {
          debugPrint('⚠️ FCM: Token already exists (duplicate key), updating instead...');
          await _supabase
              .from('tbl_fcm_tokens')
              .update({
                'UserId': userId,
                'LastUpdatedAt': DateTime.now().toIso8601String(),
              })
              .eq('Id', token);
          debugPrint('✅ FCM: Token updated in Supabase');
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('❌ FCM: Failed to save token to Supabase: $e');
      // If table doesn't exist, create it (this would need to be done manually in Supabase)
    }
  }
  
  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Foreground message received: ${message.messageId}');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');
    
    // Show notification UI when app is in foreground
    final context = navigatorKey.currentContext;
    if (context != null && message.notification != null) {
      final title = message.notification!.title ?? 'Notification';
      final body = message.notification!.body ?? '';
      
      // Show SnackBar with notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(body),
              ],
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Handle notification tap - navigate based on data
              _handleNotificationTap(message);
            },
          ),
        ),
      );
      
      debugPrint('✅ Notification UI shown in foreground');
    } else {
      debugPrint('⚠️ Cannot show notification UI: context not available');
    }
  }
  
  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.messageId}');
    debugPrint('   Data: ${message.data}');
    
    // Handle navigation based on notification data
    // This will be handled by the app's navigation system
  }
  
  /// Get current FCM token
  String? get currentToken => _fcmToken;
  
  /// Save token for current logged-in user
  /// This should be called after user logs in to ensure token is saved
  Future<void> saveTokenForCurrentUser() async {
    if (_fcmToken == null) {
      debugPrint('⚠️ FCM: No token available to save, trying to get token...');
      await _getToken();
    }
    
    if (_fcmToken != null) {
      debugPrint('💾 FCM: Saving token for current user...');
      await _saveTokenToSupabase(_fcmToken!);
    } else {
      debugPrint('❌ FCM: Failed to get token for saving');
    }
  }
  
  /// Refresh FCM token and save it
  /// Useful when token was not saved initially (e.g., user logged in after FCM init)
  Future<void> refreshToken() async {
    debugPrint('🔄 FCM: Refreshing token...');
    try {
      final newToken = await _messaging.getToken();
      if (newToken != null) {
        _fcmToken = newToken;
        debugPrint('✅ FCM: Token refreshed: $newToken');
        await _saveTokenToSupabase(newToken);
      } else {
        debugPrint('❌ FCM: Failed to refresh token');
      }
    } catch (e) {
      debugPrint('❌ FCM: Error refreshing token: $e');
    }
  }
  
  /// Get FCM token for a specific user from Supabase
  Future<String?> getTokenForUser(String userId) async {
    try {
      debugPrint('🔍 FCMService: Getting token for user: $userId');
      
      final response = await _supabase
          .from('tbl_fcm_tokens')
          .select('Token, Id, CreatedAt, LastUpdatedAt')
          .eq('UserId', userId)
          .maybeSingle();
      
      if (response != null && response['Token'] != null) {
        final token = response['Token'] as String;
        debugPrint('✅ FCMService: Found token for user: $userId');
        debugPrint('   Token (first 20 chars): ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
        debugPrint('   Created: ${response['CreatedAt']}');
        debugPrint('   Last Updated: ${response['LastUpdatedAt']}');
        return token;
      }
      
      debugPrint('⚠️ FCMService: No token found for user: $userId');
      debugPrint('   Checking if user exists in tbl_users...');
      
      // Check if user exists in tbl_users
      final userCheck = await _supabase
          .from('tbl_users')
          .select('Id, Email, Fullname')
          .eq('Id', userId)
          .maybeSingle();
      
      if (userCheck != null) {
        debugPrint('   ✅ User exists in tbl_users: ${userCheck['Email']} (${userCheck['Fullname']})');
        debugPrint('   ⚠️ But no FCM token found. User needs to login and allow notifications.');
      } else {
        debugPrint('   ❌ User does not exist in tbl_users with ID: $userId');
      }
      
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ FCMService: Failed to get token for user: $e');
      debugPrint('   Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Get all FCM tokens for a list of users
  Future<List<String>> getTokensForUsers(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];
      
      final List<String> tokens = [];
      
      // Query tokens for each user (Supabase may not support in_ for all cases)
      for (final userId in userIds) {
        try {
          final response = await _supabase
              .from('tbl_fcm_tokens')
              .select('Token')
              .eq('UserId', userId)
              .maybeSingle();
          
          if (response != null && response['Token'] != null) {
            tokens.add(response['Token'] as String);
          }
        } catch (e) {
          debugPrint('⚠️ FCM: Failed to get token for user $userId: $e');
        }
      }
      
      return tokens;
    } catch (e) {
      debugPrint('❌ FCM: Failed to get tokens for users: $e');
      return [];
    }
  }

  /// Delete FCM token from database (e.g., when token is invalid/expired)
  Future<void> deleteToken(String token) async {
    try {
      debugPrint('🗑️ FCMService: Deleting invalid token from database...');
      await _supabase
          .from('tbl_fcm_tokens')
          .delete()
          .eq('Id', token); // Token is the primary key
      debugPrint('✅ FCMService: Invalid token deleted from database');
    } catch (e) {
      debugPrint('❌ FCMService: Failed to delete token: $e');
    }
  }

  /// Delete all tokens for a user (e.g., when all tokens are invalid)
  Future<void> deleteTokensForUser(String userId) async {
    try {
      debugPrint('🗑️ FCMService: Deleting all tokens for user: $userId');
      await _supabase
          .from('tbl_fcm_tokens')
          .delete()
          .eq('UserId', userId);
      debugPrint('✅ FCMService: All tokens deleted for user: $userId');
    } catch (e) {
      debugPrint('❌ FCMService: Failed to delete tokens for user: $e');
    }
  }
}

