import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/models/notification.dart';
import '../auth/auth_controller.dart';
import '../../core/utils/result.dart';
import '../../domain/enums/role.dart';

/// Provider for unread notification count
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return 0;

  final repository = ref.watch(notificationRepositoryProvider);
  final userRole = currentUser.role.name.toLowerCase(); // 'student', 'lecturer', 'admin'
  final result = await repository.getUnreadCount(currentUser.id, userRole);
  
  if (result.isSuccess) {
    return result.data ?? 0;
  } else {
    return 0;
  }
});

/// Provider for all notifications with read status
final userNotificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];

  final repository = ref.watch(notificationRepositoryProvider);
  final userRole = currentUser.role.name.toLowerCase(); // 'student', 'lecturer', 'admin'
  final result = await repository.getNotificationsForUserWithReadStatus(
    currentUser.id,
    userRole,
  );
  
  if (result.isSuccess) {
    return result.data ?? [];
  } else {
    return [];
  }
});

/// Provider to refresh notifications
class NotificationRefreshNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }
  
  void refresh() {
    state = state + 1;
  }
}

final notificationRefreshProvider = NotifierProvider<NotificationRefreshNotifier, int>(() {
  return NotificationRefreshNotifier();
});

/// Helper function to refresh notifications
void refreshNotifications(WidgetRef ref) {
  ref.read(notificationRefreshProvider.notifier).refresh();
  ref.invalidate(unreadNotificationCountProvider);
  ref.invalidate(userNotificationsProvider);
}

/// Helper to get notification type from content
String getNotificationType(String content) {
  if (content.toLowerCase().contains('registered') || 
      content.toLowerCase().contains('booking')) {
    return 'booking_created';
  } else if (content.toLowerCase().contains('approved')) {
    return 'booking_approved';
  } else if (content.toLowerCase().contains('rejected')) {
    return 'booking_rejected';
  }
  return 'general';
}

