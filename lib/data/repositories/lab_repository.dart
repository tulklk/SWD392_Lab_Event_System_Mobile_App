import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/lab.dart';
import '../../core/utils/result.dart';

class LabRepository {
  static const String _boxName = 'labs';
  late Box<Lab> _box;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> init() async {
    _box = await Hive.openBox<Lab>(_boxName);
  }
  
  // Get labs from Supabase
  Future<Result<List<Lab>>> getLabsFromSupabase() async {
    try {
      final response = await _supabase
          .from('tbl_labs')
          .select()
          .eq('Status', 1) // active only
          .order('Name', ascending: true);

      if (response == null || response.isEmpty) {
        return Success(<Lab>[]);
      }

      final labs = (response as List)
          .map((json) {
            try {
              return Lab.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              debugPrint('Error parsing lab: $e');
              debugPrint('Lab JSON: $json');
              rethrow;
            }
          })
          .where((lab) => lab.id.isNotEmpty && lab.name.isNotEmpty) // Filter out invalid labs
          .toList();

      return Success(labs);
    } catch (e, stackTrace) {
      debugPrint('Error fetching labs: $e');
      debugPrint('Stack trace: $stackTrace');
      return Failure('Failed to fetch labs: $e');
    }
  }

  Future<Result<Lab>> createLab({
    required String name,
    String? location,
    required String roomId,
  }) async {
    try {
      final now = DateTime.now();
      final lab = Lab(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        location: location,
        createdAt: now,
        lastUpdatedAt: now,
        roomId: roomId,
        status: 1,
      );

      await _box.put(lab.id, lab);
      return Success(lab);
    } catch (e) {
      return Failure('Failed to create lab: $e');
    }
  }

  Future<Result<Lab?>> getLabById(String id) async {
    try {
      final lab = _box.get(id);
      return Success(lab);
    } catch (e) {
      return Failure('Failed to get lab: $e');
    }
  }

  Future<Result<List<Lab>>> getAllLabs() async {
    try {
      final labs = _box.values.where((lab) => lab.isActive).toList();
      return Success(labs);
    } catch (e) {
      return Failure('Failed to get all labs: $e');
    }
  }

  Future<Result<Lab>> updateLab(Lab lab) async {
    try {
      await _box.put(lab.id, lab);
      return Success(lab);
    } catch (e) {
      return Failure('Failed to update lab: $e');
    }
  }

  Future<Result<void>> deleteLab(String id) async {
    try {
      final lab = _box.get(id);
      if (lab != null) {
        final updatedLab = lab.copyWith(status: 0);
        await _box.put(id, updatedLab);
      }
      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete lab: $e');
    }
  }
}
