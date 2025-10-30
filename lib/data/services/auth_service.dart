import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/result.dart';
import '../../domain/models/user.dart' as app_user;
import '../../domain/enums/role.dart';
import 'session_controller.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final _uuid = const Uuid();
  final _sessionController = SessionController.instance;

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

  /// Login with username and password
  Future<Result<app_user.User>> login({
    required String username,
    required String password,
  }) async {
    try {
      // 1. Find email from username in tbl_users
      final userResponse = await _supabase
          .from('tbl_users')
          .select('Email, Id, status')
          .eq('Username', username)
          .maybeSingle();

      if (userResponse == null) {
        return Failure('Username not found. Please check your credentials.');
      }

      // Check if user is active
      final status = userResponse['status'] as int?;
      if (status == 0) {
        return Failure('Your account has been deactivated.');
      }

      final email = userResponse['Email'] as String;
      
      // 2. Sign in with Supabase Auth using email
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return Failure('Login failed. Please check your credentials.');
      }

      // 3. Get user data from tbl_users
      final userResult = await _getUserById(response.user!.id);
      if (userResult.isSuccess && userResult.data != null) {
        // 4. Save session to SessionController
        await _saveSession(response.user!.id, response.session);
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
        // IMPORTANT: Save session for existing user!
        await _saveSession(userId, response.session);
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
            // IMPORTANT: Save session for existing user!
            await _saveSession(userId, response.session);
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
                // IMPORTANT: Save session for existing user!
                await _saveSession(userId, response.session);
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
        // 8. Save session to SessionController
        final session = _supabase.auth.currentSession;
        await _saveSession(userId, session);
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
      // Clear session from SessionController
      await _sessionController.clearSession();
      
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Sign out from Supabase
      await _supabase.auth.signOut();
      
      debugPrint('✅ Logout successful');
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
      debugPrint('📊 Step 1: Checking Supabase session...');
      
      // First check Supabase session
      final session = _supabase.auth.currentSession;
      
      if (session == null || session.user == null) {
        debugPrint('ℹ️ AuthService: No active Supabase session');
        debugPrint('📊 Step 2: Checking SessionController...');
        
        // Check if we have a valid session in SessionController
        final hasSession = await _sessionController.loadSession();
        if (hasSession && _sessionController.userId != null) {
          debugPrint('📱 SessionController has valid session for user: ${_sessionController.userId}');
          debugPrint('📱 Token preview: ${_sessionController.token?.substring(0, 20)}...');
          debugPrint('📱 Expires at: ${_sessionController.expiryDate}');
          
          // Try to get user by stored userId
          final userResult = await _getUserById(_sessionController.userId!);
          if (userResult.isSuccess) {
            debugPrint('✅ User restored from SessionController');
          }
          return userResult;
        }
        
        debugPrint('❌ No valid session found in SessionController');
        return const Success(null);
      }

      debugPrint('✅ AuthService: Active Supabase session found for ${session.user.email}');
      debugPrint('📅 Supabase session expires at: ${session.expiresAt}');
      
      // Save/Update session in SessionController (as backup)
      await _saveSession(session.user.id, session);
      
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
        debugPrint('⚠️ User not found in tbl_users: $userId');
        debugPrint('🔧 Attempting to auto-create user from Supabase Auth...');
        
        // Try to get user from Supabase Auth and create in tbl_users
        final supabaseUser = _supabase.auth.currentUser;
        if (supabaseUser != null && supabaseUser.id == userId) {
          final email = supabaseUser.email ?? '';
          final username = email.split('@')[0];
          
          debugPrint('📝 Creating user in tbl_users:');
          debugPrint('   Email: $email');
          debugPrint('   Username: $username');
          
          // Create user in tbl_users
          final now = DateTime.now();
          final userData = {
            'Id': userId,
            'Username': username,
            'Fullname': supabaseUser.userMetadata?['full_name'] ?? username,
            'Email': email,
            'Password': '',
            'MSSV': null,
            'status': 1,
            'CreatedAt': now.toIso8601String(),
            'LastUpdatedAt': now.toIso8601String(),
          };
          
          try {
            await _supabase.from('tbl_users').insert(userData);
            debugPrint('✅ User created successfully in tbl_users');
            
            // Assign default role
            await _assignRoleToUser(userId, Role.student);
            debugPrint('✅ Default role (student) assigned');
            
            // Retry getting user
            return await _getUserById(userId);
          } catch (e) {
            debugPrint('❌ Failed to create user: $e');
            return Failure('User not found and failed to create: $e');
          }
        }
        
        return Failure('User not found in tbl_users and no Supabase Auth user available');
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
              // Case-insensitive comparison
              final role = Role.values.firstWhere(
                (r) => r.name.toLowerCase() == roleName.toLowerCase(),
                orElse: () => Role.student,
              );
              roles.add(role);
              debugPrint('📋 Role loaded: $roleName -> ${role.name}');
            } catch (e) {
              debugPrint('⚠️ Invalid role name: $roleName');
              // Invalid role name, skip
            }
          }
        }
      }

      // If no roles, assign default student role
      if (roles.isEmpty) {
        debugPrint('⚠️ No roles found, assigning default student role');
        roles.add(Role.student);
      }

      // Create user object
      final user = app_user.User.fromJson(response);
      final userWithRoles = user.copyWith(roles: roles);

      debugPrint('👤 User loaded:');
      debugPrint('   Email: ${userWithRoles.email}');
      debugPrint('   Username: ${userWithRoles.username}');
      debugPrint('   Roles: ${userWithRoles.roles.map((r) => r.name).join(", ")}');
      debugPrint('   Primary Role: ${userWithRoles.role.name}');

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

  // ==================== SESSION MANAGEMENT ====================

  /// Save session to SessionController
  Future<void> _saveSession(String userId, Session? session) async {
    if (session == null) return;
    
    try {
      final accessToken = session.accessToken;
      final expiresAt = session.expiresAt != null 
          ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
          : DateTime.now().add(const Duration(hours: 1));
      
      await _sessionController.setSession(
        userId: userId,
        token: accessToken,
        expiryDate: expiresAt,
      );
      
      debugPrint('✅ Session saved to SessionController');
    } catch (e) {
      debugPrint('⚠️ Error saving session to SessionController: $e');
    }
  }

  /// Check if SessionController has valid session
  Future<bool> hasValidSession() async {
    return await _sessionController.loadSession();
  }

  // ==================== SEED ADMIN ACCOUNT ====================
  
  /// Seed admin account for development/testing
  /// Call this once to create admin@fpt.edu.vn with password
  Future<Result<void>> seedAdminAccount({
    String email = 'admin@fpt.edu.vn',
    String password = 'Admin@123',
  }) async {
    try {
      debugPrint('🌱 Seeding admin account...');
      
      // 1. Check if user already exists in tbl_users (by email or username)
      final existingUserByEmail = await _supabase
          .from('tbl_users')
          .select()
          .eq('Email', email)
          .maybeSingle();
      
      final existingUserByUsername = await _supabase
          .from('tbl_users')
          .select()
          .eq('Username', 'admin')
          .maybeSingle();
      
      final existingUser = existingUserByEmail ?? existingUserByUsername;
      
      // 2. Try to register admin in Supabase Auth
      String? newUserId;
      try {
        final authResponse = await _supabase.auth.signUp(
          email: email,
          password: password,
        );
        
        if (authResponse.user != null) {
          debugPrint('✅ Admin account created in Supabase Auth');
          newUserId = authResponse.user!.id;
          
          // Sign out immediately
          await _supabase.auth.signOut();
        } else {
          return Failure('Failed to create admin account in Supabase Auth');
        }
      } on AuthException catch (e) {
        if (e.message.contains('already registered') || 
            e.message.contains('User already registered')) {
          debugPrint('ℹ️ Admin account already exists in Supabase Auth');
          
          // Try to sign in to get the user ID
          try {
            final signInResponse = await _supabase.auth.signInWithPassword(
              email: email,
              password: password,
            );
            
            if (signInResponse.user != null) {
              newUserId = signInResponse.user!.id;
              debugPrint('✅ Got existing admin user ID: $newUserId');
              
              // Sign out immediately
              await _supabase.auth.signOut();
            }
          } catch (signInError) {
            debugPrint('⚠️ Could not sign in to get user ID: $signInError');
            return const Success(null); // Account exists but can't get ID, consider it success
          }
        } else {
          rethrow;
        }
      }
      
      // 3. Handle tbl_users record
      if (newUserId != null) {
        if (existingUser != null) {
          // User exists in tbl_users, update with new auth ID
          final oldId = existingUser['Id'] as String;
          
          if (oldId != newUserId) {
            debugPrint('🔄 Updating admin user ID from $oldId to $newUserId');
            
            // Delete old user record (to avoid FK constraints)
            try {
              // First, delete any role assignments for old ID
              await _supabase
                  .from('tbl_users_roles')
                  .delete()
                  .eq('UserId', oldId);
              
              // Delete old user record
              await _supabase
                  .from('tbl_users')
                  .delete()
                  .eq('Id', oldId);
              
              debugPrint('✅ Deleted old admin user record');
            } catch (deleteError) {
              debugPrint('⚠️ Could not delete old user: $deleteError');
            }
            
            // Insert new user record with new ID
            final now = DateTime.now();
            final userData = {
              'Id': newUserId,
              'Username': existingUser['Username'] ?? 'admin',
              'Fullname': existingUser['Fullname'] ?? 'Administrator',
              'Email': email,
              'Password': '',
              'MSSV': existingUser['MSSV'] ?? 'ADMIN001',
              'status': 1,
              'CreatedAt': existingUser['CreatedAt'] ?? now.toIso8601String(),
              'LastUpdatedAt': now.toIso8601String(),
            };
            
            await _supabase.from('tbl_users').insert(userData);
            debugPrint('✅ Created new admin user record with new ID');
          } else {
            debugPrint('✅ Admin user ID already matches, no update needed');
          }
        } else {
          // User doesn't exist in tbl_users, create new
          final now = DateTime.now();
          final userData = {
            'Id': newUserId,
            'Username': 'admin',
            'Fullname': 'Administrator',
            'Email': email,
            'Password': '',
            'MSSV': 'ADMIN001',
            'status': 1,
            'CreatedAt': now.toIso8601String(),
            'LastUpdatedAt': now.toIso8601String(),
          };
          
          await _supabase.from('tbl_users').insert(userData);
          debugPrint('✅ Admin user created in tbl_users');
        }
        
        // 4. Assign admin role
        await _assignRoleToUser(newUserId, Role.admin);
        debugPrint('✅ Admin role assigned');
      }
      
      return const Success(null);
    } catch (e) {
      debugPrint('❌ Error seeding admin account: $e');
      return Failure('Failed to seed admin account: $e');
    }
  }
}
