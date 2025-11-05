import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/fcm_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/repositories/event_repository.dart';

/// Helper class to test and debug notifications
class NotificationHelper {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final FCMService _fcmService = FCMService();
  static final NotificationService _notificationService = NotificationService();

  /// Check if user has FCM token in database
  static Future<void> checkUserFCMToken(String userId) async {
    debugPrint('🔍 NotificationHelper: Checking FCM token for user: $userId');
    
    try {
      // Check if user exists
      final userCheck = await _supabase
          .from('tbl_users')
          .select('Id, Email, Fullname')
          .eq('Id', userId)
          .maybeSingle();
      
      if (userCheck == null) {
        debugPrint('❌ NotificationHelper: User not found in tbl_users: $userId');
        return;
      }
      
      debugPrint('✅ NotificationHelper: User found: ${userCheck['Email']} (${userCheck['Fullname']})');
      
      // Check FCM token
      final token = await _fcmService.getTokenForUser(userId);
      
      if (token == null) {
        debugPrint('❌ NotificationHelper: No FCM token found for user: $userId');
        debugPrint('   User needs to:');
        debugPrint('   1. Login to the app');
        debugPrint('   2. Allow notification permissions');
        debugPrint('   3. FCM token will be automatically saved');
      } else {
        debugPrint('✅ NotificationHelper: FCM token found for user: $userId');
        debugPrint('   Token (first 30 chars): ${token.substring(0, token.length > 30 ? 30 : token.length)}...');
      }
    } catch (e) {
      debugPrint('❌ NotificationHelper: Error checking FCM token: $e');
    }
  }

  /// Test sending notification to a user
  static Future<bool> testNotificationToUser(String userId, {
    String? title,
    String? body,
  }) async {
    debugPrint('🧪 NotificationHelper: Testing notification to user: $userId');
    
    final result = await _notificationService.sendNotificationToUser(
      userId: userId,
      title: title ?? 'Test Notification',
      body: body ?? 'This is a test notification from NotificationHelper',
      targetGroup: 'student',
    );
    
    if (result) {
      debugPrint('✅ NotificationHelper: Test notification sent successfully');
    } else {
      debugPrint('❌ NotificationHelper: Test notification failed');
    }
    
    return result;
  }

  /// Check FCM token for current logged-in user
  static Future<void> checkCurrentUserFCMToken() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('❌ NotificationHelper: No user logged in');
      return;
    }
    
    await checkUserFCMToken(userId);
  }

  /// Get all users with their FCM tokens (for debugging)
  static Future<void> listAllUsersWithTokens() async {
    debugPrint('🔍 NotificationHelper: Listing all users with FCM tokens...');
    
    try {
      final tokens = await _supabase
          .from('tbl_fcm_tokens')
          .select('UserId, Token, CreatedAt')
          .order('CreatedAt', ascending: false);
      
      if (tokens.isEmpty) {
        debugPrint('⚠️ NotificationHelper: No FCM tokens found in database');
        return;
      }
      
      debugPrint('✅ NotificationHelper: Found ${tokens.length} FCM token(s):');
      
      for (var token in tokens) {
        final userId = token['UserId'] as String;
        
        // Get user info
        final userInfo = await _supabase
            .from('tbl_users')
            .select('Email, Fullname')
            .eq('Id', userId)
            .maybeSingle();
        
        final email = userInfo?['Email'] ?? 'Unknown';
        final name = userInfo?['Fullname'] ?? 'Unknown';
        
        debugPrint('   User: $name ($email)');
        debugPrint('   UserId: $userId');
        debugPrint('   Token: ${(token['Token'] as String).substring(0, 30)}...');
        debugPrint('   Created: ${token['CreatedAt']}');
        debugPrint('');
      }
    } catch (e) {
      debugPrint('❌ NotificationHelper: Error listing tokens: $e');
    }
  }
}

