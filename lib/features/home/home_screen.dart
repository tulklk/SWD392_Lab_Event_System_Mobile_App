import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'student_dashboard_page.dart';
import 'lecturer_dashboard_page.dart';
import '../calendar/calendar_screen.dart';
import '../events/student_events_screen.dart';
import '../labs/labs_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../bookings/booking_providers.dart';
import '../admin/admin_dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/my_reports_screen.dart';
import '../../domain/enums/role.dart';
import '../auth/auth_controller.dart';
import '../notifications/notification_screen.dart';
import '../notifications/notification_providers.dart';
import '../../data/services/notification_realtime_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  int _bookingsRefreshTrigger = 0; // Counter to trigger refresh for My Bookings

  @override
  void initState() {
    super.initState();
    // Start listening to realtime notifications when home screen is opened
    // This works for all users (student, lecturer, admin)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final realtimeService = ref.read(notificationRealtimeServiceProvider);
      realtimeService.startListening(ref);
      debugPrint('🔔 HomeScreen: Started realtime notification listener');
    });
  }

  @override
  void dispose() {
    // Stop listening when home screen is closed
    final realtimeService = ref.read(notificationRealtimeServiceProvider);
    realtimeService.stopListening();
    debugPrint('🔕 HomeScreen: Stopped realtime notification listener');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final isLecturer = ref.watch(isLecturerProvider);
    final isStudent = ref.watch(isStudentProvider);
    
    // Watch for navigation signal to My Bookings
    final navigateToMyBookings = ref.watch(navigateToMyBookingsProvider);
    if (navigateToMyBookings && isStudent) {
      // Navigate to My Bookings tab (index 4 for students - after Reports)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedIndex != 4) {
          setState(() {
            _selectedIndex = 4;
          });
        }
      });
    }
    
    // Watch for booking refresh trigger and increment local counter
    final bookingRefreshTrigger = ref.watch(myBookingsRefreshProvider);
    if (bookingRefreshTrigger > 0 && isStudent) {
      // When booking is created, increment local trigger to force rebuild
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _bookingsRefreshTrigger != bookingRefreshTrigger) {
          setState(() {
            _bookingsRefreshTrigger = bookingRefreshTrigger;
          });
        }
      });
    }
    
    // Define screens and navigation based on role
    List<Widget> screens = [];
    List<NavigationDestination> destinations = [];
    
    if (isStudent) {
      // Student: Home, Calendar, Events, Reports, and My Bookings
      screens = [
        StudentDashboardPage(
          onTabChange: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
        const CalendarScreen(),
        const StudentEventsScreen(),
        const MyReportsScreen(),
        MyBookingsScreen(
          key: ValueKey(_bookingsRefreshTrigger), // Rebuild when trigger changes
        ),
      ];
      destinations = [
        const NavigationDestination(
          icon: Icon(Icons.home_rounded),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Icon(Icons.calendar_month_rounded),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Calendar',
        ),
        const NavigationDestination(
          icon: Icon(Icons.event_rounded),
          selectedIcon: Icon(Icons.event_rounded),
          label: 'Event',
        ),
        const NavigationDestination(
          icon: Icon(Icons.report_rounded),
          selectedIcon: Icon(Icons.report),
          label: 'Reports',
        ),
        const NavigationDestination(
          icon: Icon(Icons.book_online_rounded),
          selectedIcon: Icon(Icons.book_online_rounded),
          label: 'My Bookings',
        ),
      ];
    } else if (isLecturer) {
      // Lecturer: Home, Calendar, Labs, Reports, and Lab Management
      screens = [
        LecturerDashboardPage(
          onTabChange: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
        const CalendarScreen(),
        const LabsScreen(),
        const MyReportsScreen(),
        const AdminDashboardScreen(),
      ];
      destinations = [
        const NavigationDestination(
          icon: Icon(Icons.home_rounded),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Icon(Icons.calendar_month_rounded),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Calendar',
        ),
        const NavigationDestination(
          icon: Icon(Icons.science_rounded),
          selectedIcon: Icon(Icons.science_rounded),
          label: 'Labs',
        ),
        const NavigationDestination(
          icon: Icon(Icons.report_rounded),
          selectedIcon: Icon(Icons.report),
          label: 'Reports',
        ),
        const NavigationDestination(
          icon: Icon(Icons.manage_accounts_rounded),
          selectedIcon: Icon(Icons.manage_accounts_rounded),
          label: 'Manage',
        ),
      ];
    } else if (isAdmin) {
      // Admin: Full access to all features
      screens = [
        const AdminDashboardScreen(),
        const CalendarScreen(),
        const LabsScreen(),
        const MyBookingsScreen(),
        const AdminDashboardScreen(),
      ];
      destinations = [
        const NavigationDestination(
          icon: Icon(Icons.dashboard_rounded),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        const NavigationDestination(
          icon: Icon(Icons.calendar_month_rounded),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Calendar',
        ),
        const NavigationDestination(
          icon: Icon(Icons.science_rounded),
          selectedIcon: Icon(Icons.science_rounded),
          label: 'Labs',
        ),
        const NavigationDestination(
          icon: Icon(Icons.book_online_rounded),
          selectedIcon: Icon(Icons.book_online_rounded),
          label: 'Bookings',
        ),
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_rounded),
          selectedIcon: Icon(Icons.admin_panel_settings_rounded),
          label: 'Admin',
        ),
      ];
    } else {
      // Fallback for logged out users (shouldn't happen due to router guard)
      // Use at least 2 destinations to satisfy NavigationBar requirement
      screens = [
        StudentDashboardPage(),
        const CalendarScreen(),
      ];
      destinations = [
        const NavigationDestination(
          icon: Icon(Icons.home_rounded),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Icon(Icons.calendar_month_rounded),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Calendar',
        ),
      ];
    }

    // Ensure selectedIndex is valid for the current destinations
    // Use a local variable to avoid setState in build method
    final validSelectedIndex = destinations.isEmpty || 
            _selectedIndex >= destinations.length || 
            _selectedIndex < 0
        ? 0
        : _selectedIndex;
    
    // Update state if needed (but only after build completes)
    if (validSelectedIndex != _selectedIndex && destinations.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = validSelectedIndex;
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/fpt_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FPT Lab Events',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentUser?.role.displayName ?? 'User',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Notification bell with badge
          Consumer(
            builder: (context, ref, child) {
              final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
              
              return Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        ).then((_) {
                          // Refresh notifications when returning from screen
                          refreshNotifications(ref);
                        });
                      },
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    // Badge
                    unreadCountAsync.when(
                      data: (count) {
                        if (count == 0) return const SizedBox.shrink();
                        return Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                count > 99 ? '99+' : count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              onSelected: (value) async {
                print('PopupMenu selected: $value'); // Debug log
                if (value == 'profile') {
                  // Navigate to profile screen
                  print('Navigating to profile...'); // Debug log
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                } else if (value == 'logout') {
                  final authController = ref.read(authControllerProvider.notifier);
                  final result = await authController.logout();
                  
                  if (result.isSuccess && mounted) {
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged out successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );
                    // Redirect to login page
                    context.go('/login');
                  }
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF6600), // Orange primary
                      Color(0xFFFF8533), // Orange lighter
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    currentUser?.name[0].toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'profile',
                  enabled: true,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFF6600), // Orange primary
                                Color(0xFFFF8533), // Orange lighter
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              currentUser?.name[0].toUpperCase() ?? 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser?.name ?? 'User',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                currentUser?.role.displayName ?? '',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: validSelectedIndex,
        children: screens,
      ),
      bottomNavigationBar: destinations.length >= 2
          ? NavigationBar(
              selectedIndex: validSelectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
                
                // My Bookings will auto-refresh via didChangeDependencies when tab becomes visible
                if (isStudent && index == 3) {
                  debugPrint('🔄 Switched to My Bookings tab (index 3)');
                }
              },
              destinations: destinations,
            )
          : null,
    );
  }
}
