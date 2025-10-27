import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/result.dart';
import '../domain/enums/role.dart';
import '../domain/models/booking.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/labs/lab_detail_screen.dart';
import '../features/bookings/booking_form_screen.dart';
import '../features/bookings/qr_ticket_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/manage_labs_screen.dart';
import '../features/admin/manage_events_screen.dart';
import '../features/auth/auth_controller.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state to trigger router refresh when auth changes
  ref.watch(authControllerProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      debugPrint('🔄 Router: Current path = ${state.uri.path}');
      final authState = ref.read(authControllerProvider);
      
      // Check if we're still loading auth state
      final isLoading = authState.isLoading;
      final currentUser = authState.when(
        data: (user) => user,
        loading: () => null,
        error: (_, __) => null,
      );
      
      debugPrint('🔄 Router: Auth loading = $isLoading, User = ${currentUser?.email ?? "none"} (${currentUser?.role.name ?? "N/A"})');
      
      final isOnSplash = state.uri.path == '/splash';
      final isOnAuth = state.uri.path == '/login';
      
      // If still loading and not on splash, go to splash
      if (isLoading && !isOnSplash) {
        debugPrint('⏳ Router: Still loading auth, showing splash');
        return '/splash';
      }
      
      // If done loading
      if (!isLoading) {
        // If on splash, redirect based on auth state
        if (isOnSplash) {
          if (currentUser != null) {
            debugPrint('✅ Router: User logged in (${currentUser.email}), redirecting from splash');
            // Redirect based on user role
            switch (currentUser.role) {
              case Role.admin:
                debugPrint('➡️ Router: Redirecting to /admin (Admin)');
                return '/admin';
              case Role.lecturer:
                debugPrint('➡️ Router: Redirecting to /admin (Lecturer)');
                return '/admin';
              case Role.student:
              default:
                debugPrint('➡️ Router: Redirecting to /home (Student)');
                return '/home';
            }
          } else {
            debugPrint('ℹ️ Router: No user, redirecting to login');
            return '/login';
          }
        }
        
        // If no user is logged in and not on auth pages, redirect to login
        if (currentUser == null && !isOnAuth) {
          debugPrint('🔒 Router: No user and not on auth page, redirecting to login');
          return '/login';
        }
        
        // If user is logged in and on auth pages, redirect based on role
        if (currentUser != null && isOnAuth) {
          debugPrint('✅ Router: User already logged in on auth page, redirecting');
          // Redirect based on user role
          switch (currentUser.role) {
            case Role.admin:
              debugPrint('➡️ Router: Redirecting to /admin (Admin)');
              return '/admin';
            case Role.lecturer:
              debugPrint('➡️ Router: Redirecting to /admin (Lecturer)');
              return '/admin';
            case Role.student:
            default:
              debugPrint('➡️ Router: Redirecting to /home (Student)');
              return '/home';
          }
        }
      }
      
      debugPrint('✓ Router: No redirect needed');
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/labs/:id',
        name: 'lab-detail',
        builder: (context, state) {
          final labId = state.pathParameters['id']!;
          return LabDetailScreen(labId: labId);
        },
      ),
      GoRoute(
        path: '/bookings/new',
        name: 'booking-form',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BookingFormScreen(
            roomId: extra?['roomId'],
            selectedDate: extra?['selectedDate'],
            selectedStartTime: extra?['selectedStartTime'],
            selectedEndTime: extra?['selectedEndTime'],
          );
        },
      ),
      GoRoute(
        path: '/qr-ticket',
        name: 'qr-ticket',
        builder: (context, state) {
          final booking = state.extra as Booking;
          return QRTicketScreen(booking: booking);
        },
      ),
      GoRoute(
        path: '/admin',
        name: 'admin-dashboard',
        redirect: (context, state) {
          final authState = ref.read(authControllerProvider);
          final currentUser = authState.when(
            data: (user) => user,
            loading: () => null,
            error: (_, __) => null,
          );
          
          // Only admin and lecturer can access admin routes
          if (currentUser?.role != Role.admin && currentUser?.role != Role.lecturer) {
            return '/home';
          }
          return null;
        },
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'labs',
            name: 'manage-labs',
            redirect: (context, state) {
              final authState = ref.read(authControllerProvider);
              final currentUser = authState.when(
                data: (user) => user,
                loading: () => null,
                error: (_, __) => null,
              );
              
              // Only admin and lecturer can manage labs
              if (currentUser?.role != Role.admin && currentUser?.role != Role.lecturer) {
                return '/home';
              }
              return null;
            },
            builder: (context, state) => const ManageLabsScreen(),
          ),
          GoRoute(
            path: 'events',
            name: 'manage-events',
            redirect: (context, state) {
              final authState = ref.read(authControllerProvider);
              final currentUser = authState.when(
                data: (user) => user,
                loading: () => null,
                error: (_, __) => null,
              );
              
              // Only admin can manage events
              if (currentUser?.role != Role.admin) {
                return '/home';
              }
              return null;
            },
            builder: (context, state) => const ManageEventsScreen(),
          ),
        ],
      ),
    ],
  );
});

