import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/result.dart';
import '../../domain/models/equipment.dart';

class EquipmentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all equipment
  Future<Result<List<Equipment>>> getAllEquipment() async {
    try {
      debugPrint('🔍 EquipmentRepository: Fetching all equipment from Supabase...');
      final response = await _supabase
          .from('tbl_equipments')
          .select()
          .order('CreatedAt', ascending: false);

      debugPrint('✅ EquipmentRepository: Received ${(response as List).length} equipment from Supabase');
      
      final equipment = <Equipment>[];
      for (var json in (response as List)) {
        try {
          final eq = Equipment.fromJson(json as Map<String, dynamic>);
          equipment.add(eq);
        } catch (e) {
          debugPrint('⚠️ EquipmentRepository: Failed to parse equipment: $e');
          debugPrint('   JSON: $json');
        }
      }

      debugPrint('✅ EquipmentRepository: Successfully parsed ${equipment.length} equipment');
      return Success(equipment);
    } catch (e, stackTrace) {
      debugPrint('❌ EquipmentRepository: Failed to fetch equipment: $e');
      debugPrint('   Stack trace: $stackTrace');
      return Failure('Failed to fetch equipment: $e');
    }
  }

  // Get equipment by room ID
  Future<Result<List<Equipment>>> getEquipmentByRoomId(String roomId) async {
    try {
      final response = await _supabase
          .from('tbl_equipments')
          .select()
          .eq('RoomId', roomId)
          .order('Name', ascending: true);

      final equipment = (response as List)
          .map((json) => Equipment.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(equipment);
    } catch (e) {
      return Failure('Failed to fetch equipment for room: $e');
    }
  }

  // Get active equipment
  Future<Result<List<Equipment>>> getActiveEquipment() async {
    try {
      final response = await _supabase
          .from('tbl_equipments')
          .select()
          .eq('Status', 1)
          .order('Name', ascending: true);

      final equipment = (response as List)
          .map((json) => Equipment.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(equipment);
    } catch (e) {
      return Failure('Failed to fetch active equipment: $e');
    }
  }

  // Get equipment needing maintenance
  Future<Result<List<Equipment>>> getMaintenanceEquipment() async {
    try {
      final response = await _supabase
          .from('tbl_equipments')
          .select()
          .eq('Status', 2)
          .order('NextMaintenanceDate', ascending: true);

      final equipment = (response as List)
          .map((json) => Equipment.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(equipment);
    } catch (e) {
      return Failure('Failed to fetch maintenance equipment: $e');
    }
  }

  // Get equipment by ID
  Future<Result<Equipment>> getEquipmentById(String equipmentId) async {
    try {
      final response = await _supabase
          .from('tbl_equipments')
          .select()
          .eq('Id', equipmentId)
          .single();

      final equipment = Equipment.fromJson(response as Map<String, dynamic>);
      return Success(equipment);
    } catch (e) {
      return Failure('Failed to fetch equipment: $e');
    }
  }

  // Create new equipment (Lecturer/Admin only)
  Future<Result<Equipment>> createEquipment({
    required String name,
    String? description,
    String? serialNumber,
    required int type,
    required String roomId,
    String? imageUrl,
  }) async {
    try {
      final now = DateTime.now();
      
      final response = await _supabase
          .from('tbl_equipments')
          .insert({
            'Name': name,
            'Description': description,
            'SerialNumber': serialNumber,
            'Type': type,
            'Status': 1,
            'ImageUrl': imageUrl,
            'RoomId': roomId,
            'CreatedAt': now.toIso8601String(),
            'LastUpdatedAt': now.toIso8601String(),
          })
          .select()
          .single();

      final equipment = Equipment.fromJson(response as Map<String, dynamic>);
      return Success(equipment);
    } catch (e) {
      return Failure('Failed to create equipment: $e');
    }
  }

  // Update equipment (Lecturer/Admin only)
  Future<Result<Equipment>> updateEquipment({
    required String equipmentId,
    String? name,
    String? description,
    String? serialNumber,
    int? type,
    int? status,
    String? imageUrl,
    DateTime? lastMaintenanceDate,
    DateTime? nextMaintenanceDate,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'LastUpdatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['Name'] = name;
      if (description != null) updateData['Description'] = description;
      if (serialNumber != null) updateData['SerialNumber'] = serialNumber;
      if (type != null) updateData['Type'] = type;
      if (status != null) updateData['Status'] = status;
      if (imageUrl != null) updateData['ImageUrl'] = imageUrl;
      if (lastMaintenanceDate != null) {
        updateData['LastMaintenanceDate'] = lastMaintenanceDate.toIso8601String();
      }
      if (nextMaintenanceDate != null) {
        updateData['NextMaintenanceDate'] = nextMaintenanceDate.toIso8601String();
      }

      final response = await _supabase
          .from('tbl_equipments')
          .update(updateData)
          .eq('Id', equipmentId)
          .select()
          .single();

      final equipment = Equipment.fromJson(response as Map<String, dynamic>);
      return Success(equipment);
    } catch (e) {
      return Failure('Failed to update equipment: $e');
    }
  }

  // Delete equipment (Admin only)
  Future<Result<void>> deleteEquipment(String equipmentId) async {
    try {
      await _supabase
          .from('tbl_equipments')
          .delete()
          .eq('Id', equipmentId);

      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete equipment: $e');
    }
  }

  // Search equipment
  Future<Result<List<Equipment>>> searchEquipment(String query) async {
    try {
      final response = await _supabase
          .from('tbl_equipments')
          .select()
          .or('Name.ilike.%$query%,SerialNumber.ilike.%$query%')
          .order('Name', ascending: true);

      final equipment = (response as List)
          .map((json) => Equipment.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(equipment);
    } catch (e) {
      return Failure('Failed to search equipment: $e');
    }
  }
}

// Provider for EquipmentRepository
final equipmentRepositoryProvider = Provider<EquipmentRepository>((ref) {
  return EquipmentRepository();
});

