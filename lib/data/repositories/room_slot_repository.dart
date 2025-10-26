import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/result.dart';
import '../../domain/models/room_slot.dart';

class RoomSlotRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all room slots
  Future<Result<List<RoomSlot>>> getAllRoomSlots() async {
    try {
      final response = await _supabase
          .from('tbl_room_slots')
          .select()
          .order('DayOfWeek', ascending: true)
          .order('StartTime', ascending: true);

      final slots = (response as List)
          .map((json) => RoomSlot.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(slots);
    } catch (e) {
      return Failure('Failed to fetch room slots: $e');
    }
  }

  // Get slots by room ID
  Future<Result<List<RoomSlot>>> getSlotsByRoomId(String roomId) async {
    try {
      final response = await _supabase
          .from('tbl_room_slots')
          .select()
          .eq('RoomId', roomId)
          .order('DayOfWeek', ascending: true)
          .order('StartTime', ascending: true);

      final slots = (response as List)
          .map((json) => RoomSlot.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(slots);
    } catch (e) {
      return Failure('Failed to fetch room slots: $e');
    }
  }

  // Get slots by day of week
  Future<Result<List<RoomSlot>>> getSlotsByDayOfWeek(int dayOfWeek) async {
    try {
      final response = await _supabase
          .from('tbl_room_slots')
          .select()
          .eq('DayOfWeek', dayOfWeek)
          .order('StartTime', ascending: true);

      final slots = (response as List)
          .map((json) => RoomSlot.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(slots);
    } catch (e) {
      return Failure('Failed to fetch slots by day: $e');
    }
  }

  // Get room slot by ID
  Future<Result<RoomSlot>> getSlotById(String slotId) async {
    try {
      final response = await _supabase
          .from('tbl_room_slots')
          .select()
          .eq('Id', slotId)
          .single();

      final slot = RoomSlot.fromJson(response as Map<String, dynamic>);
      return Success(slot);
    } catch (e) {
      return Failure('Failed to fetch room slot: $e');
    }
  }

  // Create new room slot (Lecturer/Admin only)
  Future<Result<RoomSlot>> createRoomSlot({
    required String roomId,
    required int dayOfWeek,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final now = DateTime.now();
      
      final response = await _supabase
          .from('tbl_room_slots')
          .insert({
            'RoomId': roomId,
            'DayOfWeek': dayOfWeek,
            'StartTime': startTime.toIso8601String(),
            'EndTime': endTime.toIso8601String(),
            'CreatedAt': now.toIso8601String(),
            'LastUpdatedAt': now.toIso8601String(),
          })
          .select()
          .single();

      final slot = RoomSlot.fromJson(response as Map<String, dynamic>);
      return Success(slot);
    } catch (e) {
      return Failure('Failed to create room slot: $e');
    }
  }

  // Update room slot (Lecturer/Admin only)
  Future<Result<RoomSlot>> updateRoomSlot({
    required String slotId,
    int? dayOfWeek,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'LastUpdatedAt': DateTime.now().toIso8601String(),
      };

      if (dayOfWeek != null) updateData['DayOfWeek'] = dayOfWeek;
      if (startTime != null) updateData['StartTime'] = startTime.toIso8601String();
      if (endTime != null) updateData['EndTime'] = endTime.toIso8601String();

      final response = await _supabase
          .from('tbl_room_slots')
          .update(updateData)
          .eq('Id', slotId)
          .select()
          .single();

      final slot = RoomSlot.fromJson(response as Map<String, dynamic>);
      return Success(slot);
    } catch (e) {
      return Failure('Failed to update room slot: $e');
    }
  }

  // Delete room slot (Admin only)
  Future<Result<void>> deleteRoomSlot(String slotId) async {
    try {
      await _supabase
          .from('tbl_room_slots')
          .delete()
          .eq('Id', slotId);

      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete room slot: $e');
    }
  }

  // Check if time slot is available for booking
  Future<Result<bool>> isSlotAvailable({
    required String roomId,
    required int dayOfWeek,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      // Check if there's an overlapping slot
      final response = await _supabase
          .from('tbl_room_slots')
          .select()
          .eq('RoomId', roomId)
          .eq('DayOfWeek', dayOfWeek)
          .or('StartTime.lte.${endTime.toIso8601String()},EndTime.gte.${startTime.toIso8601String()}')
          .maybeSingle();

      return Success(response == null);
    } catch (e) {
      return Failure('Failed to check slot availability: $e');
    }
  }

  // Get available slots for a specific room and day
  Future<Result<List<RoomSlot>>> getAvailableSlots({
    required String roomId,
    required int dayOfWeek,
  }) async {
    try {
      // This would need to cross-check with bookings to find truly available slots
      // For now, just return all slots for that room and day
      final response = await _supabase
          .from('tbl_room_slots')
          .select()
          .eq('RoomId', roomId)
          .eq('DayOfWeek', dayOfWeek)
          .order('StartTime', ascending: true);

      final slots = (response as List)
          .map((json) => RoomSlot.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(slots);
    } catch (e) {
      return Failure('Failed to fetch available slots: $e');
    }
  }
}

// Provider for RoomSlotRepository
final roomSlotRepositoryProvider = Provider<RoomSlotRepository>((ref) {
  return RoomSlotRepository();
});

