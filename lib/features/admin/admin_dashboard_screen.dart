import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/role.dart';
import '../auth/auth_controller.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final isLabManager = ref.watch(isLabManagerProvider);
    
    // Check if user has admin privileges
    if (!isAdmin && !isLabManager) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Color(0xFF64748B),
              ),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You need admin or lab manager privileges to access this page.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Admin Dashboard',
                            style: TextStyle(
                              fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
      body: DefaultTabController(
        length: 3,
                    child: Column(
                    children: [
                      Container(
                              color: Colors.white,
              child: const TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Labs'),
                  Tab(text: 'Bookings'),
                ],
                labelColor: Color(0xFF1E293B),
                unselectedLabelColor: Color(0xFF64748B),
                indicatorColor: Color(0xFFFF6600),
                indicatorWeight: 3,
              ),
            ),
          Expanded(
              child: TabBarView(
              children: [
                  _buildOverviewTab(),
                  _buildLabsTab(),
                  _buildBookingsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard('12', 'Total Labs', const Color(0xFF1A73E8), Icons.location_on),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('48', 'Active Bookings', const Color(0xFF10B981), Icons.calendar_today),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
                children: [
                  Expanded(
                child: _buildStatCard('1,234', 'Total Users', const Color(0xFF8B5CF6), Icons.people),
              ),
              const SizedBox(width: 16),
                    Expanded(
                child: _buildStatCard('156', 'This Week', const Color(0xFFF59E0B), Icons.bar_chart),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Recent Bookings Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Bookings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF1A73E8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildBookingItem(
            'Machine Learning Workshop',
            'Computer Lab A • Dec 23 at 10:00 AM',
            'By Dr. Smith • 25 participants',
            'confirmed',
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _buildBookingItem(
            'Database Design Session',
            'Computer Lab B • Dec 24 at 2:00 PM',
            'By Prof. Johnson • 20 participants',
            'pending',
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          _buildBookingItem(
            'Mobile Development',
            'Computer Lab C • Dec 25 at 9:00 AM',
            'By Dr. Wilson • 30 participants',
            'confirmed',
            const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildLabsTab() {
    return const Center(
      child: Text('Labs management coming soon'),
    );
  }

  Widget _buildBookingsTab() {
    return const Center(
      child: Text('Bookings management coming soon'),
    );
  }

  Widget _buildStatCard(String value, String label, Color color, IconData icon) {
    return Container(
        padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Text(
              value,
                    style: TextStyle(
                      fontSize: 28,
                fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingItem(
    String title,
    String schedule,
    String organizer,
    String status,
    Color statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                title,
                        style: const TextStyle(
                          fontSize: 16,
                  fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
              ),
              const SizedBox(height: 8),
              Text(
                  schedule,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  organizer,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}