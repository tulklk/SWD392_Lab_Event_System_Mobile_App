import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/notification_repository.dart';
import '../../features/notifications/notification_providers.dart';

/// Service to handle realtime notification updates using Supabase Realtime
/// Uses reference counting to support multiple screens
class NotificationRealtimeService {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  int _referenceCount = 0;
  WidgetRef? _currentRef;

  /// Start listening to notification changes
  /// This will automatically refresh notifications when new ones are created
  /// Uses reference counting - multiple screens can call this, listener will only stop when all screens are closed
  void startListening(WidgetRef ref) {
    _referenceCount++;
    _currentRef = ref;
    
    if (_referenceCount == 1) {
      // First reference - start listening
      try {
        debugPrint('🔔 NotificationRealtimeService: Starting realtime listener...');
        debugPrint('   Reference count: $_referenceCount');
        
        // Subscribe to INSERT events on tbl_notifications table
        _channel = _supabase
            .channel('notifications')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'tbl_notifications',
              callback: (payload) {
                debugPrint('📨 NotificationRealtimeService: New notification received');
                debugPrint('   Payload: ${payload.newRecord}');
                
                // Auto refresh notifications when new notification is created
                // Use currentRef if available, otherwise try to get from callback context
                if (_currentRef != null) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    try {
                      refreshNotifications(_currentRef!);
                      debugPrint('✅ NotificationRealtimeService: Notifications refreshed');
                    } catch (e) {
                      debugPrint('⚠️ NotificationRealtimeService: Failed to refresh (ref may be invalid): $e');
                    }
                  });
                }
              },
            )
            .subscribe();

        debugPrint('✅ NotificationRealtimeService: Realtime listener started');
      } catch (e) {
        debugPrint('❌ NotificationRealtimeService: Failed to start listener: $e');
        _referenceCount = 0;
        _currentRef = null;
      }
    } else {
      debugPrint('ℹ️ NotificationRealtimeService: Already listening (reference count: $_referenceCount)');
    }
  }

  /// Stop listening to notification changes
  /// Uses reference counting - listener will only stop when all screens are closed
  void stopListening() {
    if (_referenceCount == 0) {
      return;
    }

    _referenceCount--;
    debugPrint('🔕 NotificationRealtimeService: Stop requested (reference count: $_referenceCount)');

    if (_referenceCount == 0) {
      // Last reference - stop listening
      try {
        debugPrint('🔕 NotificationRealtimeService: Stopping realtime listener...');
        _channel?.unsubscribe();
        _channel = null;
        _currentRef = null;
        debugPrint('✅ NotificationRealtimeService: Realtime listener stopped');
      } catch (e) {
        debugPrint('❌ NotificationRealtimeService: Failed to stop listener: $e');
      }
    }
  }

  /// Check if currently listening
  bool get isListening => _referenceCount > 0;
}

// Provider for NotificationRealtimeService
final notificationRealtimeServiceProvider = Provider<NotificationRealtimeService>((ref) {
  return NotificationRealtimeService();
});

