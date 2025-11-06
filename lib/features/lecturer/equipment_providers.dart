import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../domain/models/equipment.dart';
import '../../domain/models/room.dart';
import '../../core/utils/result.dart';

/// Provider for rooms that have equipment
final roomsProvider = FutureProvider<List<Room>>((ref) async {
  try {
    debugPrint('🔍 RoomsProvider: Fetching rooms with equipment...');
    
    // First, get all equipment to find which rooms have equipment
    final equipmentRepository = ref.watch(equipmentRepositoryProvider);
    final equipmentResult = await equipmentRepository.getAllEquipment();
    
    if (!equipmentResult.isSuccess || equipmentResult.data == null) {
      debugPrint('⚠️ RoomsProvider: Failed to get equipment, returning empty list');
      return [];
    }
    
    final allEquipment = equipmentResult.data!;
    // Filter out maintenance equipment (status 2)
    final availableEquipment = allEquipment.where((eq) => eq.status != 2).toList();
    
    // Get unique room IDs from equipment
    final roomIds = availableEquipment
        .map((eq) => eq.roomId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    
    debugPrint('📦 RoomsProvider: Found ${roomIds.length} unique rooms with equipment');
    debugPrint('   Room IDs: $roomIds');
    
    if (roomIds.isEmpty) {
      debugPrint('⚠️ RoomsProvider: No rooms with equipment found');
      return [];
    }
    
    // Get room details for each room ID
    final roomRepository = ref.watch(roomRepositoryProvider);
    final rooms = <Room>[];
    
    for (final roomId in roomIds) {
      try {
        final roomResult = await roomRepository.getRoomById(roomId);
        if (roomResult.isSuccess && roomResult.data != null) {
          rooms.add(roomResult.data!);
        }
      } catch (e) {
        debugPrint('⚠️ RoomsProvider: Failed to get room $roomId: $e');
      }
    }
    
    // Sort rooms by name
    rooms.sort((a, b) => a.name.compareTo(b.name));
    
    debugPrint('✅ RoomsProvider: Returning ${rooms.length} rooms with equipment');
    return rooms;
  } catch (e, stackTrace) {
    debugPrint('❌ RoomsProvider: Exception occurred: $e');
    debugPrint('   Stack trace: $stackTrace');
    return [];
  }
});

/// Provider for room by ID
final roomProvider = FutureProvider.family<Room?, String>((ref, roomId) async {
  final repository = ref.watch(roomRepositoryProvider);
  final result = await repository.getRoomById(roomId);
  
  if (result.isSuccess) {
    return result.data;
  } else {
    return null;
  }
});

/// Provider for all active equipment
final allEquipmentProvider = FutureProvider<List<Equipment>>((ref) async {
  final repository = ref.watch(equipmentRepositoryProvider);
  // Get all equipment (not just active) to show everything
  final result = await repository.getAllEquipment();
  
  if (result.isSuccess) {
    // Filter out only maintenance equipment (status 2), show inactive (0) and active (1)
    return (result.data ?? []).where((eq) => eq.status != 2).toList();
  } else {
    return [];
  }
});

/// Provider for equipment by room ID
final equipmentByRoomProvider = FutureProvider.family<List<Equipment>, String>((ref, roomId) async {
  final repository = ref.watch(equipmentRepositoryProvider);
  final result = await repository.getEquipmentByRoomId(roomId);
  
  if (result.isSuccess) {
    return result.data ?? [];
  } else {
    return [];
  }
});

/// Provider for filtered equipment (by room and search query)
final filteredEquipmentProvider = FutureProvider.family<List<Equipment>, ({
  String? roomId,
  String? searchQuery,
})>((ref, params) async {
  try {
    debugPrint('🔍 EquipmentProvider: Fetching equipment...');
    debugPrint('   roomId: ${params.roomId}');
    debugPrint('   searchQuery: ${params.searchQuery}');
    
    final repository = ref.watch(equipmentRepositoryProvider);
    
    // If roomId is specified, get equipment for that room
    if (params.roomId != null) {
      debugPrint('📦 EquipmentProvider: Getting equipment for room: ${params.roomId}');
      final result = await repository.getEquipmentByRoomId(params.roomId!);
      
      if (result.isSuccess) {
        var equipment = result.data ?? [];
        debugPrint('✅ EquipmentProvider: Found ${equipment.length} equipment for room');
        
        // Apply search filter if provided
        if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
          final query = params.searchQuery!.toLowerCase();
          equipment = equipment.where((eq) {
            return eq.name.toLowerCase().contains(query) ||
                   (eq.description?.toLowerCase().contains(query) ?? false) ||
                   (eq.serialNumber?.toLowerCase().contains(query) ?? false);
          }).toList();
          debugPrint('🔍 EquipmentProvider: After search filter: ${equipment.length} equipment');
        }
        
        return equipment;
      } else {
        debugPrint('❌ EquipmentProvider: Failed to get equipment for room: ${result.error}');
        return [];
      }
    }
    
    // Otherwise, get all equipment (not just active)
    debugPrint('📦 EquipmentProvider: Getting all equipment...');
    final result = await repository.getAllEquipment();
    
    if (result.isSuccess) {
      final allEquipment = result.data ?? [];
      debugPrint('✅ EquipmentProvider: Fetched ${allEquipment.length} total equipment from database');
      
      // Filter out only maintenance equipment (status 2), show inactive (0) and active (1)
      var equipment = allEquipment.where((eq) => eq.status != 2).toList();
      debugPrint('📊 EquipmentProvider: After status filter (removing status 2): ${equipment.length} equipment');
      debugPrint('   Status breakdown:');
      final statusCounts = <int, int>{};
      for (var eq in allEquipment) {
        statusCounts[eq.status] = (statusCounts[eq.status] ?? 0) + 1;
      }
      statusCounts.forEach((status, count) {
        debugPrint('     Status $status: $count items');
      });
      
      // Apply search filter if provided
      if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
        final query = params.searchQuery!.toLowerCase();
        equipment = equipment.where((eq) {
          return eq.name.toLowerCase().contains(query) ||
                 (eq.description?.toLowerCase().contains(query) ?? false) ||
                 (eq.serialNumber?.toLowerCase().contains(query) ?? false);
        }).toList();
        debugPrint('🔍 EquipmentProvider: After search filter: ${equipment.length} equipment');
      }
      
      debugPrint('✅ EquipmentProvider: Returning ${equipment.length} equipment');
      return equipment;
    } else {
      debugPrint('❌ EquipmentProvider: Failed to get all equipment: ${result.error}');
      return [];
    }
  } catch (e, stackTrace) {
    debugPrint('❌ EquipmentProvider: Exception occurred: $e');
    debugPrint('   Stack trace: $stackTrace');
    return [];
  }
});

