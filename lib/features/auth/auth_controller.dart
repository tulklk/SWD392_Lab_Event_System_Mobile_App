import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user.dart';
import '../../domain/enums/role.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/utils/result.dart';

class AuthController extends Notifier<AsyncValue<User?>> {
  @override
  AsyncValue<User?> build() {
    _loadCurrentUser();
    return const AsyncValue.loading();
  }

  UserRepository get _userRepository => ref.read(userRepositoryProvider);

  Future<void> _loadCurrentUser() async {
    try {
      state = const AsyncValue.loading();
      // Ensure repository is initialized
      await _userRepository.init();
      final result = await _userRepository.getCurrentUser();
      
      if (result.isSuccess) {
        state = AsyncValue.data(result.data);
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<Result<User>> login({
    required String name,
    String? studentId,
    required Role role,
  }) async {
    try {
      // Ensure repository is initialized
      await _userRepository.init();
      
      // Create or get user
      final result = await _userRepository.createUser(
        name: name,
        studentId: studentId,
        role: role.name,
      );

      if (result.isSuccess) {
        print('User created successfully: ${result.data!.name}');
        // Set as current user
        await _userRepository.setCurrentUser(result.data!.id);
        print('Current user set to: ${result.data!.id}');
        state = AsyncValue.data(result.data);
        return result;
      } else {
        print('User creation failed: ${result.error}');
        return result;
      }
    } catch (e) {
      return Failure('Login failed: $e');
    }
  }

  Future<Result<void>> logout() async {
    try {
      final result = await _userRepository.logout();
      if (result.isSuccess) {
        state = const AsyncValue.data(null);
      }
      return result;
    } catch (e) {
      return Failure('Logout failed: $e');
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

  bool get isLabManager => currentUser?.role == Role.labManager;

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

final isLabManagerProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role == Role.labManager;
});

final isStudentProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role == Role.student;
});
