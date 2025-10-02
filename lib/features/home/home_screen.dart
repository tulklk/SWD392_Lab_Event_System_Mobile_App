import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'student_dashboard_page.dart';
import 'lab_manager_dashboard_page.dart';
import '../calendar/calendar_screen.dart';
import '../labs/labs_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../admin/admin_dashboard_screen.dart';
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
    final isLabManager = ref.watch(isLabManagerProvider);
    final isStudent = ref.watch(isStudentProvider);
    
    // Define screens and navigation based on role
    List<Widget> screens = [];
    List<NavigationDestination> destinations = [];
    
    if (isStudent) {
      // Student: Only Home, Calendar, Labs, and My Bookings
      screens = [
        StudentDashboardPage(),
        const CalendarScreen(),
        const LabsScreen(),
        const MyBookingsScreen(),
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
          icon: Icon(Icons.book_online_rounded),
          selectedIcon: Icon(Icons.book_online_rounded),
          label: 'My Bookings',
        ),
      ];
    } else if (isLabManager) {
      // Lab Manager: Home, Calendar, Labs, Bookings Management, and Lab Management
      screens = [
        const LabManagerDashboardPage(),
        const CalendarScreen(),
        const LabsScreen(),
        const MyBookingsScreen(),
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
          icon: Icon(Icons.book_online_rounded),
          selectedIcon: Icon(Icons.book_online_rounded),
          label: 'Bookings',
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'FL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
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
                if (value == 'logout') {
                  final authController = ref.read(authControllerProvider.notifier);
                  await authController.logout();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              currentUser?.name[0].toUpperCase() ?? 'U',
                              style: TextStyle(
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
        },
        destinations: destinations,
      ),
    );
  }
}
