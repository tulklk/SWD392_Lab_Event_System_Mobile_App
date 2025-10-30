import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user.dart';
import '../../domain/enums/role.dart';
import '../../data/services/auth_service.dart';
import '../../core/utils/result.dart';

class AuthController extends Notifier<AsyncValue<User?>> {
  late final AuthService _authService;

  @override
  AsyncValue<User?> build() {
    _authService = AuthService();
    _loadCurrentUser();
    return const AsyncValue.loading();
  }

  Future<void> _loadCurrentUser() async {
    try {
      debugPrint('🔍 AuthController: Loading current user...');
      state = const AsyncValue.loading();
      
      // Small delay to ensure Supabase has time to restore session
      await Future.delayed(const Duration(milliseconds: 100));
      
      final result = await _authService.getCurrentUserProfile();
      
      if (result.isSuccess) {
        if (result.data != null) {
          debugPrint('✅ AuthController: User loaded - ${result.data!.email} (${result.data!.role.name})');
        } else {
          debugPrint('ℹ️ AuthController: No user session found');
        }
        state = AsyncValue.data(result.data);
      } else {
        debugPrint('❌ AuthController: Failed to load user - ${result.error}');
        state = const AsyncValue.data(null);
      }
    } catch (error, stackTrace) {
      debugPrint('❌ AuthController: Error loading user - $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Login with username and password
  Future<Result<User>> login({
    required String username,
    required String password,
  }) async {
    try {
      final result = await _authService.login(
        username: username,
        password: password,
      );

      if (result.isSuccess) {
        // Get user profile
        final profileResult = await _authService.getCurrentUserProfile();
        if (profileResult.isSuccess && profileResult.data != null) {
          final user = profileResult.data!;
          debugPrint('🔐 AuthController: Login successful');
          debugPrint('   User: ${user.email}');
          debugPrint('   Role: ${user.role.name} (${user.role.displayName})');
          debugPrint('   All Roles: ${user.roles.map((r) => r.name).join(", ")}');
          
          state = AsyncValue.data(user);
          return Success(user);
        } else {
          return Failure('Failed to load user profile');
        }
      } else {
        return Failure(result.error!);
      }
    } catch (e) {
      return Failure('Login failed: $e');
    }
  }

  // Register with email and password
  Future<Result<User>> register({
    required String email,
    required String password,
    required String fullname,
    required String username,
    String? mssv,
    required Role role,
  }) async {
    try {
      final result = await _authService.register(
        email: email,
        password: password,
        fullname: fullname,
        username: username,
        mssv: mssv,
        role: role,
      );

      if (result.isSuccess && result.data != null) {
        state = AsyncValue.data(result.data);
        return Success(result.data!);
      } else {
        return Failure(result.error ?? 'Registration failed');
      }
    } catch (e) {
      return Failure('Registration failed: $e');
    }
  }

  // Sign in with Google
  Future<Result<User>> signInWithGoogle() async {
    try {
      final result = await _authService.signInWithGoogle();

      if (result.isSuccess && result.data != null) {
        state = AsyncValue.data(result.data);
        return Success(result.data!);
      } else {
        return Failure(result.error ?? 'Google sign in failed');
      }
    } catch (e) {
      return Failure('Google sign in failed: $e');
    }
  }

  // Logout
  Future<Result<void>> logout() async {
    try {
      final result = await _authService.logout();
      if (result.isSuccess) {
        state = const AsyncValue.data(null);
      }
      return result;
    } catch (e) {
      return Failure('Logout failed: $e');
    }
  }

  // Reset password
  Future<Result<void>> resetPassword({required String email}) async {
    try {
      return await _authService.resetPassword(email: email);
    } catch (e) {
      return Failure('Password reset failed: $e');
    }
  }

  // Seed admin account (for development)
  Future<Result<void>> seedAdminAccount() async {
    try {
      return await _authService.seedAdminAccount();
    } catch (e) {
      return Failure('Failed to seed admin account: $e');
    }
  }

  User? get currentUser {
    return state.when(
      data: (user) => user,
      loading: () => null,
      error: (_, __) => null,
    );
  }

  bool get isLoggedIn => currentUser != null;
  
  bool get isAdmin => currentUser?.role == Role.admin;

  bool get isLecturer => currentUser?.role == Role.lecturer;

  bool get isStudent => currentUser?.role == Role.student;
}

final authControllerProvider = NotifierProvider<AuthController, AsyncValue<User?>>(() {
  return AuthController();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authControllerProvider).when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role == Role.admin;
});

final isLecturerProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role == Role.lecturer;
});

final isStudentProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role == Role.student;
});
