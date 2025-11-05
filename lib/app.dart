import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/l10n.dart';
import 'core/config/supabase_config.dart';
import 'data/seed/seed_data.dart';
import 'data/repositories/lab_repository.dart';
import 'data/repositories/event_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/booking_repository.dart';
import 'data/services/fcm_service.dart';
import 'features/auth/auth_controller.dart';
import 'routes/app_router.dart';

class LabSystemApp extends ConsumerWidget {
  const LabSystemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'FPT Lab System',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

class AppInitializer extends ConsumerStatefulWidget {
  final Widget child;
  
  const AppInitializer({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize Firebase
      try {
        await Firebase.initializeApp();
        debugPrint('✅ Firebase initialized successfully');
        
        // Initialize FCM
        final fcmService = FCMService();
        await fcmService.initialize();
        debugPrint('✅ FCM initialized successfully');
      } catch (e) {
        debugPrint('⚠️ Firebase initialization failed (may not be configured): $e');
        // Continue without Firebase if not configured
      }
      
      // Initialize Supabase with auth persistence (session persistence is enabled by default)
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
      );
      debugPrint('✅ Supabase initialized successfully');
      
      // Setup auth state listener - CRITICAL for session persistence!
      // This listens to auth changes and updates the app state
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        final event = data.event;
        
        debugPrint('🔔 Auth state changed: $event');
        if (session != null) {
          debugPrint('📱 Session active: ${session.user.email}');
          
          // IMPORTANT: Save FCM token when user logs in
          // This ensures token is saved even if FCM was initialized before login
          try {
            final fcmService = FCMService();
            final currentToken = fcmService.currentToken;
            if (currentToken != null) {
              debugPrint('🔄 Saving FCM token after login for user: ${session.user.id}');
              // Force save token by calling internal method
              // We'll add a public method for this
              await fcmService.saveTokenForCurrentUser();
            } else {
              debugPrint('⚠️ No FCM token available to save after login');
              // Try to get token again
              await fcmService.refreshToken();
            }
          } catch (e) {
            debugPrint('⚠️ Failed to save FCM token after login: $e');
          }
        } else {
          debugPrint('📱 No active session');
        }
        
        // Refresh auth controller when auth state changes
        if (mounted) {
          ref.invalidate(authControllerProvider);
        }
      });
      
      // Wait longer for Supabase to recover session from local storage
      // Google Sign In needs more time to restore session
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Check if we have a session
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        debugPrint('✅ Session recovered: User ${session.user.email}');
        debugPrint('📅 Session expires at: ${session.expiresAt}');
        
        // IMPORTANT: Save FCM token if we have a session on app startup
        // This handles the case where FCM was initialized before login
        try {
          final fcmService = FCMService();
          await Future.delayed(const Duration(milliseconds: 500)); // Wait a bit more
          await fcmService.saveTokenForCurrentUser();
        } catch (e) {
          debugPrint('⚠️ Failed to save FCM token on startup: $e');
        }
      } else {
        debugPrint('ℹ️ No existing session found');
      }
      
      // Initialize Hive (for local caching of other data like labs, events, bookings)
      try {
      await Hive.initFlutter();
        debugPrint('✅ Hive initialized');
      } catch (e) {
        debugPrint('ℹ️ Hive already initialized: $e');
      }
      
      // Initialize repositories
      final labRepository = LabRepository();
      final eventRepository = EventRepository();
      final userRepository = UserRepository();
      final bookingRepository = BookingRepository();
      
      try {
      await labRepository.init();
      await eventRepository.init();
      await userRepository.init();
      await bookingRepository.init();
        debugPrint('✅ Repositories initialized');
      } catch (e) {
        debugPrint('⚠️ Repository init error (may be already open): $e');
      }
      
      // Seed data if needed (only for labs and events, users will be in Supabase)
      await SeedData.seedIfNeeded(
        labRepository: labRepository,
        eventRepository: eventRepository,
        userRepository: userRepository,
        bookingRepository: bookingRepository,
      );
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing app: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Initializing FPT Lab System...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return widget.child;
  }
}
