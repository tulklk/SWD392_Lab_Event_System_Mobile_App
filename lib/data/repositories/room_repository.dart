import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/result.dart';
import '../../domain/models/room.dart';

class RoomRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all rooms
  Future<Result<List<Room>>> getAllRooms() async {
    try {
      final response = await _supabase
          .from('tbl_rooms')
          .select()
          .order('CreatedAt', ascending: false);

      final rooms = (response as List)
          .map((json) => Room.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(rooms);
    } catch (e) {
      return Failure('Failed to fetch rooms: $e');
    }
  }

  // Get active rooms only
  Future<Result<List<Room>>> getActiveRooms() async {
    try {
      final response = await _supabase
          .from('tbl_rooms')
          .select()
          .eq('Status', 1)
          .order('Name', ascending: true);

      final rooms = (response as List)
          .map((json) => Room.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(rooms);
    } catch (e) {
      return Failure('Failed to fetch active rooms: $e');
    }
  }

  // Get room by ID
  Future<Result<Room>> getRoomById(String roomId) async {
    try {
      final response = await _supabase
          .from('tbl_rooms')
          .select()
          .eq('Id', roomId)
          .single();

      final room = Room.fromJson(response as Map<String, dynamic>);
      return Success(room);
    } catch (e) {
      return Failure('Failed to fetch room: $e');
    }
  }

  // Create new room (Lecturer/Admin only)
  Future<Result<Room>> createRoom({
    required String name,
    required int capacity,
  }) async {
    try {
      final now = DateTime.now();
      
      final response = await _supabase
          .from('tbl_rooms')
          .insert({
            'Name': name,
            'Capacity': capacity,
            'Status': 1,
            'CreatedAt': now.toIso8601String(),
            'LastUpdatedAt': now.toIso8601String(),
          })
          .select()
          .single();

      final room = Room.fromJson(response as Map<String, dynamic>);
      return Success(room);
    } catch (e) {
      return Failure('Failed to create room: $e');
    }
  }

  // Update room (Lecturer/Admin only)
  Future<Result<Room>> updateRoom({
    required String roomId,
    String? name,
    int? capacity,
    int? status,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'LastUpdatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['Name'] = name;
      if (capacity != null) updateData['Capacity'] = capacity;
      if (status != null) updateData['Status'] = status;

      final response = await _supabase
          .from('tbl_rooms')
          .update(updateData)
          .eq('Id', roomId)
          .select()
          .single();

      final room = Room.fromJson(response as Map<String, dynamic>);
      return Success(room);
    } catch (e) {
      return Failure('Failed to update room: $e');
    }
  }

  // Delete room (Admin only)
  Future<Result<void>> deleteRoom(String roomId) async {
    try {
      await _supabase
          .from('tbl_rooms')
          .delete()
          .eq('Id', roomId);

      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete room: $e');
    }
  }

  // Search rooms by name
  Future<Result<List<Room>>> searchRooms(String query) async {
    try {
      final response = await _supabase
          .from('tbl_rooms')
          .select()
          .ilike('Name', '%$query%')
          .eq('Status', 1)
          .order('Name', ascending: true);

      final rooms = (response as List)
          .map((json) => Room.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(rooms);
    } catch (e) {
      return Failure('Failed to search rooms: $e');
    }
  }

  // Get rooms by capacity (greater than or equal)
  Future<Result<List<Room>>> getRoomsByCapacity(int minCapacity) async {
    try {
      final response = await _supabase
          .from('tbl_rooms')
          .select()
          .gte('Capacity', minCapacity)
          .eq('Status', 1)
          .order('Capacity', ascending: true);

      final rooms = (response as List)
          .map((json) => Room.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(rooms);
    } catch (e) {
      return Failure('Failed to fetch rooms by capacity: $e');
    }
  }
}

// Provider for RoomRepository
final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository();
});

