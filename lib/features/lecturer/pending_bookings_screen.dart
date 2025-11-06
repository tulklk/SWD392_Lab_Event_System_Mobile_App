import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/room.dart';
import '../../domain/models/user.dart';
import '../auth/auth_controller.dart';

final pendingBookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) async {
  try {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🚀 pendingBookingsProvider: STARTED');
    debugPrint('   Timestamp: ${DateTime.now().toIso8601String()}');
    debugPrint('═══════════════════════════════════════════════════════════');
    
    final bookingRepository = ref.watch(bookingRepositoryProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    debugPrint('📋 pendingBookingsProvider: Getting current user...');
    debugPrint('   Current user: ${currentUser?.id} (${currentUser?.name}), Role: ${currentUser?.role}');
    
    // Get lecturer ID if current user is lecturer
    final lecturerId = currentUser?.id;
    
    if (lecturerId == null) {
      debugPrint('⚠️ pendingBookingsProvider: No current user, returning empty list');
      return [];
    }
    
    debugPrint('🔍 pendingBookingsProvider: Calling getPendingBookings with lecturerId: $lecturerId');
    final result = await bookingRepository.getPendingBookings(lecturerId: lecturerId);
    
    if (result.isSuccess) {
      debugPrint('✅ pendingBookingsProvider: Success, returning ${result.data?.length ?? 0} bookings');
      if (result.data != null && result.data!.isNotEmpty) {
        for (final booking in result.data!) {
          debugPrint('   ✅ Booking: ${booking.id}, EventId: ${booking.eventId}, Purpose: ${booking.purpose}');
        }
      }
    } else {
      debugPrint('❌ pendingBookingsProvider: Failed: ${result.error}');
    }
    
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🏁 pendingBookingsProvider: COMPLETED');
    debugPrint('═══════════════════════════════════════════════════════════');
    
    return result.data ?? [];
  } catch (e, stackTrace) {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('💥 pendingBookingsProvider: EXCEPTION!');
    debugPrint('   Error: $e');
    debugPrint('   Stack trace: $stackTrace');
    debugPrint('═══════════════════════════════════════════════════════════');
    return [];
  }
});

class PendingBookingsScreen extends ConsumerWidget {
  const PendingBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🖥️ PendingBookingsScreen.build() CALLED');
    debugPrint('   Timestamp: ${DateTime.now().toIso8601String()}');
    debugPrint('═══════════════════════════════════════════════════════════');
    
    final pendingBookingsAsync = ref.watch(pendingBookingsProvider);
    
    debugPrint('📊 PendingBookingsScreen: Watching pendingBookingsProvider');

    return Scaffold(
      body: pendingBookingsAsync.when(
        data: (bookings) {
          debugPrint('📦 PendingBookingsScreen: Received data, ${bookings.length} bookings');
          
          if (bookings.isEmpty) {
            debugPrint('⚠️ PendingBookingsScreen: Bookings list is empty');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All caught up!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No pending bookings to review',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }
          
          debugPrint('✅ PendingBookingsScreen: Displaying ${bookings.length} bookings');

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pendingBookingsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _PendingBookingCard(
                  booking: booking,
                  onApprove: () async {
                    await _handleApprove(context, ref, booking.id);
                  },
                  onReject: () async {
                    await _handleReject(context, ref, booking.id);
                  },
                );
              },
            ),
          );
        },
        loading: () {
          debugPrint('⏳ PendingBookingsScreen: Loading state');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          debugPrint('❌ PendingBookingsScreen: Error state');
          debugPrint('   Error: $error');
          debugPrint('   Stack: $stack');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading bookings',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, WidgetRef ref, String bookingId) async {
    final bookingRepository = ref.read(bookingRepositoryProvider);
    final result = await bookingRepository.approveBooking(bookingId);

    if (context.mounted) {
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Booking approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(pendingBookingsProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to approve booking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref, String bookingId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Booking'),
        content: const Text('Are you sure you want to reject this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final bookingRepository = ref.read(bookingRepositoryProvider);
      final result = await bookingRepository.rejectBooking(bookingId);

      if (context.mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking rejected'),
              backgroundColor: Colors.orange,
            ),
          );
          ref.invalidate(pendingBookingsProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to reject booking'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _PendingBookingCard extends ConsumerWidget {
  final Booking booking;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingBookingCard({
    required this.booking,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pending_actions, size: 14, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Submitted ${_getTimeAgo(booking.createdAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Purpose
            Text(
              booking.purpose,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // User info
            FutureBuilder<User?>(
              future: _getUser(ref, booking.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6600), Color(0xFFFF8533)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Loading user...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                
                final user = snapshot.data;
                return Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6600), Color(0xFFFF8533)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          user?.fullname[0].toUpperCase() ?? 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullname ?? 'Unknown User',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            
            // Room info
            FutureBuilder<Room?>(
              future: _getRoom(ref, booking.roomId),
              builder: (context, snapshot) {
                final room = snapshot.data;
                return Row(
                  children: [
                    Icon(Icons.meeting_room, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        room?.name ?? 'Room ${booking.roomId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 8),
            
            // Date and time
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(booking.startTime),
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${timeFormat.format(booking.startTime)} - ${timeFormat.format(booking.endTime)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<User?> _getUser(WidgetRef ref, String userId) async {
    final userRepository = ref.read(userRepositoryProvider);
    final result = await userRepository.getUserById(userId);
    return result.data;
  }

  Future<Room?> _getRoom(WidgetRef ref, String roomId) async {
    final roomRepository = ref.read(roomRepositoryProvider);
    final result = await roomRepository.getRoomById(roomId);
    return result.data;
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}

