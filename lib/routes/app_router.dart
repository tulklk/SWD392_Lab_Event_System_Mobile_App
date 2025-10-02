import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/result.dart';
import '../domain/enums/role.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/labs/lab_detail_screen.dart';
import '../features/bookings/booking_form_screen.dart';
import '../features/bookings/qr_ticket_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/manage_labs_screen.dart';
import '../features/admin/manage_events_screen.dart';
import '../features/auth/auth_controller.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      print('Router redirect called for path: ${state.uri.path}');
      final authState = ref.read(authControllerProvider);
      final currentUser = authState.when(
        data: (user) => user,
        loading: () => null,
        error: (_, __) => null,
      );
      print('Current user: ${currentUser?.name} (${currentUser?.role})');
      
      // If no user is logged in and not on splash or login page, redirect to splash
      if (currentUser == null && state.uri.path != '/' && state.uri.path != '/login') {
        print('No user found, redirecting to splash');
        return '/';
      }
      
      // If user is logged in and on splash or login page, redirect to home
      if (currentUser != null && (state.uri.path == '/' || state.uri.path == '/login')) {
        print('User logged in, redirecting to home');
        return '/home';
      }
      
      print('No redirect needed');
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
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
            labId: extra?['labId'],
            selectedDate: extra?['selectedDate'],
            selectedStartTime: extra?['selectedStartTime'],
            selectedEndTime: extra?['selectedEndTime'],
          );
        },
      ),
      GoRoute(
        path: '/bookings/:id/qr',
        name: 'qr-ticket',
        builder: (context, state) {
          final bookingId = state.pathParameters['id']!;
          return QRTicketScreen(bookingId: bookingId);
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
          
          // Only admin and lab manager can access admin routes
          if (currentUser?.role != Role.admin && currentUser?.role != Role.labManager) {
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
              
              // Only admin and lab manager can manage labs
              if (currentUser?.role != Role.admin && currentUser?.role != Role.labManager) {
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

