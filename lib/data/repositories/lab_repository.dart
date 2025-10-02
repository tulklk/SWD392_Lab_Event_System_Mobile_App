import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/lab.dart';
import '../../core/utils/result.dart';

class LabRepository {
  static const String _boxName = 'labs';
  late Box<Lab> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Lab>(_boxName);
  }

  Future<Result<Lab>> createLab({
    required String name,
    required String location,
    required int capacity,
    required String description,
  }) async {
    try {
      final lab = Lab(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        location: location,
        capacity: capacity,
        description: description,
        createdAt: DateTime.now(),
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
        final updatedLab = lab.copyWith(isActive: false);
        await _box.put(id, updatedLab);
      }
      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete lab: $e');
    }
  }
}
