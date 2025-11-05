import 'package:flutter/material.dart';
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
import '../../domain/enums/role.dart';
import '../auth/auth_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final isLecturer = ref.watch(isLecturerProvider);
    final isStudent = ref.watch(isStudentProvider);
    
    // Watch for navigation signal to My Bookings
    final navigateToMyBookings = ref.watch(navigateToMyBookingsProvider);
    if (navigateToMyBookings && isStudent) {
      // Navigate to My Bookings tab (index 3 for students)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedIndex != 3) {
          setState(() {
            _selectedIndex = 3;
          });
        }
      });
    }
    
    // Define screens and navigation based on role
    List<Widget> screens = [];
    List<NavigationDestination> destinations = [];
    
    if (isStudent) {
      // Student: Only Home, Calendar, Events, and My Bookings
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
        MyBookingsScreen(),
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
          icon: Icon(Icons.book_online_rounded),
          selectedIcon: Icon(Icons.book_online_rounded),
          label: 'My Bookings',
        ),
      ];
    } else if (isLecturer) {
      // Lecturer: Home, Calendar, Labs, and Lab Management
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
      screens = [StudentDashboardPage()];
      destinations = [
        const NavigationDestination(
          icon: Icon(Icons.home_rounded),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
      ];
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
          Container(
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
            child: IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.notifications_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
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
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
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
      ),
    );
  }
}
