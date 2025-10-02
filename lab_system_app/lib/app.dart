import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/l10n.dart';
import 'data/local/hive_adapters.dart';
import 'data/seed/seed_data.dart';
import 'data/repositories/lab_repository.dart';
import 'data/repositories/event_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/booking_repository.dart';
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
      // Initialize Hive
      await Hive.initFlutter();
      
      // Register adapters
      HiveAdapters.registerAdapters();
      
      // Initialize repositories
      final labRepository = LabRepository();
      final eventRepository = EventRepository();
      final userRepository = UserRepository();
      final bookingRepository = BookingRepository();
      
      await labRepository.init();
      await eventRepository.init();
      await userRepository.init();
      await bookingRepository.init();
      
      // Seed data if needed
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
