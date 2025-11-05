import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_controller.dart';
import '../notifications/notification_providers.dart';
import 'lecturer_events_screen.dart';
import 'pending_bookings_screen.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/event_registration_repository.dart';
import '../../domain/models/event.dart';

class LecturerDashboardScreen extends ConsumerStatefulWidget {
  const LecturerDashboardScreen({super.key});

  @override
  ConsumerState<LecturerDashboardScreen> createState() => _LecturerDashboardScreenState();
}

class _LecturerDashboardScreenState extends ConsumerState<LecturerDashboardScreen> {
  int _selectedIndex = 0;
  int _eventsRefreshTrigger = 0; // Counter to trigger refresh

  List<Widget> get _screens => [
    LecturerOverviewPage(
      onTabChange: (index) {
        setState(() {
          _selectedIndex = index;
        });
        // Refresh events screen when navigated to Events tab
        if (index == 1) {
          setState(() {
            _eventsRefreshTrigger++; // Trigger refresh
          });
        }
      },
    ),
    LecturerEventsScreen(
      key: ValueKey(_eventsRefreshTrigger), // Rebuild when trigger changes
    ),
    const PendingBookingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

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
                    'Lecturer Portal',
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
                      'Lecturer',
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
          // Notification Bell with Badge
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
            child: _NotificationBell(
              onTap: () {
                context.push('/notifications');
              },
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
                if (value == 'profile') {
                  context.push('/profile');
                } else if (value == 'logout') {
                  final authController = ref.read(authControllerProvider.notifier);
                  final result = await authController.logout();
                  
                  if (result.isSuccess && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged out successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );
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
                      Color(0xFFFF6600),
                      Color(0xFFFF8533),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    currentUser?.name[0].toUpperCase() ?? 'L',
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
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 12),
                      const Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // Refresh events screen when Events tab is selected
          if (index == 1) {
            // Events tab is at index 1 - trigger refresh by updating key
            setState(() {
              _eventsRefreshTrigger++;
            });
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.approval_outlined),
            selectedIcon: Icon(Icons.approval),
            label: 'Approvals',
          ),
        ],
      ),
    );
  }
}

// Overview Page with statistics
class LecturerOverviewPage extends ConsumerStatefulWidget {
  final Function(int)? onTabChange;
  
  const LecturerOverviewPage({
    super.key,
    this.onTabChange,
  });

  @override
  ConsumerState<LecturerOverviewPage> createState() => _LecturerOverviewPageState();
}

class _LecturerOverviewPageState extends ConsumerState<LecturerOverviewPage> {
  int _pendingApprovalsCount = 0;
  int _activeEventsCount = 0;
  int _totalRegistrationsCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoadingStats = true);

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() => _isLoadingStats = false);
      return;
    }

    try {
      // 1. Get pending approvals count
      final bookingRepository = ref.read(bookingRepositoryProvider);
      final pendingBookingsResult = await bookingRepository.getPendingBookings();
      final pendingCount = pendingBookingsResult.isSuccess 
          ? (pendingBookingsResult.data?.length ?? 0)
          : 0;

      // 2. Get active events count
      final eventRepository = ref.read(eventRepositoryProvider);
      final eventsResult = await eventRepository.getEventsByCreator(currentUser.id);
      final now = DateTime.now();
      final activeEvents = eventsResult.isSuccess && eventsResult.data != null
          ? eventsResult.data!.where((event) {
              return event.status == 1 && // active
                     event.startDate != null &&
                     event.endDate != null &&
                     event.startDate!.isBefore(now) &&
                     event.endDate!.isAfter(now);
            }).toList()
          : <Event>[];
      final activeCount = activeEvents.length;

      // 3. Get total registrations count (for all events created by lecturer)
      int totalRegistrations = 0;
      if (eventsResult.isSuccess && eventsResult.data != null) {
        final eventRegistrationRepository = ref.read(eventRegistrationRepositoryProvider);
        for (final event in eventsResult.data!) {
          final registrationsResult = await eventRegistrationRepository.getRegistrationsForEvent(event.id);
          if (registrationsResult.isSuccess && registrationsResult.data != null) {
            totalRegistrations += registrationsResult.data!.length;
          }
        }
      }

      if (mounted) {
        setState(() {
          _pendingApprovalsCount = pendingCount;
          _activeEventsCount = activeCount;
          _totalRegistrationsCount = totalRegistrations;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading statistics: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF6600),
                  Color(0xFFFF8533),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6600).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser?.fullname ?? 'Lecturer',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentUser?.email ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.event_note,
                  title: 'Create Event',
                  subtitle: 'New workshop',
                  color: Colors.blue,
                  onTap: () {
                    context.push('/lecturer/events/create');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.approval,
                  title: 'Approvals',
                  subtitle: 'Review bookings',
                  color: Colors.orange,
                  onTap: () {
                    // Navigate to approvals tab (index 2)
                    widget.onTabChange?.call(2);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Statistics
          Text(
            'Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          _StatisticCard(
            icon: Icons.pending_actions,
            title: 'Pending Approvals',
            value: _isLoadingStats ? '...' : '$_pendingApprovalsCount',
            subtitle: 'Bookings waiting review',
            color: Colors.amber,
            onTap: () {
              widget.onTabChange?.call(2); // Navigate to Approvals tab
            },
          ),
          const SizedBox(height: 12),
          _StatisticCard(
            icon: Icons.event_available,
            title: 'Active Events',
            value: _isLoadingStats ? '...' : '$_activeEventsCount',
            subtitle: 'Ongoing workshops',
            color: Colors.green,
            onTap: () {
              widget.onTabChange?.call(1); // Navigate to Events tab
            },
          ),
          const SizedBox(height: 12),
          _StatisticCard(
            icon: Icons.people_outline,
            title: 'Total Registrations',
            value: _isLoadingStats ? '...' : '$_totalRegistrationsCount',
            subtitle: 'Students registered',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _StatisticCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

/// Notification Bell Widget with Badge
class _NotificationBell extends ConsumerWidget {
  final VoidCallback onTap;

  const _NotificationBell({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

    return IconButton(
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          unreadCountAsync.when(
            data: (count) {
              if (count > 0) {
                return Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: count > 9 ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: count > 9 ? BorderRadius.circular(8) : null,
                    ),
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
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

