import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/booking.dart';
import '../../domain/enums/booking_status.dart';
import '../../data/repositories/booking_repository.dart';
import '../../core/utils/result.dart';
import '../auth/auth_controller.dart';
import 'booking_detail_bottomsheet.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final bookingRepository = BookingRepository();
    await bookingRepository.init();
    
    final result = await bookingRepository.getBookingsForUser(currentUser.id);
    if (result.isSuccess) {
      setState(() {
        _bookings = result.data!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final bookingRepository = BookingRepository();
    await bookingRepository.init();
    
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBookingCard(
          'Machine Learning Workshop',
          'Mon, Dec 23 • 10:00 AM - 12:00 PM',
          'Computer Lab A • Building A, Floor 2',
          '25 participants',
          'Repeats weekly',
          'Confirmed',
          const Color(0xFF10B981),
          showQR: true,
        ),
        const SizedBox(height: 16),
        _buildBookingCard(
          'Database Design Session',
          'Tue, Dec 24 • 2:00 PM - 4:00 PM',
          'Computer Lab B • Building A, Floor 3',
          '20 participants',
          '',
          'Pending',
          const Color(0xFFF59E0B),
        ),
        const SizedBox(height: 16),
        _buildBookingCard(
          'Mobile App Development',
          'Wed, Dec 25 • 9:00 AM - 11:00 AM',
          'Computer Lab C • Building B, Floor 1',
          '30 participants',
          '',
          'Confirmed',
          const Color(0xFF10B981),
          showQR: true,
        ),
      ],
    );
  }

  Widget _buildPastBookings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBookingCard(
          'Web Development Workshop',
          'Mon, Dec 16 • 2:00 PM - 4:00 PM',
          'Computer Lab A • Building A, Floor 2',
          '25 participants',
          '',
          'Completed',
          const Color(0xFF64748B),
        ),
        const SizedBox(height: 16),
        _buildBookingCard(
          'Python Programming',
          'Fri, Dec 13 • 10:00 AM - 12:00 PM',
          'Computer Lab B • Building A, Floor 3',
          '30 participants',
          '',
          'Completed',
          const Color(0xFF64748B),
        ),
      ],
    );
  }

  Widget _buildBookingCard(
    String title,
    String datetime,
    String location,
    String participants,
    String repeats,
    String status,
    Color statusColor, {
    bool showQR = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF6600),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
          const SizedBox(height: 12),
          
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                datetime,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          Row(
            children: [
              const Icon(
                Icons.people,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                participants,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          
          if (repeats.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.repeat,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  repeats,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              if (showQR) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // View QR
                    },
                    icon: const Icon(
                      Icons.qr_code,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    label: const Text(
                      'View QR',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Options
                  },
                  icon: const Icon(
                    Icons.more_horiz,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  label: const Text(
                    'Options',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status, ThemeData theme) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.approved:
        return Colors.green;
      case BookingStatus.rejected:
        return Colors.red;
      case BookingStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.approved:
        return Icons.check_circle;
      case BookingStatus.rejected:
        return Icons.cancel;
      case BookingStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showBookingDetail(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BookingDetailBottomSheet(booking: booking),
    );
  }

  void _showCancelDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel "${booking.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelBooking(booking.id);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
