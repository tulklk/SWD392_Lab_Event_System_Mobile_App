import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/result.dart';
import '../../domain/models/notification.dart' as model;

class NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

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
      
      final response = await _supabase
          .from('tbl_notifications')
          .insert({
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

  // Mark notification as read (track in separate table if needed)
  Future<Result<void>> markAsRead(String notificationId, String userId) async {
    try {
      // If you have a notification_reads table, insert here
      // For now, we'll just return success
      return const Success(null);
    } catch (e) {
      return Failure('Failed to mark notification as read: $e');
    }
  }
}

// Provider for NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

