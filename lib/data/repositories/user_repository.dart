import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter/foundation.dart';
import '../../domain/models/user.dart';
import '../../domain/enums/role.dart';
import '../../core/utils/result.dart';

class UserRepository {
  static const String _boxName = 'users';
  final SupabaseClient _supabase = Supabase.instance.client;
  late Box<User> _box;

  Future<void> init() async {
    _box = await Hive.openBox<User>(_boxName);
  }

  Future<Result<User>> createUser({
    required String username,
    required String fullname,
    required String email,
    String? mssv,
    required Role role,
  }) async {
    try {
      final now = DateTime.now();
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        fullname: fullname,
        email: email,
        mssv: mssv,
        status: 1,
        createdAt: now,
        lastUpdatedAt: now,
        roles: [role],
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
      debugPrint('🔍 UserRepository: Getting user by ID: $id');
      
      // First try to get from Supabase
      final response = await _supabase
          .from('tbl_users')
          .select()
          .eq('Id', id)
          .maybeSingle();

      if (response != null) {
        debugPrint('✅ User found in Supabase: ${response['Fullname']}');
        
        // Get user roles
        final rolesResponse = await _supabase
            .from('tbl_users_roles')
            .select('RoleId, tbl_roles(name)')
            .eq('UserId', id);

        // Parse roles
        final roles = <Role>[];
        if (rolesResponse != null && rolesResponse is List) {
          for (final roleData in rolesResponse) {
            final roleName = roleData['tbl_roles']?['name'] as String?;
            if (roleName != null) {
              try {
                final role = Role.values.firstWhere(
                  (r) => r.name.toLowerCase() == roleName.toLowerCase(),
                  orElse: () => Role.student,
                );
                roles.add(role);
              } catch (e) {
                debugPrint('⚠️ Invalid role name: $roleName');
              }
            }
          }
        }

        // If no roles, assign default student role
        if (roles.isEmpty) {
          roles.add(Role.student);
        }

        // Create user object
        final user = User.fromJson(response);
        final userWithRoles = user.copyWith(roles: roles);
        
        // Cache in Hive for future use
        try {
          await _box.put(userWithRoles.id, userWithRoles);
        } catch (e) {
          debugPrint('⚠️ Failed to cache user in Hive: $e');
        }
        
        return Success(userWithRoles);
      }

      // Fallback: try to get from Hive cache
      debugPrint('⚠️ User not found in Supabase, trying Hive cache...');
      final cachedUser = _box.get(id);
      if (cachedUser != null) {
        debugPrint('✅ User found in Hive cache: ${cachedUser.fullname}');
        return Success(cachedUser);
      }

      debugPrint('❌ User not found: $id');
      return Success(null);
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting user: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Fallback: try to get from Hive cache
      try {
        final cachedUser = _box.get(id);
        if (cachedUser != null) {
          debugPrint('✅ Fallback: User found in Hive cache: ${cachedUser.fullname}');
          return Success(cachedUser);
        }
      } catch (e2) {
        debugPrint('⚠️ Failed to get from Hive cache: $e2');
      }
      
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
