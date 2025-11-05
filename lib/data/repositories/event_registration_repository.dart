import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/result.dart';
import '../../domain/models/event_registration.dart';
import '../../domain/models/booking.dart';
import '../services/notification_service.dart';
import '../repositories/event_repository.dart';
import 'dart:math';

final eventRegistrationRepositoryProvider = Provider<EventRegistrationRepository>((ref) {
  return EventRegistrationRepository();
});

class EventRegistrationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  final _random = Random();

  // No need for init with Supabase
  Future<void> init() async {
    // Empty - kept for compatibility
  }

  // Create new event registration
  Future<Result<EventRegistration>> createRegistration({
    required String eventId,
    required String userId,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final registrationId = _uuid.v4();

      final response = await _supabase
          .from('tbl_event_registrations')
          .insert({
            'Id': registrationId,
            'EventId': eventId,
            'UserId': userId,
            'Status': 0, // pending
            'Notes': notes,
            'CreatedAt': now.toIso8601String(),
            'LastUpdatedAt': now.toIso8601String(),
          })
          .select()
          .single();

      final registration = EventRegistration.fromJson(response as Map<String, dynamic>);
      return Success(registration);
    } catch (e) {
      return Failure('Failed to create registration: $e');
    }
  }

  // Get all registrations for an event
  // Note: Event registrations are stored in tbl_bookings with EventId
  Future<Result<List<EventRegistration>>> getRegistrationsForEvent(String eventId) async {
    try {
      debugPrint('🔍 Getting registrations for event: $eventId');
      
      // Query from tbl_bookings where EventId matches
      final response = await _supabase
          .from('tbl_bookings')
          .select()
          .eq('EventId', eventId)
          .order('CreatedAt', ascending: false);

      if (response == null || response.isEmpty) {
        debugPrint('⚠️ No bookings found for event: $eventId');
        return Success(<EventRegistration>[]);
      }

      debugPrint('✅ Found ${response.length} bookings for event: $eventId');

      // Convert Booking to EventRegistration
      final registrations = (response as List)
          .map((json) => _bookingToEventRegistration(json as Map<String, dynamic>))
          .toList();

      return Success(registrations);
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting registrations: $e');
      debugPrint('Stack trace: $stackTrace');
      return Failure('Failed to get registrations: $e');
    }
  }

  // Helper: Convert Booking JSON to EventRegistration
  EventRegistration _bookingToEventRegistration(Map<String, dynamic> bookingJson) {
    return EventRegistration(
      id: bookingJson['Id']?.toString() ?? '',
      eventId: bookingJson['EventId']?.toString() ?? '',
      userId: bookingJson['UserId']?.toString() ?? '',
      status: bookingJson['Status'] as int? ?? 0,
      notes: bookingJson['Notes']?.toString(),
      createdAt: bookingJson['CreatedAt'] != null
          ? DateTime.parse(bookingJson['CreatedAt'].toString())
          : DateTime.now(),
      lastUpdatedAt: bookingJson['LastUpdatedAt'] != null
          ? DateTime.parse(bookingJson['LastUpdatedAt'].toString())
          : DateTime.now(),
      attendanceCode: bookingJson['AttendanceCode']?.toString(), // May be null if column doesn't exist
    );
  }

  // Get pending registrations for an event
  // Note: Event registrations are stored in tbl_bookings with EventId
  Future<Result<List<EventRegistration>>> getPendingRegistrationsForEvent(String eventId) async {
    try {
      debugPrint('🔍 Getting pending registrations for event: $eventId');
      
      // Query from tbl_bookings where EventId matches and Status is pending
      final response = await _supabase
          .from('tbl_bookings')
          .select()
          .eq('EventId', eventId)
          .eq('Status', 0) // pending
          .order('CreatedAt', ascending: false);

      if (response == null || response.isEmpty) {
        debugPrint('⚠️ No pending bookings found for event: $eventId');
        return Success(<EventRegistration>[]);
      }

      debugPrint('✅ Found ${response.length} pending bookings for event: $eventId');

      // Convert Booking to EventRegistration
      final registrations = (response as List)
          .map((json) => _bookingToEventRegistration(json as Map<String, dynamic>))
          .toList();

      return Success(registrations);
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting pending registrations: $e');
      debugPrint('Stack trace: $stackTrace');
      return Failure('Failed to get pending registrations: $e');
    }
  }

  // Approve registration
  // Note: Updates booking in tbl_bookings
  Future<Result<void>> approveRegistration(String id) async {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🚀 EventRegistrationRepository.approveRegistration() CALLED');
    debugPrint('   Booking/Registration ID: $id');
    debugPrint('   Timestamp: ${DateTime.now().toIso8601String()}');
    debugPrint('═══════════════════════════════════════════════════════════');
    
    try {
      debugPrint('✅ Step 1: Approving registration/booking: $id');
      
      // Generate attendance code (6-digit)
      final attendanceCode = _generateAttendanceCode();

      // Update booking in tbl_bookings
      // Note: AttendanceCode may not exist in tbl_bookings schema, so we'll try to update it
      // If it fails, we'll just update Status without AttendanceCode
      try {
        await _supabase
            .from('tbl_bookings')
            .update({
              'Status': 1, // approved
              'AttendanceCode': attendanceCode,
              'LastUpdatedAt': DateTime.now().toIso8601String(),
            })
            .eq('Id', id);
      } catch (e) {
        // If AttendanceCode column doesn't exist, update without it
        debugPrint('⚠️ AttendanceCode column may not exist, updating without it: $e');
        await _supabase
            .from('tbl_bookings')
            .update({
              'Status': 1, // approved
              'LastUpdatedAt': DateTime.now().toIso8601String(),
            })
            .eq('Id', id);
      }

      debugPrint('✅ Step 2: Registration approved successfully in database');
      debugPrint('   Status updated to: Approved (1)');
      debugPrint('   Attendance Code: $attendanceCode');
      
      // Send notification to student about approval
      debugPrint('');
      debugPrint('📤 Step 3: Preparing to send notification to student...');
      try {
        final notificationService = NotificationService();
        final eventRepository = EventRepository();
        
        // Get booking to find student and event
        debugPrint('🔍 EventRegistrationRepository: Fetching booking details for ID: $id');
        final bookingResult = await _supabase
            .from('tbl_bookings')
            .select('UserId, EventId')
            .eq('Id', id)
            .maybeSingle();
        
        if (bookingResult == null) {
          debugPrint('❌ EventRegistrationRepository: Booking not found with ID: $id');
        } else {
          final studentId = bookingResult['UserId'] as String?;
          final eventId = bookingResult['EventId'] as String?;
          
          debugPrint('📋 EventRegistrationRepository: Booking details found');
          debugPrint('   Student ID: $studentId');
          debugPrint('   Event ID: $eventId');
          
          if (studentId == null || eventId == null) {
            debugPrint('❌ EventRegistrationRepository: Missing studentId or eventId');
            debugPrint('   studentId is null: ${studentId == null}');
            debugPrint('   eventId is null: ${eventId == null}');
          } else {
            // Get event title
            debugPrint('🔍 EventRegistrationRepository: Fetching event details for ID: $eventId');
            final eventResult = await eventRepository.getEventById(eventId);
            
            if (!eventResult.isSuccess) {
              debugPrint('❌ EventRegistrationRepository: Failed to get event: ${eventResult.error}');
            } else if (eventResult.data == null) {
              debugPrint('❌ EventRegistrationRepository: Event not found');
            } else {
              final eventTitle = eventResult.data!.title;
              debugPrint('✅ EventRegistrationRepository: Event found - "$eventTitle"');
              
              // Send notification to student
              debugPrint('📤 EventRegistrationRepository: Sending notification to student...');
              final notificationResult = await notificationService.notifyStudentOfApproval(
                studentId: studentId,
                eventTitle: eventTitle,
                bookingId: id,
              );
              
              if (notificationResult) {
                debugPrint('✅ EventRegistrationRepository: Notification sent successfully to student: $studentId');
              } else {
                debugPrint('❌ EventRegistrationRepository: Failed to send notification to student: $studentId');
                debugPrint('   Possible reasons:');
                debugPrint('   1. Student has not logged in and initialized FCM');
                debugPrint('   2. Student has not granted notification permissions');
                debugPrint('   3. FCM token not found in database');
                debugPrint('   4. FCM Service Account authentication failed');
              }
            }
          }
        }
      } catch (e, stackTrace) {
        debugPrint('❌ EventRegistrationRepository: Exception while sending notification: $e');
        debugPrint('   Stack trace: $stackTrace');
        // Don't fail approval if notification fails
      }
      
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('✅ EventRegistrationRepository.approveRegistration() COMPLETED SUCCESSFULLY');
      debugPrint('   Booking ID: $id');
      debugPrint('   Timestamp: ${DateTime.now().toIso8601String()}');
      debugPrint('═══════════════════════════════════════════════════════════');
      
      return const Success(null);
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('❌ EventRegistrationRepository.approveRegistration() FAILED');
      debugPrint('   Booking ID: $id');
      debugPrint('   Error: $e');
      debugPrint('   Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════════');
      
      return Failure('Failed to approve registration: $e');
    }
  }

  // Bulk approve registrations
  // Note: Updates bookings in tbl_bookings
  Future<Result<void>> bulkApproveRegistrations(List<String> ids) async {
    try {
      debugPrint('✅ Bulk approving ${ids.length} registrations/bookings');
      
      for (final id in ids) {
        final attendanceCode = _generateAttendanceCode();
        
        // Update booking in tbl_bookings
        try {
          await _supabase
              .from('tbl_bookings')
              .update({
                'Status': 1,
                'AttendanceCode': attendanceCode,
                'LastUpdatedAt': DateTime.now().toIso8601String(),
              })
              .eq('Id', id);
        } catch (e) {
          // If AttendanceCode column doesn't exist, update without it
          await _supabase
              .from('tbl_bookings')
              .update({
                'Status': 1,
                'LastUpdatedAt': DateTime.now().toIso8601String(),
              })
              .eq('Id', id);
        }
      }

      debugPrint('✅ Bulk approval completed successfully');
      return const Success(null);
    } catch (e, stackTrace) {
      debugPrint('❌ Error bulk approving registrations: $e');
      debugPrint('Stack trace: $stackTrace');
      return Failure('Failed to bulk approve registrations: $e');
    }
  }

  // Reject registration
  // Note: Updates booking in tbl_bookings
  Future<Result<void>> rejectRegistration(String id) async {
    try {
      debugPrint('❌ Rejecting registration/booking: $id');
      
      // Update booking in tbl_bookings
      await _supabase
          .from('tbl_bookings')
          .update({
            'Status': 2, // rejected
            'LastUpdatedAt': DateTime.now().toIso8601String(),
          })
          .eq('Id', id);

      debugPrint('✅ Registration rejected successfully');
      
      // Send notification to student about rejection
      try {
        final notificationService = NotificationService();
        final eventRepository = EventRepository();
        
        // Get booking to find student and event
        final bookingResult = await _supabase
            .from('tbl_bookings')
            .select('UserId, EventId')
            .eq('Id', id)
            .maybeSingle();
        
        if (bookingResult != null) {
          final studentId = bookingResult['UserId'] as String?;
          final eventId = bookingResult['EventId'] as String?;
          
          if (studentId != null && eventId != null) {
            // Get event title
            final eventResult = await eventRepository.getEventById(eventId);
            if (eventResult.isSuccess && eventResult.data != null) {
              final eventTitle = eventResult.data!.title;
              
              // Send notification to student
              await notificationService.notifyStudentOfRejection(
                studentId: studentId,
                eventTitle: eventTitle,
                bookingId: id,
              );
              
              debugPrint('✅ Notification sent to student: $studentId');
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Failed to send notification (rejection still successful): $e');
        // Don't fail rejection if notification fails
      }
      
      return const Success(null);
    } catch (e, stackTrace) {
      debugPrint('❌ Error rejecting registration: $e');
      debugPrint('Stack trace: $stackTrace');
      return Failure('Failed to reject registration: $e');
    }
  }

  // Delete registration
  // Note: Deletes booking from tbl_bookings
  Future<Result<void>> deleteRegistration(String id) async {
    try {
      debugPrint('🗑️ Deleting registration/booking: $id');
      
      await _supabase
          .from('tbl_bookings')
          .delete()
          .eq('Id', id);

      debugPrint('✅ Registration deleted successfully');
      return const Success(null);
    } catch (e, stackTrace) {
      debugPrint('❌ Error deleting registration: $e');
      debugPrint('Stack trace: $stackTrace');
      return Failure('Failed to delete registration: $e');
    }
  }

  // Get registration by ID
  // Note: Queries from tbl_bookings
  Future<Result<EventRegistration?>> getRegistrationById(String id) async {
    try {
      debugPrint('🔍 Getting registration by ID: $id');
      
      final response = await _supabase
          .from('tbl_bookings')
          .select()
          .eq('Id', id)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ No booking found with ID: $id');
        return const Success(null);
      }

      final registration = _bookingToEventRegistration(response as Map<String, dynamic>);
      debugPrint('✅ Found registration: ${registration.id}');
      return Success(registration);
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting registration: $e');
      debugPrint('Stack trace: $stackTrace');
      return Failure('Failed to get registration: $e');
    }
  }

  // Check if user already registered for event
  // Note: Queries from tbl_bookings
  Future<Result<bool>> hasUserRegistered(String eventId, String userId) async {
    try {
      debugPrint('🔍 Checking if user $userId registered for event $eventId');
      
      final response = await _supabase
          .from('tbl_bookings')
          .select()
          .eq('EventId', eventId)
          .eq('UserId', userId)
          .maybeSingle();

      final hasRegistered = response != null;
      debugPrint('✅ User registration check: $hasRegistered');
      return Success(hasRegistered);
    } catch (e, stackTrace) {
      debugPrint('❌ Error checking registration: $e');
      debugPrint('Stack trace: $stackTrace');
      return Failure('Failed to check registration: $e');
    }
  }

  // Generate 6-digit attendance code
  String _generateAttendanceCode() {
    final code = _random.nextInt(900000) + 100000; // 100000-999999
    return code.toString();
  }
}

