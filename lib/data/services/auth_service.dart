import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/result.dart';
import '../../domain/models/user.dart' as app_user;
import '../../domain/enums/role.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final _uuid = const Uuid();

  // Get current Supabase auth user
  bool get isLoggedIn {
    try {
      return _supabase.auth.currentSession != null;
    } catch (e) {
      return false;
    }
  }

  // ==================== EMAIL/PASSWORD AUTH ====================

  /// Register with email, password and user details
  Future<Result<app_user.User>> register({
    required String email,
    required String password,
    required String fullname,
    required String username,
    String? mssv,
    required Role role,
  }) async {
    try {
      // 1. Sign up with Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return Failure('Registration failed. Please try again.');
      }

      final userId = authResponse.user!.id;

      // 2. Create user in tbl_users
      final now = DateTime.now();
      final userData = {
        'Id': userId,
        'Username': username,
        'Fullname': fullname,
        'Email': email,
        'Password': '', // Not storing password in custom table
        'MSSV': mssv,
        'status': 1, // Active
        'CreatedAt': now.toIso8601String(),
        'LastUpdatedAt': now.toIso8601String(),
      };

      await _supabase.from('tbl_users').insert(userData);

      // 3. Get or create role
      final roleResult = await _getRoleByName(role.name);
      if (!roleResult.isSuccess) {
        // Create role if doesn't exist
        await _createRole(role);
      }

      // 4. Assign role to user
      await _assignRoleToUser(userId, role);

      // 5. Get complete user data
      final userResult = await _getUserById(userId);
      if (userResult.isSuccess && userResult.data != null) {
        return Success(userResult.data!);
      }

      return Failure('User created but failed to load profile');
    } on AuthException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Registration failed: $e');
    }
  }

  /// Login with email and password
  Future<Result<app_user.User>> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign in with Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return Failure('Login failed. Please check your credentials.');
      }

      // 2. Get user data from tbl_users
      final userResult = await _getUserById(response.user!.id);
      if (userResult.isSuccess && userResult.data != null) {
        // Check if user is active
        if (userResult.data!.status == 0) {
          await logout();
          return Failure('Your account has been deactivated.');
        }
        return Success(userResult.data!);
      }

      return Failure('Login successful but failed to load user profile.');
    } on AuthException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Login failed: $e');
    }
  }

  // ==================== GOOGLE SIGN IN ====================

  /// Sign in with Google
  Future<Result<app_user.User>> signInWithGoogle() async {
    try {
      debugPrint('🔐 Starting Google Sign In...');
      
      // 1. Sign in with Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('❌ Google sign in cancelled by user');
        return Failure('Google sign in was cancelled');
      }

      debugPrint('✅ Google user obtained: ${googleUser.email}');
      
      // Validate email domain - Only allow @fpt.edu.vn
      final email = googleUser.email;
      if (!email.toLowerCase().endsWith('@fpt.edu.vn')) {
        debugPrint('❌ Invalid email domain: $email');
        // Sign out from Google and reject login
        await _googleSignIn.signOut();
        return Failure('Only FPT University email addresses (@fpt.edu.vn) are allowed to sign in.');
      }

      debugPrint('✅ Email domain validated: $email');

      // 2. Get Google auth
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        debugPrint('❌ Failed to get Google auth tokens');
        return Failure('Failed to get Google credentials');
      }

      debugPrint('✅ Google auth tokens obtained');

      // 3. Sign in to Supabase with Google credentials
      debugPrint('🔐 Signing in to Supabase with Google credentials...');
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        debugPrint('❌ Supabase authentication failed');
        return Failure('Failed to authenticate with Google');
      }

      debugPrint('✅ Supabase authentication successful');
      debugPrint('📱 Session created for: ${response.user!.email}');
      debugPrint('📅 Session expires at: ${response.session?.expiresAt}');
      
      final userId = response.user!.id;
      // Email already validated above

      // 4. Check if user exists in tbl_users (by userId first, then by email)
      final existingUser = await _getUserById(userId);
      if (existingUser.isSuccess && existingUser.data != null) {
        return Success(existingUser.data!);
      }

      // Check if user exists by email (in case userId changed but email is same)
      try {
        final existingByEmail = await _supabase
            .from('tbl_users')
            .select()
            .eq('Email', email)
            .maybeSingle();

        if (existingByEmail != null) {
          debugPrint('User found by email: $email, getting user data...');
          // User exists with this email, just return the existing user
          final existingUserId = existingByEmail['Id'] as String;
          final userResult = await _getUserById(existingUserId);
          if (userResult.isSuccess && userResult.data != null) {
            return Success(userResult.data!);
          }
        }
      } catch (e) {
        debugPrint('Email check error: $e');
        // Continue to create new user
      }

      // 5. Create new user if doesn't exist
      final now = DateTime.now();
      final username = googleUser.email.split('@')[0]; // Use email prefix as username
      final userData = {
        'Id': userId,
        'Username': username,
        'Fullname': googleUser.displayName ?? username,
        'Email': email,
        'Password': '', // No password for Google sign in
        'MSSV': null,
        'status': 1,
        'CreatedAt': now.toIso8601String(),
        'LastUpdatedAt': now.toIso8601String(),
      };

      try {
        await _supabase.from('tbl_users').insert(userData);
      } catch (e) {
        debugPrint('Insert user error: $e');
        // If insert fails due to duplicate email, get existing user by email
        if (e.toString().contains('duplicate key') || 
            e.toString().contains('IX_tbl_users_Email')) {
          try {
            final existingByEmail = await _supabase
                .from('tbl_users')
                .select()
                .eq('Email', email)
                .maybeSingle();
            
            if (existingByEmail != null) {
              final existingUserId = existingByEmail['Id'] as String;
              final userResult = await _getUserById(existingUserId);
              if (userResult.isSuccess && userResult.data != null) {
                return Success(userResult.data!);
              }
            }
          } catch (emailError) {
            debugPrint('Failed to get user by email: $emailError');
          }
        }
        rethrow;
      }

      // 6. Assign default role (student)
      await _assignRoleToUser(userId, Role.student);

      // 7. Get complete user data
      final userResult = await _getUserById(userId);
      if (userResult.isSuccess && userResult.data != null) {
        return Success(userResult.data!);
      }

      return Failure('Google sign in successful but failed to load profile');
    } catch (e) {
      return Failure('Google sign in failed: $e');
    }
  }

  // ==================== LOGOUT ====================

  /// Logout user
  Future<Result<void>> logout() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Sign out from Supabase
      await _supabase.auth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure('Logout failed: $e');
    }
  }

  // ==================== GET USER DATA ====================

  /// Get current user profile
  Future<Result<app_user.User?>> getCurrentUserProfile() async {
    try {
      debugPrint('🔐 AuthService: Checking current session...');
      final session = _supabase.auth.currentSession;
      
      if (session == null || session.user == null) {
        debugPrint('ℹ️ AuthService: No active session');
        return const Success(null);
      }

      debugPrint('✅ AuthService: Active session found for ${session.user.email}');
      return await _getUserById(session.user.id);
    } catch (e) {
      debugPrint('❌ AuthService: Error getting profile - $e');
      return Failure('Failed to get user profile: $e');
    }
  }

  /// Get user by ID with roles
  Future<Result<app_user.User>> _getUserById(String userId) async {
    try {
      // Get user data
      final response = await _supabase
          .from('tbl_users')
          .select()
          .eq('Id', userId)
          .maybeSingle();

      if (response == null) {
        return Failure('User not found');
      }

      // Get user roles
      final rolesResponse = await _supabase
          .from('tbl_users_roles')
          .select('RoleId, tbl_roles(name)')
          .eq('UserId', userId);

      // Parse roles
      final roles = <Role>[];
      if (rolesResponse != null && rolesResponse is List) {
        for (final roleData in rolesResponse) {
          final roleName = roleData['tbl_roles']?['name'] as String?;
          if (roleName != null) {
            try {
              final role = Role.values.firstWhere(
                (r) => r.name == roleName,
                orElse: () => Role.student,
              );
              roles.add(role);
            } catch (e) {
              // Invalid role name, skip
            }
          }
        }
      }

      // If no roles, assign default student role
      if (roles.isEmpty) {
        roles.add(Role.student);
      }

      // Create user object
      final user = app_user.User.fromJson(response);
      final userWithRoles = user.copyWith(roles: roles);

      return Success(userWithRoles);
    } catch (e) {
      return Failure('Failed to get user: $e');
    }
  }

  // ==================== ROLE MANAGEMENT ====================

  /// Get role by name
  Future<Result<Map<String, dynamic>>> _getRoleByName(String roleName) async {
    try {
      final response = await _supabase
          .from('tbl_roles')
          .select()
          .eq('name', roleName)
          .maybeSingle();

      if (response == null) {
        return Failure('Role not found');
      }

      return Success(response);
    } catch (e) {
      return Failure('Failed to get role: $e');
    }
  }

  /// Create role
  Future<Result<void>> _createRole(Role role) async {
    try {
      final now = DateTime.now();
      final roleData = {
        'id': _uuid.v4(),
        'name': role.name,
        'description': role.displayName,
        'CreatedAt': now.toIso8601String(),
        'LastUpdatedAt': now.toIso8601String(),
      };

      await _supabase.from('tbl_roles').insert(roleData);
      return const Success(null);
    } catch (e) {
      // Role might already exist, ignore error
      return const Success(null);
    }
  }

  /// Assign role to user
  Future<Result<void>> _assignRoleToUser(String userId, Role role) async {
    try {
      // Get role ID
      final roleResult = await _getRoleByName(role.name);
      if (!roleResult.isSuccess) {
        return Failure('Role not found');
      }

      final roleId = roleResult.data!['id'] as String;

      // Check if assignment already exists
      final existing = await _supabase
          .from('tbl_users_roles')
          .select()
          .eq('UserId', userId)
          .eq('RoleId', roleId)
          .maybeSingle();

      if (existing != null) {
        return const Success(null); // Already assigned
      }

      // Assign role
      await _supabase.from('tbl_users_roles').insert({
        'UserId': userId,
        'RoleId': roleId,
      });

      return const Success(null);
    } catch (e) {
      return Failure('Failed to assign role: $e');
    }
  }

  // ==================== PASSWORD RESET ====================

  /// Reset password
  Future<Result<void>> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return const Success(null);
    } on AuthException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Password reset failed: $e');
    }
  }

  // ==================== UPDATE PROFILE ====================

  /// Update user profile
  Future<Result<app_user.User>> updateUserProfile({
    required String userId,
    String? fullname,
    String? username,
    String? mssv,
  }) async {
    try {
      final updates = <String, dynamic>{
        'LastUpdatedAt': DateTime.now().toIso8601String(),
      };
      
      if (fullname != null) updates['Fullname'] = fullname;
      if (username != null) updates['Username'] = username;
      if (mssv != null) updates['MSSV'] = mssv;

      await _supabase
          .from('tbl_users')
          .update(updates)
          .eq('Id', userId);

      // Fetch updated profile
      final result = await _getUserById(userId);
      if (result.isSuccess && result.data != null) {
        return Success(result.data!);
      }

      return Failure('Failed to fetch updated profile');
    } catch (e) {
      return Failure('Failed to update user profile: $e');
    }
  }

  // Stream auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
