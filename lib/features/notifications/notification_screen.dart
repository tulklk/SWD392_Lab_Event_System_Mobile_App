import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/notification.dart' as app_models;
import 'notification_providers.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/notification_realtime_service.dart';
import '../auth/auth_controller.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure realtime listener is active when notification screen is opened
    // The listener is already started from LecturerDashboardScreen, but we ensure it's active here too
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final realtimeService = ref.read(notificationRealtimeServiceProvider);
      if (!realtimeService.isListening) {
        realtimeService.startListening(ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final refreshTrigger = ref.watch(notificationRefreshProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          notificationsAsync.when(
            data: (notifications) {
              final unreadCount = notifications.where((n) => !(n['IsRead'] as bool? ?? false)).length;
              if (unreadCount == 0) return const SizedBox.shrink();
              
              return TextButton.icon(
                onPressed: () async {
                  final currentUser = ref.read(currentUserProvider);
                  if (currentUser == null) return;
                  
                  final repository = ref.read(notificationRepositoryProvider);
                  final notificationIds = notifications
                      .map((n) => n['Id'] as String)
                      .toList();
                  await repository.markAllAsRead(currentUser.id, notificationIds);
                  refreshNotifications(ref);
                },
                icon: const Icon(Icons.done_all, size: 18),
                label: Text('Mark all read ($unreadCount)'),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              refreshNotifications(ref);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notificationData = notifications[index];
                final notification = app_models.Notification.fromJson(notificationData);
                final isRead = notificationData['IsRead'] as bool? ?? false;
                
                return _NotificationCard(
                  notification: notification,
                  isRead: isRead,
                  onTap: () async {
                    // Mark as read when tapped
                    if (!isRead) {
                      final currentUser = ref.read(currentUserProvider);
                      if (currentUser != null) {
                        final repository = ref.read(notificationRepositoryProvider);
                        await repository.markAsRead(notification.id, currentUser.id);
                        refreshNotifications(ref);
                      }
                    }
                    
                    // Handle navigation based on notification type
                    _handleNotificationTap(context, notification);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load notifications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => refreshNotifications(ref),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, app_models.Notification notification) {
    // Navigate based on notification type
    final type = getNotificationType(notification.content, title: notification.title);
    switch (type) {
      case 'booking_created':
      case 'booking_approved':
      case 'booking_rejected':
        // TODO: Navigate to booking detail screen if needed
        break;
      default:
        // Show notification details
        break;
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final app_models.Notification notification;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !isRead;
    final timeAgo = _getTimeAgo(notification.createdAt);
    final notificationType = getNotificationType(notification.content, title: notification.title);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnread ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUnread
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unread indicator
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(width: 20),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Icon based on type
              _getIconForType(notificationType),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getIconForType(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'booking_created':
        icon = Icons.add_circle_outline;
        color = Colors.orange;
        break;
      case 'booking_approved':
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case 'booking_rejected':
        icon = Icons.cancel_outlined;
        color = Colors.red;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

