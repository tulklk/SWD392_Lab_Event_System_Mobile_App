import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/booking.dart';
import '../../domain/enums/booking_status.dart';
import '../../domain/enums/role.dart';
import '../../data/repositories/booking_repository.dart';
import '../../core/utils/result.dart';
import '../auth/auth_controller.dart';
import 'booking_detail_bottomsheet.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> 
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<Booking> _bookings = [];
  bool _isLoading = false;
  DateTime? _lastRefreshTime;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBookings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app resumes
    if (state == AppLifecycleState.resumed && mounted) {
      debugPrint('📱 My Bookings: App resumed, refreshing...');
      _refreshData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always refresh when dependencies change (e.g., when tab becomes visible)
    final now = DateTime.now();
    if (_lastRefreshTime == null || 
        now.difference(_lastRefreshTime!).inSeconds > 2) {
      debugPrint('🔄 My Bookings: Dependencies changed, refreshing...');
      _refreshData();
    }
  }

  void _checkAndRefresh() {
    final now = DateTime.now();
    if (_lastRefreshTime == null || 
        now.difference(_lastRefreshTime!).inSeconds > 2) {
      debugPrint('🔄 My Bookings: Checking for refresh...');
      _refreshData();
    }
  }
  
  // Public method to refresh from outside
  void refreshBookings() {
    debugPrint('🔄 My Bookings: Manual refresh triggered');
    _refreshData();
  }

  Future<void> _refreshData() async {
    if (_isLoading) {
      debugPrint('⏭️ My Bookings: Already loading, skipping...');
      return;
    }
    
    debugPrint('🔄 My Bookings: Refreshing data...');
    _lastRefreshTime = DateTime.now();
    await _loadBookings();
  }

  Future<void> _loadBookings() async {
    // Prevent duplicate calls
    if (_isLoading) {
      debugPrint('⏭️ Already loading, skipping...');
      return;
    }
    
    if (mounted) {
      setState(() {
        _isLoading = true;
        _lastRefreshTime = DateTime.now();
      });
    }
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    debugPrint('🔄 Loading bookings for user ${currentUser.id}...');
    final bookingRepository = BookingRepository();
    
    final result = await bookingRepository.getBookingsForUser(currentUser.id);
    
    if (!mounted) return;
    
    if (result.isSuccess) {
      debugPrint('📚 Loaded ${result.data!.length} bookings');
      setState(() {
        _bookings = result.data!;
        _isLoading = false;
      });
    } else {
      debugPrint('❌ Failed to load bookings: ${result.error}');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Failed to load bookings')),
      );
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final bookingRepository = BookingRepository();
    
    final result = await bookingRepository.cancelBooking(bookingId);
    if (result.isSuccess) {
      _loadBookings(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E293B)),
            onPressed: _loadBookings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                tabs: [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Past'),
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
                  _buildUpcomingBookings(),
                  _buildPastBookings(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingBookings() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final now = DateTime.now();
    // Upcoming: TẤT CẢ Pending (chờ duyệt) HOẶC (chưa kết thúc VÀ không cancelled)
    final upcomingBookings = _bookings
        .where((b) => b.isPending || (b.endTime.isAfter(now) && !b.isCancelled))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    debugPrint('🔍 Total bookings: ${_bookings.length}');
    debugPrint('✅ Upcoming bookings: ${upcomingBookings.length}');
    for (final b in upcomingBookings) {
      final statusText = b.isPending ? 'Pending (chờ duyệt)' 
          : b.isApproved ? 'Approved' 
          : b.isRejected ? 'Rejected' 
          : 'Cancelled';
      debugPrint('  - ${b.purpose} | ${b.startTime} - ${b.endTime} | Status: $statusText');
    }
    
    if (upcomingBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No upcoming bookings',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                // Navigate to Labs/Booking
                await context.push('/labs');
                // Force refresh when coming back
                if (mounted) {
                  debugPrint('↩️ User returned from Labs, refreshing...');
                  await Future.delayed(const Duration(milliseconds: 500));
                  if (mounted) {
                    await _loadBookings();
                  }
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Book a Room'),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: upcomingBookings.length,
        itemBuilder: (context, index) {
          final booking = upcomingBookings[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index < upcomingBookings.length - 1 ? 16 : 0),
            child: _buildBookingCard(booking, isUpcoming: true),
          );
        },
      ),
    );
  }

  Widget _buildPastBookings() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final now = DateTime.now();
    // Past: (Đã kết thúc HOẶC Cancelled) VÀ KHÔNG phải Pending
    final pastBookings = _bookings
        .where((b) => (b.endTime.isBefore(now) || b.isCancelled) && !b.isPending)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    
    debugPrint('📚 Past bookings: ${pastBookings.length}');
    for (final b in pastBookings) {
      final statusText = b.isCancelled ? 'Cancelled' 
          : b.isRejected ? 'Rejected' 
          : b.isApproved ? 'Completed' 
          : 'Other';
      debugPrint('  - ${b.purpose} | ${b.startTime} - ${b.endTime} | Status: $statusText');
    }
    
    if (pastBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No past bookings',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pastBookings.length,
        itemBuilder: (context, index) {
          final booking = pastBookings[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index < pastBookings.length - 1 ? 16 : 0),
            child: _buildBookingCard(booking, isUpcoming: false),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, {required bool isUpcoming}) {
    final statusColor = _getStatusColor(booking.bookingStatus);
    final currentUser = ref.watch(currentUserProvider);
    final isStudent = currentUser?.role == Role.student;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.purpose,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.bookingStatus.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                _formatDate(booking.date),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                '${_formatTime(booking.start)} - ${_formatTime(booking.end)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.note, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.notes!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              // QR Code button for approved bookings
              if (isUpcoming && booking.isApproved) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/qr-ticket', extra: booking);
                    },
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: const Text('View QR'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A73E8),
                      side: const BorderSide(color: Color(0xFF1A73E8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              // Cancel button - ONLY for Admin/Lecturer, NOT for Student
              if (isUpcoming && !booking.isCancelled && !isStudent) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelDialog(booking),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelBooking(booking.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return const Color(0xFFF59E0B);
      case BookingStatus.approved:
        return const Color(0xFF10B981);
      case BookingStatus.rejected:
        return const Color(0xFFEF4444);
      case BookingStatus.cancelled:
        return const Color(0xFF64748B);
    }
  }

  String _formatDate(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
