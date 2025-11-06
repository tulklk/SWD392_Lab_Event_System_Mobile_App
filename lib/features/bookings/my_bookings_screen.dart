import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../domain/models/booking.dart';
import '../../domain/enums/booking_status.dart';
import '../../domain/enums/role.dart';
import '../../domain/models/room.dart';
import '../../domain/models/lab.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/lab_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/event_repository.dart';
import '../../domain/models/user.dart' as app_models;
import '../../domain/models/event.dart';
import '../../core/utils/result.dart';
import '../auth/auth_controller.dart';
import 'booking_providers.dart';
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
  int _lastRefreshTrigger = 0; // Track the refresh provider state

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
  void didUpdateWidget(MyBookingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When widget key changes (triggered by refresh), reload bookings
    if (widget.key != oldWidget.key) {
      debugPrint('🔄 My Bookings: Widget key changed, refreshing...');
      _lastRefreshTime = null; // Reset to force refresh
      _refreshData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when returning to this screen (e.g., when tab becomes visible)
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
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const TabBar(
                tabs: [
                  Tab(
                    child: Text(
                      'Upcoming',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Tab(
                    child: Text(
                      'Past',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                labelColor: Color(0xFFFF6600),
                unselectedLabelColor: Color(0xFF64748B),
                indicatorColor: Color(0xFFFF6600),
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
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
    final allUpcomingBookings = _bookings
        .where((b) => b.isPending || (b.endTime.isAfter(now) && !b.isCancelled))
        .toList();
    
    // Separate into Pending and Approved
    final pendingBookings = allUpcomingBookings
        .where((b) => b.isPending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
    
    final approvedBookings = allUpcomingBookings
        .where((b) => b.isApproved && !b.isPending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
    
    debugPrint('🔍 Total bookings: ${_bookings.length}');
    debugPrint('⏳ Pending bookings: ${pendingBookings.length}');
    debugPrint('✅ Approved bookings: ${approvedBookings.length}');
    
    if (pendingBookings.isEmpty && approvedBookings.isEmpty) {
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pending Section
          if (pendingBookings.isNotEmpty) ...[
            _buildSectionHeader('Pending', pendingBookings.length, const Color(0xFFF59E0B)),
            const SizedBox(height: 12),
            ...pendingBookings.asMap().entries.map((entry) {
              final index = entry.key;
              final booking = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < pendingBookings.length - 1 ? 16 : 24),
                child: _BookingCardWithRoom(
                  booking: booking,
                  isUpcoming: true,
                  onCancel: _showCancelDialog,
                ),
              );
            }),
          ],
          
          // Approved Section
          if (approvedBookings.isNotEmpty) ...[
            _buildSectionHeader('Approved', approvedBookings.length, const Color(0xFF10B981)),
            const SizedBox(height: 12),
            ...approvedBookings.asMap().entries.map((entry) {
              final index = entry.key;
              final booking = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < approvedBookings.length - 1 ? 16 : 0),
                child: _BookingCardWithRoom(
                  booking: booking,
                  isUpcoming: true,
                  onCancel: _showCancelDialog,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first (mới nhất lên đầu)
    
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
            child: _BookingCardWithRoom(
              booking: booking,
              isUpcoming: false,
              onCancel: _showCancelDialog,
            ),
          );
        },
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

// Widget to display booking card with Lab and Room info
class _BookingCardWithRoom extends ConsumerStatefulWidget {
  final Booking booking;
  final bool isUpcoming;
  final Function(Booking) onCancel;

  const _BookingCardWithRoom({
    required this.booking,
    required this.isUpcoming,
    required this.onCancel,
  });

  @override
  ConsumerState<_BookingCardWithRoom> createState() => _BookingCardWithRoomState();
}

class _BookingCardWithRoomState extends ConsumerState<_BookingCardWithRoom> {
  Room? _room;
  Lab? _lab;
  bool _isLoadingRoomLab = true;
  app_models.User? _creator;
  bool _isLoadingCreator = false;

  @override
  void initState() {
    super.initState();
    _loadRoomAndLab();
    _loadCreator();
  }

  Future<void> _loadCreator() async {
    if (widget.booking.eventId == null || widget.booking.eventId!.isEmpty) {
      return;
    }
    
    setState(() => _isLoadingCreator = true);
    try {
      final eventRepository = EventRepository();
      final eventResult = await eventRepository.getEventById(widget.booking.eventId!);
      
      if (eventResult.isSuccess && eventResult.data != null) {
        final event = eventResult.data!;
        final userRepository = UserRepository();
        final userResult = await userRepository.getUserById(event.createdBy);
        
        if (userResult.isSuccess && userResult.data != null && mounted) {
          setState(() {
            _creator = userResult.data;
            _isLoadingCreator = false;
          });
        } else {
          setState(() => _isLoadingCreator = false);
        }
      } else {
        setState(() => _isLoadingCreator = false);
      }
    } catch (e) {
      debugPrint('Error loading creator: $e');
      setState(() => _isLoadingCreator = false);
    }
  }

  Future<void> _loadRoomAndLab() async {
    setState(() => _isLoadingRoomLab = true);

    try {
      final roomRepository = RoomRepository();
      final labRepository = LabRepository();

      // Load Room
      final roomResult = await roomRepository.getRoomById(widget.booking.roomId);
      if (roomResult.isSuccess && roomResult.data != null) {
        setState(() => _room = roomResult.data);

        // Get LabId from Room
        String? labId;
        try {
          final supabase = Supabase.instance.client;
          final roomResponse = await supabase
              .from('tbl_rooms')
              .select('LabId')
              .eq('Id', widget.booking.roomId)
              .maybeSingle();
          if (roomResponse != null && roomResponse['LabId'] != null) {
            labId = roomResponse['LabId']?.toString();
          }
        } catch (e) {
          debugPrint('Could not get LabId from room: $e');
        }

        // Load Lab
        if (labId != null && labId.isNotEmpty) {
          final labResult = await labRepository.getLabById(labId);
          if (labResult.isSuccess && labResult.data != null && mounted) {
            setState(() => _lab = labResult.data);
          } else {
            // Try from Supabase if not in Hive
            final labsResult = await labRepository.getLabsFromSupabase();
            if (labsResult.isSuccess && labsResult.data != null && mounted) {
              try {
                final lab = labsResult.data!.firstWhere((l) => l.id == labId);
                setState(() => _lab = lab);
              } catch (e) {
                debugPrint('Lab with id $labId not found');
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading room/lab: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingRoomLab = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.booking.bookingStatus);
    final currentUser = ref.watch(currentUserProvider);
    final isStudent = currentUser?.role == Role.student;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.booking.purpose,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.booking.bookingStatus.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Lab and Room info - Simple layout
            if (_lab != null || _room != null || _isLoadingRoomLab) ...[
              if (_isLoadingRoomLab)
                Row(
                  children: [
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 8),
                    Text(
                      'Loading location...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                )
              else ...[
                if (_lab != null) ...[
                  Row(
                    children: [
                      Icon(Icons.science, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        _lab!.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (_room != null) ...[
                  Row(
                    children: [
                      Icon(Icons.room, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        _room!.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ],
            
            // Date and Time - Simple rows
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _formatDate(widget.booking.date),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${_formatTime(widget.booking.start)} - ${_formatTime(widget.booking.end)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            
            // Notes - Simple text
            if (widget.booking.notes != null && widget.booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.booking.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            // Lecturer info
            if (_creator != null || _isLoadingCreator) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  if (_isLoadingCreator)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey[600],
                      ),
                    )
                  else
                    Text(
                      'Lecturer: ${_creator?.fullname ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
            
            // Action buttons
            if (widget.isUpcoming && widget.booking.isApproved) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/qr-ticket', extra: widget.booking);
                  },
                  icon: const Icon(Icons.qr_code, size: 18),
                  label: const Text('View QR Ticket'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6600),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
            
            // Cancel button - ONLY for Admin/Lecturer, NOT for Student
            if (widget.isUpcoming && !widget.booking.isCancelled && !isStudent) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => widget.onCancel(widget.booking),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel Booking'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red[700]!, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
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
