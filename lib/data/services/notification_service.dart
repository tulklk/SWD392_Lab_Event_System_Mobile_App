import 'package:flutter/foundation.dart';
import 'fcm_service.dart';
import 'fcm_v1_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/notification_repository.dart';

/// Service to send push notifications via FCM
/// Uses FCM HTTP v1 API with Service Account
class NotificationService {
  final FCMService _fcmService = FCMService();
  final FCMV1Service _fcmV1Service = FCMV1Service(); // Use v1 API with Service Account
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationRepository _notificationRepository = NotificationRepository();
  
  /// Check if FCM is properly configured
  /// FCM v1 API is always available (uses Service Account from code)
  bool get isConfigured => true;
  
  /// Send notification to a specific user by FCM token
  /// Uses FCM HTTP v1 API with Service Account
  Future<bool> sendNotificationToToken({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (!isConfigured) {
      debugPrint('⚠️ FCM is not configured. Notification will not be sent.');
      return false;
    }
    
    debugPrint('📤 NotificationService: Sending FCM notification via v1 API...');
    debugPrint('   Using Service Account authentication');
    
    // Use FCM v1 API with Service Account
    return await _fcmV1Service.sendNotification(
      token: token,
      title: title,
      body: body,
      data: data,
    );
  }
  
  /// Send notification to a user by userId
  Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? targetGroup, // Optional: specify target group (student, lecturer, admin, all)
  }) async {
    try {
      debugPrint('📤 NotificationService: Attempting to send notification to user: $userId');
      debugPrint('   Title: $title');
      debugPrint('   Body: $body');
      
      // Check if FCM is configured
      if (!isConfigured) {
        debugPrint('❌ NotificationService: FCM is not configured!');
        return false;
      }
      
      // Get FCM token for user
      debugPrint('🔍 NotificationService: Getting FCM token for user: $userId');
      final token = await _fcmService.getTokenForUser(userId);
      
      if (token == null) {
        debugPrint('❌ NotificationService: No FCM token found for user: $userId');
        debugPrint('   This means the lecturer has not logged in and initialized FCM yet.');
        debugPrint('   The lecturer needs to:');
        debugPrint('   1. Login to the app');
        debugPrint('   2. Allow notification permissions');
        debugPrint('   3. FCM token will be automatically saved to tbl_fcm_tokens');
        return false;
      }
      
      debugPrint('✅ NotificationService: Found FCM token for user: $userId');
      debugPrint('   Token (first 20 chars): ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      
      final result = await _fcmV1Service.sendNotificationWithErrorCode(
        token: token,
        title: title,
        body: body,
        data: data,
      );
      
      final success = result['success'] == true;
      final errorCode = result['errorCode'] as String?;
      
      // If notification failed due to UNREGISTERED token, remove it from database
      if (!success && errorCode == 'UNREGISTERED') {
        debugPrint('🗑️ NotificationService: Token is UNREGISTERED, removing from database...');
        await _fcmService.deleteToken(token);
        debugPrint('✅ NotificationService: Invalid token removed from database');
        debugPrint('   User needs to login again to get a new token');
      } else if (!success) {
        debugPrint('⚠️ NotificationService: Notification send failed (error: $errorCode)');
      }
      
      // Save notification to database regardless of FCM send result
      // This ensures user can see notifications even if FCM failed
      try {
        // Use provided targetGroup or default to 'all'
        final notificationTargetGroup = targetGroup ?? 'all';
        
        // Create notification in tbl_notifications
        final notificationResult = await _notificationRepository.createNotification(
          title: title,
          content: body,
          targetGroup: notificationTargetGroup,
          createdBy: data?['createdBy'] as String? ?? userId,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 365)), // Set endDate to 1 year from now
        );
        
        if (notificationResult.isSuccess) {
          debugPrint('✅ NotificationService: Notification saved to database (targetGroup: $notificationTargetGroup)');
        } else {
          debugPrint('⚠️ NotificationService: Failed to save notification: ${notificationResult.error}');
        }
      } catch (e) {
        debugPrint('⚠️ NotificationService: Failed to save notification to database: $e');
      }
      
      if (success) {
        debugPrint('✅ NotificationService: Notification sent successfully to user: $userId');
      } else {
        debugPrint('❌ NotificationService: Failed to send notification to user: $userId');
      }
      
      return success;
    } catch (e, stackTrace) {
      debugPrint('❌ NotificationService: Error sending notification to user: $e');
      debugPrint('   Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Send notification when student books an event (to lecturer)
  Future<bool> notifyLecturerOfBooking({
    required String lecturerId,
    required String studentName,
    required String eventTitle,
    required String bookingId,
  }) async {
    debugPrint('📨 NotificationService: notifyLecturerOfBooking called');
    debugPrint('   Lecturer ID: $lecturerId');
    debugPrint('   Student Name: $studentName');
    debugPrint('   Event Title: $eventTitle');
    debugPrint('   Booking ID: $bookingId');
    
    return await sendNotificationToUser(
      userId: lecturerId,
      title: 'New Event Registration',
      body: '$studentName has registered for your event "$eventTitle"',
      targetGroup: 'lecturer', // Target lecturers
      data: {
        'type': 'booking_created',
        'bookingId': bookingId,
        'eventTitle': eventTitle,
        'studentName': studentName,
      },
    );
  }
  
  /// Send notification when lecturer approves booking (to student)
  Future<bool> notifyStudentOfApproval({
    required String studentId,
    required String eventTitle,
    required String bookingId,
  }) async {
    debugPrint('📨 NotificationService: notifyStudentOfApproval called');
    debugPrint('   Student ID: $studentId');
    debugPrint('   Event Title: $eventTitle');
    debugPrint('   Booking ID: $bookingId');
    
    final result = await sendNotificationToUser(
      userId: studentId,
      title: 'Booking Approved',
      body: 'Your registration for event "$eventTitle" has been approved!',
      targetGroup: 'student', // Target students
      data: {
        'type': 'booking_approved',
        'bookingId': bookingId,
        'eventTitle': eventTitle,
      },
    );
    
    if (result) {
      debugPrint('✅ NotificationService: Approval notification sent successfully to student: $studentId');
    } else {
      debugPrint('❌ NotificationService: Failed to send approval notification to student: $studentId');
    }
    
    return result;
  }

  /// Send notification when lecturer rejects booking (to student)
  Future<bool> notifyStudentOfRejection({
    required String studentId,
    required String eventTitle,
    required String bookingId,
  }) async {
    return await sendNotificationToUser(
      userId: studentId,
      title: 'Booking Rejected',
      body: 'Your registration for "$eventTitle" has been rejected.',
      targetGroup: 'student', // Target students
      data: {
        'type': 'booking_rejected',
        'bookingId': bookingId,
        'eventTitle': eventTitle,
      },
    );
  }
}

