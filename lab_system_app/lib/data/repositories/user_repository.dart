import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user.dart';
import '../../domain/enums/role.dart';
import '../../core/utils/result.dart';

class UserRepository {
  static const String _boxName = 'users';
  late Box<User> _box;

  Future<void> init() async {
    _box = await Hive.openBox<User>(_boxName);
  }

  Future<Result<User>> createUser({
    required String name,
    String? studentId,
    required String role,
  }) async {
    try {
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        studentId: studentId,
        role: Role.values.firstWhere(
          (r) => r.name == role,
          orElse: () => Role.student,
        ),
        createdAt: DateTime.now(),
      );

      await _box.put(user.id, user);
      return Success(user);
    } catch (e) {
      return Failure('Failed to create user: $e');
    }
  }

  Future<Result<User?>> getCurrentUser() async {
    try {
      final settingsBox = await Hive.openBox('settings');
      final currentUserId = settingsBox.get('current_user_id');
      if (currentUserId == null) return Success(null);
      
      final user = _box.get(currentUserId);
      return Success(user);
    } catch (e) {
      return Failure('Failed to get current user: $e');
    }
  }

  Future<Result<void>> setCurrentUser(String userId) async {
    try {
      // Store current user ID in a separate box
      final settingsBox = await Hive.openBox('settings');
      await settingsBox.put('current_user_id', userId);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to set current user: $e');
    }
  }

  Future<Result<void>> logout() async {
    try {
      final settingsBox = await Hive.openBox('settings');
      await settingsBox.delete('current_user_id');
      return const Success(null);
    } catch (e) {
      return Failure('Failed to logout: $e');
    }
  }

  Future<Result<User?>> getUserById(String id) async {
    try {
      final user = _box.get(id);
      return Success(user);
    } catch (e) {
      return Failure('Failed to get user: $e');
    }
  }

  Future<Result<List<User>>> getAllUsers() async {
    try {
      final users = _box.values.where((user) => user.id != 'current_user_id').toList();
      return Success(users);
    } catch (e) {
      return Failure('Failed to get all users: $e');
    }
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});
