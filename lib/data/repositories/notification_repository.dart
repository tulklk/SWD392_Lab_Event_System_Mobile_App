import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/result.dart';
import '../../domain/models/notification.dart' as model;

class NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // Get all notifications
  Future<Result<List<model.Notification>>> getAllNotifications() async {
    try {
      final response = await _supabase
          .from('tbl_notifications')
          .select()
          .order('CreatedAt', ascending: false);

      final notifications = (response as List)
          .map((json) => model.Notification.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(notifications);
    } catch (e) {
      return Failure('Failed to fetch notifications: $e');
    }
  }

  // Get active notifications for a specific target group
  Future<Result<List<model.Notification>>> getNotificationsForUser(String userRole) async {
    try {
      final now = DateTime.now();
      
      final response = await _supabase
          .from('tbl_notifications')
          .select()
          .eq('Status', 1)
          .or('TargetGroup.eq.all,TargetGroup.eq.$userRole')
          .lte('StartDate', now.toIso8601String())
          .or('EndDate.is.null,EndDate.gte.${now.toIso8601String()}')
          .order('CreatedAt', ascending: false);

      final notifications = (response as List)
          .map((json) => model.Notification.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(notifications);
    } catch (e) {
      return Failure('Failed to fetch notifications: $e');
    }
  }

  // Get notification by ID
  Future<Result<model.Notification>> getNotificationById(String notificationId) async {
    try {
      final response = await _supabase
          .from('tbl_notifications')
          .select()
          .eq('Id', notificationId)
          .single();

      final notification = model.Notification.fromJson(response as Map<String, dynamic>);
      return Success(notification);
    } catch (e) {
      return Failure('Failed to fetch notification: $e');
    }
  }

  // Create new notification (Admin/Lecturer only)
  Future<Result<model.Notification>> createNotification({
    required String title,
    required String content,
    required String targetGroup,
    required String createdBy,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final notificationId = _uuid.v4(); // Generate UUID for notification
      
      final response = await _supabase
          .from('tbl_notifications')
          .insert({
            'Id': notificationId, // Add ID field
            'Title': title,
            'Content': content,
            'TargetGroup': targetGroup,
            'StartDate': (startDate ?? now).toIso8601String(),
            'EndDate': endDate?.toIso8601String(),
            'Status': 1,
            'CreatedBy': createdBy,
            'CreatedAt': now.toIso8601String(),
            'LastUpdatedAt': now.toIso8601String(),
          })
          .select()
          .single();

      final notification = model.Notification.fromJson(response as Map<String, dynamic>);
      return Success(notification);
    } catch (e) {
      return Failure('Failed to create notification: $e');
    }
  }

  // Update notification (Admin/Lecturer only)
  Future<Result<model.Notification>> updateNotification({
    required String notificationId,
    String? title,
    String? content,
    String? targetGroup,
    DateTime? startDate,
    DateTime? endDate,
    int? status,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'LastUpdatedAt': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['Title'] = title;
      if (content != null) updateData['Content'] = content;
      if (targetGroup != null) updateData['TargetGroup'] = targetGroup;
      if (startDate != null) updateData['StartDate'] = startDate.toIso8601String();
      if (endDate != null) updateData['EndDate'] = endDate.toIso8601String();
      if (status != null) updateData['Status'] = status;

      final response = await _supabase
          .from('tbl_notifications')
          .update(updateData)
          .eq('Id', notificationId)
          .select()
          .single();

      final notification = model.Notification.fromJson(response as Map<String, dynamic>);
      return Success(notification);
    } catch (e) {
      return Failure('Failed to update notification: $e');
    }
  }

  // Delete notification (Admin only)
  Future<Result<void>> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('tbl_notifications')
          .delete()
          .eq('Id', notificationId);

      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete notification: $e');
    }
  }

  // Mark notification as read for a user
  Future<Result<void>> markAsRead(String notificationId, String userId) async {
    try {
      final now = DateTime.now();
      
      // Check if already read
      final existing = await _supabase
          .from('tbl_notification_reads')
          .select('Id')
          .eq('NotificationId', notificationId)
          .eq('UserId', userId)
          .maybeSingle();

      if (existing == null) {
        // Insert new read record with UUID
        final readId = _uuid.v4();
        await _supabase.from('tbl_notification_reads').insert({
          'Id': readId,
          'NotificationId': notificationId,
          'UserId': userId,
          'ReadAt': now.toIso8601String(),
          'CreatedAt': now.toIso8601String(),
          'LastUpdatedAt': now.toIso8601String(),
        });
        debugPrint('✅ NotificationRepository: Marked notification as read');
        debugPrint('   Notification ID: $notificationId');
        debugPrint('   User ID: $userId');
        debugPrint('   Read ID: $readId');
      } else {
        // Update read timestamp
        await _supabase
            .from('tbl_notification_reads')
            .update({
              'ReadAt': now.toIso8601String(),
              'LastUpdatedAt': now.toIso8601String(),
            })
            .eq('NotificationId', notificationId)
            .eq('UserId', userId);
        debugPrint('✅ NotificationRepository: Updated read timestamp for notification');
        debugPrint('   Notification ID: $notificationId');
        debugPrint('   User ID: $userId');
      }

      return const Success(null);
    } catch (e) {
      debugPrint('❌ NotificationRepository: Failed to mark notification as read: $e');
      return Failure('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<Result<void>> markAllAsRead(String userId, List<String> notificationIds) async {
    try {
      final now = DateTime.now();
      int markedCount = 0;
      
      debugPrint('📚 NotificationRepository: Marking all notifications as read');
      debugPrint('   User ID: $userId');
      debugPrint('   Total notifications: ${notificationIds.length}');
      
      for (final notificationId in notificationIds) {
        final existing = await _supabase
            .from('tbl_notification_reads')
            .select('Id')
            .eq('NotificationId', notificationId)
            .eq('UserId', userId)
            .maybeSingle();

        if (existing == null) {
          // Insert new read record with UUID
          final readId = _uuid.v4();
          await _supabase.from('tbl_notification_reads').insert({
            'Id': readId,
            'NotificationId': notificationId,
            'UserId': userId,
            'ReadAt': now.toIso8601String(),
            'CreatedAt': now.toIso8601String(),
            'LastUpdatedAt': now.toIso8601String(),
          });
          markedCount++;
        }
      }

      debugPrint('✅ NotificationRepository: Marked $markedCount notifications as read');
      return const Success(null);
    } catch (e) {
      debugPrint('❌ NotificationRepository: Failed to mark all notifications as read: $e');
      return Failure('Failed to mark all notifications as read: $e');
    }
  }

  // Get unread count for a user
  Future<Result<int>> getUnreadCount(String userId, String userRole) async {
    try {
      final now = DateTime.now();
      
      // Get all active notifications for user's role
      final notifications = await _supabase
          .from('tbl_notifications')
          .select('Id')
          .eq('Status', 1)
          .or('TargetGroup.eq.all,TargetGroup.eq.$userRole')
          .lte('StartDate', now.toIso8601String())
          .or('EndDate.is.null,EndDate.gte.${now.toIso8601String()}');

      if (notifications.isEmpty) {
        return const Success(0);
      }

      final notificationIds = (notifications as List)
          .map((n) => n['Id'] as String)
          .toList();

      // Get read notifications for this user
      // Query each notification ID individually since Supabase may not support in_ for all cases
      final readIds = <String>{};
      for (final notificationId in notificationIds) {
        try {
          final readResponse = await _supabase
              .from('tbl_notification_reads')
              .select('NotificationId')
              .eq('UserId', userId)
              .eq('NotificationId', notificationId)
              .maybeSingle();
          
          if (readResponse != null) {
            readIds.add(notificationId);
          }
        } catch (e) {
          // Skip if error
          continue;
        }
      }

      final unreadCount = notificationIds.length - readIds.length;
      return Success(unreadCount);
    } catch (e) {
      return Failure('Failed to get unread count: $e');
    }
  }

  // Get notifications for user with read status
  Future<Result<List<Map<String, dynamic>>>> getNotificationsForUserWithReadStatus(
    String userId,
    String userRole,
  ) async {
    try {
      final now = DateTime.now();
      
      // Get all active notifications for user's role
      final notifications = await _supabase
          .from('tbl_notifications')
          .select()
          .eq('Status', 1)
          .or('TargetGroup.eq.all,TargetGroup.eq.$userRole')
          .lte('StartDate', now.toIso8601String())
          .or('EndDate.is.null,EndDate.gte.${now.toIso8601String()}')
          .order('CreatedAt', ascending: false);

      if (notifications.isEmpty) {
        return Success([]);
      }

      final notificationIds = (notifications as List)
          .map((n) => (n as Map<String, dynamic>)['Id'] as String)
          .toList();

      // Get read notifications for this user
      // Query each notification ID individually since Supabase may not support in_ for all cases
      final readMap = <String, DateTime>{};
      for (final notificationId in notificationIds) {
        try {
          final readResponse = await _supabase
              .from('tbl_notification_reads')
              .select('NotificationId, ReadAt')
              .eq('UserId', userId)
              .eq('NotificationId', notificationId)
              .maybeSingle();
          
          if (readResponse != null) {
            final readAt = DateTime.parse(readResponse['ReadAt'] as String);
            readMap[notificationId] = readAt;
          }
        } catch (e) {
          // Skip if error
          continue;
        }
      }

      // Combine notifications with read status
      final result = (notifications as List).map((notification) {
        final notificationMap = notification as Map<String, dynamic>;
        final notificationId = notificationMap['Id'] as String;
        return {
          ...notificationMap,
          'IsRead': readMap.containsKey(notificationId),
          'ReadAt': readMap[notificationId],
        };
      }).toList();

      return Success(result);
    } catch (e) {
      return Failure('Failed to get notifications with read status: $e');
    }
  }

}

// Provider for NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

