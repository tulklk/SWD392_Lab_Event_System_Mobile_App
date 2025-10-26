import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/result.dart';
import '../../domain/models/booking_apply.dart';

class BookingApplyRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all booking applications
  Future<Result<List<BookingApply>>> getAllBookingApplies() async {
    try {
      final response = await _supabase
          .from('tbl_booking_applies')
          .select()
          .order('CreatedAt', ascending: false);

      final applies = (response as List)
          .map((json) => BookingApply.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(applies);
    } catch (e) {
      return Failure('Failed to fetch booking applications: $e');
    }
  }

  // Get booking applications by booking ID
  Future<Result<List<BookingApply>>> getAppliesByBookingId(String bookingId) async {
    try {
      final response = await _supabase
          .from('tbl_booking_applies')
          .select()
          .eq('BookingId', bookingId)
          .order('CreatedAt', ascending: false);

      final applies = (response as List)
          .map((json) => BookingApply.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(applies);
    } catch (e) {
      return Failure('Failed to fetch booking applications: $e');
    }
  }

  // Get pending booking applications (Lecturer/Admin)
  Future<Result<List<BookingApply>>> getPendingApplies() async {
    try {
      final response = await _supabase
          .from('tbl_booking_applies')
          .select()
          .eq('Status', 'pending')
          .order('CreatedAt', ascending: true);

      final applies = (response as List)
          .map((json) => BookingApply.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(applies);
    } catch (e) {
      return Failure('Failed to fetch pending applications: $e');
    }
  }

  // Get booking apply by ID
  Future<Result<BookingApply>> getApplyById(String applyId) async {
    try {
      final response = await _supabase
          .from('tbl_booking_applies')
          .select()
          .eq('Id', applyId)
          .single();

      final apply = BookingApply.fromJson(response as Map<String, dynamic>);
      return Success(apply);
    } catch (e) {
      return Failure('Failed to fetch booking application: $e');
    }
  }

  // Create new booking application
  Future<Result<BookingApply>> createBookingApply({
    required String bookingId,
    required String roomSlotId,
    String? note,
  }) async {
    try {
      final now = DateTime.now();
      
      final response = await _supabase
          .from('tbl_booking_applies')
          .insert({
            'BookingId': bookingId,
            'RoomSlotId': roomSlotId,
            'Status': 'pending',
            'Note': note,
            'CreatedAt': now.toIso8601String(),
            'LastUpdatedAt': now.toIso8601String(),
          })
          .select()
          .single();

      final apply = BookingApply.fromJson(response as Map<String, dynamic>);
      return Success(apply);
    } catch (e) {
      return Failure('Failed to create booking application: $e');
    }
  }

  // Update booking application status (Lecturer/Admin only)
  Future<Result<BookingApply>> updateApplyStatus({
    required String applyId,
    required String status,
    String? note,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'Status': status,
        'LastUpdatedAt': DateTime.now().toIso8601String(),
      };

      if (note != null) {
        updateData['Note'] = note;
      }

      final response = await _supabase
          .from('tbl_booking_applies')
          .update(updateData)
          .eq('Id', applyId)
          .select()
          .single();

      final apply = BookingApply.fromJson(response as Map<String, dynamic>);
      return Success(apply);
    } catch (e) {
      return Failure('Failed to update booking application status: $e');
    }
  }

  // Delete booking application
  Future<Result<void>> deleteApply(String applyId) async {
    try {
      await _supabase
          .from('tbl_booking_applies')
          .delete()
          .eq('Id', applyId);

      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete booking application: $e');
    }
  }
}

// Provider for BookingApplyRepository
final bookingApplyRepositoryProvider = Provider<BookingApplyRepository>((ref) {
  return BookingApplyRepository();
});

