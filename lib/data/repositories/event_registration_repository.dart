import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/result.dart';
import '../../domain/models/event_registration.dart';
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
  Future<Result<List<EventRegistration>>> getRegistrationsForEvent(String eventId) async {
    try {
      final response = await _supabase
          .from('tbl_event_registrations')
          .select()
          .eq('EventId', eventId)
          .order('CreatedAt', ascending: false);

      final registrations = (response as List)
          .map((json) => EventRegistration.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(registrations);
    } catch (e) {
      return Failure('Failed to get registrations: $e');
    }
  }

  // Get pending registrations for an event
  Future<Result<List<EventRegistration>>> getPendingRegistrationsForEvent(String eventId) async {
    try {
      final response = await _supabase
          .from('tbl_event_registrations')
          .select()
          .eq('EventId', eventId)
          .eq('Status', 0)
          .order('CreatedAt', ascending: false);

      final registrations = (response as List)
          .map((json) => EventRegistration.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(registrations);
    } catch (e) {
      return Failure('Failed to get pending registrations: $e');
    }
  }

  // Approve registration
  Future<Result<void>> approveRegistration(String id) async {
    try {
      // Generate attendance code (6-digit)
      final attendanceCode = _generateAttendanceCode();

      await _supabase
          .from('tbl_event_registrations')
          .update({
            'Status': 1, // approved
            'AttendanceCode': attendanceCode,
            'LastUpdatedAt': DateTime.now().toIso8601String(),
          })
          .eq('Id', id);

      return const Success(null);
    } catch (e) {
      return Failure('Failed to approve registration: $e');
    }
  }

  // Bulk approve registrations
  Future<Result<void>> bulkApproveRegistrations(List<String> ids) async {
    try {
      for (final id in ids) {
        final attendanceCode = _generateAttendanceCode();
        await _supabase
            .from('tbl_event_registrations')
            .update({
              'Status': 1,
              'AttendanceCode': attendanceCode,
              'LastUpdatedAt': DateTime.now().toIso8601String(),
            })
            .eq('Id', id);
      }

      return const Success(null);
    } catch (e) {
      return Failure('Failed to bulk approve registrations: $e');
    }
  }

  // Reject registration
  Future<Result<void>> rejectRegistration(String id) async {
    try {
      await _supabase
          .from('tbl_event_registrations')
          .update({
            'Status': 2, // rejected
            'LastUpdatedAt': DateTime.now().toIso8601String(),
          })
          .eq('Id', id);

      return const Success(null);
    } catch (e) {
      return Failure('Failed to reject registration: $e');
    }
  }

  // Delete registration
  Future<Result<void>> deleteRegistration(String id) async {
    try {
      await _supabase
          .from('tbl_event_registrations')
          .delete()
          .eq('Id', id);

      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete registration: $e');
    }
  }

  // Get registration by ID
  Future<Result<EventRegistration?>> getRegistrationById(String id) async {
    try {
      final response = await _supabase
          .from('tbl_event_registrations')
          .select()
          .eq('Id', id)
          .maybeSingle();

      if (response == null) {
        return const Success(null);
      }

      final registration = EventRegistration.fromJson(response as Map<String, dynamic>);
      return Success(registration);
    } catch (e) {
      return Failure('Failed to get registration: $e');
    }
  }

  // Check if user already registered for event
  Future<Result<bool>> hasUserRegistered(String eventId, String userId) async {
    try {
      final response = await _supabase
          .from('tbl_event_registrations')
          .select()
          .eq('EventId', eventId)
          .eq('UserId', userId)
          .maybeSingle();

      return Success(response != null);
    } catch (e) {
      return Failure('Failed to check registration: $e');
    }
  }

  // Generate 6-digit attendance code
  String _generateAttendanceCode() {
    final code = _random.nextInt(900000) + 100000; // 100000-999999
    return code.toString();
  }
}

