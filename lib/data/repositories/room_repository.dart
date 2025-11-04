import 'package:flutter/foundation.dart';
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

  // Get rooms by LabId
  // Database schema shows tbl_rooms has LabId column (uuid)
  Future<Result<List<Room>>> getRoomsByLabId(String labId) async {
    try {
      debugPrint('🔍 Getting rooms for LabId: $labId');
      debugPrint('   LabId type: ${labId.runtimeType}');
      debugPrint('   LabId length: ${labId.length}');
      
      // First, try to get all rooms to debug
      try {
        final allRoomsResponse = await _supabase
            .from('tbl_rooms')
            .select()
            .eq('Status', 1);
        
        if (allRoomsResponse != null && allRoomsResponse.isNotEmpty) {
          debugPrint('📊 Total active rooms in database: ${allRoomsResponse.length}');
          // Check what LabIds exist
          final allRooms = (allRoomsResponse as List).cast<Map<String, dynamic>>();
          final labIdsInRooms = allRooms
              .where((r) => r['LabId'] != null)
              .map((r) => r['LabId'].toString())
              .toSet();
          debugPrint('   Unique LabIds in rooms: ${labIdsInRooms.length}');
          labIdsInRooms.forEach((lid) {
            debugPrint('     - $lid');
            final roomsForLab = allRooms.where((r) => r['LabId']?.toString() == lid).length;
            debugPrint('       -> $roomsForLab rooms');
          });
          
          // Check if our LabId matches any
          final matchingRooms = allRooms.where((r) {
            final roomLabId = r['LabId']?.toString();
            return roomLabId == labId;
          }).toList();
          
          if (matchingRooms.isNotEmpty) {
            debugPrint('✅ Found ${matchingRooms.length} matching rooms (direct match)');
            final rooms = matchingRooms
                .map((json) => Room.fromJson(json))
                .toList();
            return Success(rooms);
          } else {
            debugPrint('⚠️ No direct match found. Checking case-insensitive...');
            // Try case-insensitive match
            final caseInsensitiveMatch = allRooms.where((r) {
              final roomLabId = r['LabId']?.toString().toLowerCase();
              return roomLabId == labId.toLowerCase();
            }).toList();
            
            if (caseInsensitiveMatch.isNotEmpty) {
              debugPrint('✅ Found ${caseInsensitiveMatch.length} rooms (case-insensitive match)');
              final rooms = caseInsensitiveMatch
                  .map((json) => Room.fromJson(json))
                  .toList();
              return Success(rooms);
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error getting all rooms for debug: $e');
      }
      
      // Now try the actual query
      debugPrint('🔍 Querying with Supabase filter...');
      final response = await _supabase
          .from('tbl_rooms')
          .select()
          .eq('LabId', labId)
          .eq('Status', 1)
          .order('Name', ascending: true);

      debugPrint('   Raw response type: ${response.runtimeType}');
      debugPrint('   Response is null: ${response == null}');
      
      if (response == null) {
        debugPrint('⚠️ Response is null');
        return Success(<Room>[]);
      }

      final responseList = response as List;
      debugPrint('   Response length: ${responseList.length}');
      
      if (responseList.isEmpty) {
        debugPrint('⚠️ No rooms found for LabId: $labId');
        debugPrint('   Trying without Status filter...');
        
        // Try without Status filter
        final responseNoStatus = await _supabase
            .from('tbl_rooms')
            .select()
            .eq('LabId', labId)
            .order('Name', ascending: true);
        
        if (responseNoStatus != null && (responseNoStatus as List).isNotEmpty) {
          debugPrint('✅ Found ${(responseNoStatus as List).length} rooms (without Status filter)');
          final rooms = (responseNoStatus as List)
              .map((json) => Room.fromJson(json as Map<String, dynamic>))
              .toList();
          return Success(rooms);
        }
        
        return Success(<Room>[]);
      }

      final rooms = responseList
          .map((json) {
            try {
              return Room.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              debugPrint('❌ Error parsing room: $e');
              debugPrint('Room JSON: $json');
              rethrow;
            }
          })
          .toList();

      debugPrint('✅ Found ${rooms.length} rooms for LabId: $labId');
      return Success(rooms);
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching rooms by LabId: $e');
      debugPrint('Stack trace: $stackTrace');
      return Failure('Failed to fetch rooms by lab: $e');
    }
  }
}

// Provider for RoomRepository
final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository();
});

