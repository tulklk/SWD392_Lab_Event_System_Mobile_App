import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/supabase_config.dart';
import '../../domain/models/booking.dart';
import '../../core/utils/result.dart';
import '../services/notification_service.dart';
import '../services/fcm_service.dart';
import '../repositories/event_repository.dart';
import '../repositories/user_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

class BookingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // No need for init with Supabase
  Future<void> init() async {
    // Empty - kept for compatibility
  }

  // Create new booking
  Future<Result<Booking>> createBooking({
    String? eventId,
    required String roomId,
    required String userId,
    required String purpose,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final bookingId = _uuid.v4(); // Generate UUID
      
      final response = await _supabase
          .from('tbl_bookings')
          .insert({
            'Id': bookingId,
            'UserId': userId,
            'RoomId': roomId,
            'StartTime': startTime.toIso8601String(),
            'EndTime': endTime.toIso8601String(),
            'Purpose': purpose,
            'Status': 0, // pending
            'Notes': notes,
            'EventId': eventId,
            'CreatedAt': now.toIso8601String(),
            'LastUpdatedAt': now.toIso8601String(),
          })
          .select()
          .single();

      final booking = Booking.fromJson(response as Map<String, dynamic>);
      return Success(booking);
    } catch (e) {
      return Failure('Failed to create booking: $e');
    }
  }

  // Get booking by ID
  Future<Result<Booking?>> getBookingById(String id) async {
    try {
      final response = await _supabase
          .from('tbl_bookings')
          .select()
          .eq('Id', id)
          .maybeSingle();

      if (response == null) {
        return const Success(null);
      }

      final booking = Booking.fromJson(response as Map<String, dynamic>);
      return Success(booking);
    } catch (e) {
      return Failure('Failed to get booking: $e');
    }
  }

  // Get all bookings
  Future<Result<List<Booking>>> getAllBookings() async {
    try {
      final response = await _supabase
          .from('tbl_bookings')
          .select()
          .order('CreatedAt', ascending: false);

      final bookings = (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(bookings);
    } catch (e) {
      return Failure('Failed to get all bookings: $e');
    }
  }

  // Get bookings for specific user
  Future<Result<List<Booking>>> getBookingsForUser(String userId) async {
    try {
      final response = await _supabase
          .from('tbl_bookings')
          .select()
          .eq('UserId', userId)
          .order('StartTime', ascending: false);

      final bookings = (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(bookings);
    } catch (e) {
      return Failure('Failed to get bookings for user: $e');
    }
  }

  // Get bookings for specific room
  Future<Result<List<Booking>>> getBookingsForLab(String roomId) async {
    try {
      final response = await _supabase
          .from('tbl_bookings')
          .select()
          .eq('RoomId', roomId)
          .order('StartTime', ascending: false);

      final bookings = (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(bookings);
    } catch (e) {
      return Failure('Failed to get bookings for room: $e');
    }
  }

  // Get bookings for specific date
  Future<Result<List<Booking>>> getBookingsForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('tbl_bookings')
          .select()
          .gte('StartTime', startOfDay.toIso8601String())
          .lt('StartTime', endOfDay.toIso8601String())
          .order('StartTime', ascending: true);

      final bookings = (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(bookings);
    } catch (e) {
      return Failure('Failed to get bookings for date: $e');
    }
  }

  // Check if there's a booking conflict
  Future<Result<bool>> hasConflict(
    String roomId,
    DateTime date,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get all bookings for this room on this date that are not cancelled or rejected
      final response = await _supabase
          .from('tbl_bookings')
          .select()
          .eq('RoomId', roomId)
          .gte('StartTime', startOfDay.toIso8601String())
          .lt('StartTime', endOfDay.toIso8601String())
          .neq('Status', 3) // not cancelled
          .neq('Status', 2); // not rejected

      final bookings = (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();

      // Check for overlapping bookings
      for (final booking in bookings) {
        if (start.isBefore(booking.endTime) && end.isAfter(booking.startTime)) {
          return const Success(true);
        }
      }

      return const Success(false);
    } catch (e) {
      return Failure('Failed to check conflict: $e');
    }
  }

  // Update booking
  Future<Result<Booking>> updateBooking(Booking booking) async {
    try {
      final response = await _supabase
          .from('tbl_bookings')
          .update(booking.toJson())
          .eq('Id', booking.id)
          .select()
          .single();

      final updatedBooking = Booking.fromJson(response as Map<String, dynamic>);
      return Success(updatedBooking);
    } catch (e) {
      return Failure('Failed to update booking: $e');
    }
  }

  // Cancel booking
  Future<Result<void>> cancelBooking(String id) async {
    try {
      await _supabase
          .from('tbl_bookings')
          .update({
            'Status': 3, // cancelled
            'LastUpdatedAt': DateTime.now().toIso8601String(),
          })
          .eq('Id', id);

      return const Success(null);
    } catch (e) {
      return Failure('Failed to cancel booking: $e');
    }
  }

  // Approve booking (Lecturer/Admin only)
  Future<Result<void>> approveBooking(String id) async {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🚀 BookingRepository.approveBooking() CALLED');
    debugPrint('   Booking ID: $id');
    debugPrint('   Timestamp: ${DateTime.now().toIso8601String()}');
    debugPrint('═══════════════════════════════════════════════════════════');
    
    try {
      debugPrint('✅ Step 1: Approving booking: $id');
      
      // Update booking status
      await _supabase
          .from('tbl_bookings')
          .update({
            'Status': 1, // approved
            'LastUpdatedAt': DateTime.now().toIso8601String(),
          })
          .eq('Id', id);

      debugPrint('✅ Step 2: Booking approved successfully in database');
      debugPrint('   Status updated to: Approved (1)');
      
      // Send notification to student about approval
      debugPrint('');
      debugPrint('📤 Step 3: Preparing to send notification to student...');
      try {
        final notificationService = NotificationService();
        final eventRepository = EventRepository();
        
        // Get booking to find student and event
        debugPrint('🔍 BookingRepository: Fetching booking details for ID: $id');
        final bookingResult = await getBookingById(id);
        
        if (!bookingResult.isSuccess) {
          debugPrint('❌ BookingRepository: Failed to get booking: ${bookingResult.error}');
        } else if (bookingResult.data == null) {
          debugPrint('❌ BookingRepository: Booking not found with ID: $id');
        } else {
          final booking = bookingResult.data!;
          final studentId = booking.userId;
          final eventId = booking.eventId;
          
          debugPrint('📋 BookingRepository: Booking details found');
          debugPrint('   Student ID: $studentId');
          debugPrint('   Event ID: $eventId');
          
          if (eventId != null && eventId.isNotEmpty) {
            // This is an event booking - get event title
            debugPrint('🔍 BookingRepository: Fetching event details for ID: $eventId');
            final eventResult = await eventRepository.getEventById(eventId);
            
            if (!eventResult.isSuccess) {
              debugPrint('❌ BookingRepository: Failed to get event: ${eventResult.error}');
            } else if (eventResult.data == null) {
              debugPrint('❌ BookingRepository: Event not found');
            } else {
              final eventTitle = eventResult.data!.title;
              debugPrint('✅ BookingRepository: Event found - "$eventTitle"');
              
              // Send notification to student
              debugPrint('📤 BookingRepository: Sending notification to student...');
              final notificationResult = await notificationService.notifyStudentOfApproval(
                studentId: studentId,
                eventTitle: eventTitle,
                bookingId: id,
              );
              
              if (notificationResult) {
                debugPrint('✅ BookingRepository: Notification sent successfully to student: $studentId');
              } else {
                debugPrint('❌ BookingRepository: Failed to send notification to student: $studentId');
                debugPrint('   Possible reasons:');
                debugPrint('   1. Student has not logged in and initialized FCM');
                debugPrint('   2. Student has not granted notification permissions');
                debugPrint('   3. FCM token not found in database');
                debugPrint('   4. FCM Service Account authentication failed');
              }
            }
          } else {
            // This is a lab booking (not event booking) - use purpose as title
            final purpose = booking.purpose ?? 'lab booking';
            debugPrint('📋 BookingRepository: This is a lab booking (not event)');
            debugPrint('   Purpose: $purpose');
            
            // Send notification to student with lab booking info
            debugPrint('📤 BookingRepository: Sending notification to student for lab booking...');
            final notificationResult = await notificationService.sendNotificationToUser(
              userId: studentId,
              title: 'Booking Approved',
              body: 'Lịch booking của bạn cho "$purpose" đã thành công!',
              targetGroup: 'student',
              data: {
                'type': 'booking_approved',
                'bookingId': id,
                'purpose': purpose,
              },
            );
            
            if (notificationResult) {
              debugPrint('✅ BookingRepository: Notification sent successfully to student: $studentId');
            } else {
              debugPrint('❌ BookingRepository: Failed to send notification to student: $studentId');
            }
          }
        }
      } catch (e, stackTrace) {
        debugPrint('❌ BookingRepository: Exception while sending notification: $e');
        debugPrint('   Stack trace: $stackTrace');
        // Don't fail approval if notification fails
      }
      
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('✅ BookingRepository.approveBooking() COMPLETED SUCCESSFULLY');
      debugPrint('   Booking ID: $id');
      debugPrint('   Timestamp: ${DateTime.now().toIso8601String()}');
      debugPrint('═══════════════════════════════════════════════════════════');
      
      return const Success(null);
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('❌ BookingRepository.approveBooking() FAILED');
      debugPrint('   Booking ID: $id');
      debugPrint('   Error: $e');
      debugPrint('   Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════════');
      
      return Failure('Failed to approve booking: $e');
    }
  }

  // Reject booking (Lecturer/Admin only)
  Future<Result<void>> rejectBooking(String id) async {
    try {
      await _supabase
          .from('tbl_bookings')
          .update({
            'Status': 2, // rejected
            'LastUpdatedAt': DateTime.now().toIso8601String(),
          })
          .eq('Id', id);

      return const Success(null);
    } catch (e) {
      return Failure('Failed to reject booking: $e');
    }
  }

  // Delete booking (hard delete)
  Future<Result<void>> deleteBooking(String id) async {
    try {
      await _supabase
          .from('tbl_bookings')
          .delete()
          .eq('Id', id);

      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete booking: $e');
    }
  }

  // Get pending bookings (for Lecturer/Admin review)
  Future<Result<List<Booking>>> getPendingBookings() async {
    try {
      final response = await _supabase
          .from('tbl_bookings')
          .select()
          .eq('Status', 0) // pending
          .order('CreatedAt', ascending: false);

      final bookings = (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(bookings);
    } catch (e) {
      return Failure('Failed to get pending bookings: $e');
    }
  }

  // Get upcoming bookings for a user
  Future<Result<List<Booking>>> getUpcomingBookingsForUser(String userId) async {
    try {
      final now = DateTime.now();
      
      final response = await _supabase
          .from('tbl_bookings')
          .select()
          .eq('UserId', userId)
          .gte('StartTime', now.toIso8601String())
          .order('StartTime', ascending: true);

      final bookings = (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(bookings);
    } catch (e) {
      return Failure('Failed to get upcoming bookings: $e');
    }
  }

  // Get past bookings for a user
  Future<Result<List<Booking>>> getPastBookingsForUser(String userId) async {
    try {
      final now = DateTime.now();
      
      final response = await _supabase
          .from('tbl_bookings')
          .select()
          .eq('UserId', userId)
          .lt('EndTime', now.toIso8601String())
          .order('StartTime', ascending: false);

      final bookings = (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(bookings);
    } catch (e) {
      return Failure('Failed to get past bookings: $e');
    }
  }

  // Check if user already booked an event
  Future<Result<bool>> hasUserBookedEvent(String eventId, String userId) async {
    try {
      final response = await _supabase
          .from('tbl_bookings')
          .select()
          .eq('EventId', eventId)
          .eq('UserId', userId)
          .maybeSingle();

      return Success(response != null);
    } catch (e) {
      return Failure('Failed to check event booking: $e');
    }
  }

  // Get bookings for an event (to check capacity)
  Future<Result<List<Booking>>> getBookingsForEvent(String eventId) async {
    try {
      final response = await _supabase
          .from('tbl_bookings')
          .select()
          .eq('EventId', eventId)
          .order('CreatedAt', ascending: false);

      final bookings = (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(bookings);
    } catch (e) {
      return Failure('Failed to get bookings for event: $e');
    }
  }

  // Create booking for an event
  Future<Result<Booking>> createEventBooking({
    required String eventId,
    required String roomId,
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final bookingId = _uuid.v4();
      
      final response = await _supabase
          .from('tbl_bookings')
          .insert({
            'Id': bookingId,
            'UserId': userId,
            'RoomId': roomId,
            'EventId': eventId,
            'StartTime': startTime.toIso8601String(),
            'EndTime': endTime.toIso8601String(),
            'Purpose': 'Event Registration',
            'Status': 0, // pending
            'Notes': notes,
            'CreatedAt': now.toIso8601String(),
            'LastUpdatedAt': now.toIso8601String(),
          })
          .select()
          .single();

      final booking = Booking.fromJson(response as Map<String, dynamic>);
      
      // Send notification to lecturer about new booking
      debugPrint('📨 BookingRepository: Attempting to send notification to lecturer');
      try {
        final eventRepository = EventRepository();
        final userRepository = UserRepository();
        final notificationService = NotificationService();
        
        // Get event details to find lecturer
        debugPrint('🔍 BookingRepository: Getting event details for eventId: $eventId');
        final eventResult = await eventRepository.getEventById(eventId);
        
        if (eventResult.isSuccess && eventResult.data != null) {
          final event = eventResult.data!;
          final lecturerId = event.createdBy;
          
          debugPrint('✅ BookingRepository: Found event: ${event.title}');
          debugPrint('   Lecturer ID (event.createdBy): $lecturerId');
          
          // Get student name
          debugPrint('🔍 BookingRepository: Getting student details for userId: $userId');
          final studentResult = await userRepository.getUserById(userId);
          final studentName = studentResult.isSuccess && studentResult.data != null
              ? (studentResult.data!.fullname ?? 'A student')
              : 'A student';
          
          debugPrint('✅ BookingRepository: Student name: $studentName');
          
          // Send notification to lecturer
          debugPrint('📤 BookingRepository: Sending notification to lecturer...');
          final notificationResult = await notificationService.notifyLecturerOfBooking(
            lecturerId: lecturerId,
            studentName: studentName,
            eventTitle: event.title,
            bookingId: bookingId,
          );
          
          if (notificationResult) {
            debugPrint('✅ BookingRepository: Notification sent successfully to lecturer: $lecturerId');
          } else {
            debugPrint('⚠️ BookingRepository: Failed to send notification to lecturer: $lecturerId');
            debugPrint('   This could be because:');
            debugPrint('   1. Lecturer has not logged in and initialized FCM');
            debugPrint('   2. Lecturer has not granted notification permissions');
            debugPrint('   3. FCM Service Account authentication failed');
            debugPrint('   4. No FCM token found in tbl_fcm_tokens for lecturer');
          }
        } else {
          debugPrint('❌ BookingRepository: Failed to get event details: ${eventResult.error}');
        }
      } catch (e, stackTrace) {
        debugPrint('❌ BookingRepository: Error sending notification (booking still created): $e');
        debugPrint('   Stack trace: $stackTrace');
        // Don't fail booking creation if notification fails
      }
      
      return Success(booking);
    } catch (e) {
      return Failure('Failed to create event booking: $e');
    }
  }
}
