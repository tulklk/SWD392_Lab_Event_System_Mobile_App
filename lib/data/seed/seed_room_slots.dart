import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/result.dart';

/// Seed Room Slots data
/// Call this once to populate room slots in database
class SeedRoomSlots {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Seed 8 time slots for all days (Monday to Friday) for a given room
  Future<Result<void>> seedSlotsForRoom(String roomId) async {
    try {
      // Define 8 time slots like in FPT schedule
      final List<Map<String, String>> timeSlots = [
        {'start': '07:00:00', 'end': '08:30:00'}, // Slot 1
        {'start': '08:45:00', 'end': '10:15:00'}, // Slot 2
        {'start': '10:30:00', 'end': '12:00:00'}, // Slot 3
        {'start': '12:30:00', 'end': '14:00:00'}, // Slot 4
        {'start': '14:15:00', 'end': '15:45:00'}, // Slot 5
        {'start': '16:00:00', 'end': '17:30:00'}, // Slot 6
        {'start': '17:45:00', 'end': '19:15:00'}, // Slot 7
        {'start': '19:30:00', 'end': '21:00:00'}, // Slot 8
      ];

      // Create slots for Monday to Friday (1-5)
      final List<Map<String, dynamic>> slotsToInsert = [];
      
      for (int dayOfWeek = 1; dayOfWeek <= 5; dayOfWeek++) {
        for (final slot in timeSlots) {
          slotsToInsert.add({
            'RoomId': roomId,
            'DayOfWeek': dayOfWeek,
            'StartTime': slot['start'],
            'EndTime': slot['end'],
          });
        }
      }

      // Insert all slots
      await _supabase.from('tbl_room_slots').insert(slotsToInsert);
      
      print('✅ Successfully seeded ${slotsToInsert.length} slots for room $roomId');
      return const Success(null);
    } catch (e) {
      print('❌ Error seeding room slots: $e');
      return Failure('Failed to seed room slots: $e');
    }
  }

  /// Seed slots for all rooms in the system
  Future<Result<void>> seedSlotsForAllRooms() async {
    try {
      // Get all rooms
      final response = await _supabase
          .from('tbl_rooms')
          .select('Id')
          .eq('Status', 1); // Only active rooms

      final rooms = response as List;
      
      if (rooms.isEmpty) {
        print('⚠️ No rooms found in database');
        return const Failure('No rooms found');
      }

      print('📋 Found ${rooms.length} rooms. Seeding slots...');
      
      // Seed slots for each room
      for (final room in rooms) {
        final roomId = room['Id'] as String;
        await seedSlotsForRoom(roomId);
      }

      print('✅ Completed seeding slots for all rooms!');
      return const Success(null);
    } catch (e) {
      print('❌ Error seeding slots for all rooms: $e');
      return Failure('Failed to seed slots: $e');
    }
  }

  /// Clear all room slots (for testing)
  Future<Result<void>> clearAllSlots() async {
    try {
      await _supabase.from('tbl_room_slots').delete().neq('Id', '');
      print('✅ Cleared all room slots');
      return const Success(null);
    } catch (e) {
      print('❌ Error clearing room slots: $e');
      return Failure('Failed to clear slots: $e');
    }
  }

  /// Seed slots for specific room ID with custom schedule
  Future<Result<void>> seedCustomSlots({
    required String roomId,
    required List<int> daysOfWeek, // e.g., [1, 2, 3, 4, 5] for Mon-Fri
    required List<Map<String, String>> timeSlots, // [{start: '07:00:00', end: '08:30:00'}]
  }) async {
    try {
      final List<Map<String, dynamic>> slotsToInsert = [];
      
      for (final dayOfWeek in daysOfWeek) {
        for (final slot in timeSlots) {
          slotsToInsert.add({
            'RoomId': roomId,
            'DayOfWeek': dayOfWeek,
            'StartTime': slot['start'],
            'EndTime': slot['end'],
          });
        }
      }

      await _supabase.from('tbl_room_slots').insert(slotsToInsert);
      
      print('✅ Successfully seeded ${slotsToInsert.length} custom slots for room $roomId');
      return const Success(null);
    } catch (e) {
      print('❌ Error seeding custom slots: $e');
      return Failure('Failed to seed custom slots: $e');
    }
  }
}

