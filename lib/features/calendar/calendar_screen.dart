import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/event.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/lab.dart';
import '../../domain/models/room.dart';
import '../../domain/models/user.dart' as app_models;
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/lab_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/utils/result.dart';
import '../auth/auth_controller.dart';
import '../bookings/booking_detail_bottomsheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

enum CalendarFilter { events, bookings }

class _CalendarScreenState extends ConsumerState<CalendarScreen> 
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Event> _events = [];
  List<Booking> _bookings = [];
  Map<String, String> _roomIdToName = {}; // Cache: roomId -> room name
  CalendarFilter _selectedFilter = CalendarFilter.events;
  bool _isLoading = false;
  DateTime? _lastRefreshTime;
  bool _isCalendarExpanded = true; // Track calendar expand/collapse state

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDay = DateTime.now();
    _initializeData(); // Initialize data properly
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app resumes or widget becomes visible
    if (state == AppLifecycleState.resumed && mounted) {
      debugPrint('📱 Calendar: App resumed, refreshing...');
      _refreshData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when user navigates back to this tab
    _checkAndRefresh();
  }

  void _checkAndRefresh() {
    final now = DateTime.now();
    // Only refresh if last refresh was more than 5 seconds ago
    if (_lastRefreshTime == null || 
        now.difference(_lastRefreshTime!).inSeconds > 5) {
      debugPrint('🔄 Calendar: Checking for refresh...');
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (_isLoading) {
      debugPrint('⏭️ Calendar: Already loading, skipping...');
      return;
    }
    
    debugPrint('🔄 Calendar: Refreshing data...');
    _lastRefreshTime = DateTime.now();
    
    await _loadRoomNames();
    if (_selectedDay != null && mounted) {
      await _loadDataForDay(_selectedDay!);
    }
  }

  Future<void> _initializeData() async {
    // Load room names FIRST, then load bookings
    await _loadRoomNames();
    await _loadDataForDay(_selectedDay!);
  }

  Future<void> _loadRoomNames() async {
    debugPrint('🏢 Loading room names...');
    final labRepository = LabRepository();
    final result = await labRepository.getAllLabs();
    
    if (result.isSuccess && result.data != null) {
      final Map<String, String> roomMap = {};
      for (final lab in result.data!) {
        if (lab.roomId != null && lab.roomId!.isNotEmpty) {
          roomMap[lab.roomId!] = lab.name;
          debugPrint('   📍 ${lab.roomId} → ${lab.name}');
        }
      }
      if (mounted) {
        setState(() {
          _roomIdToName = roomMap;
        });
        debugPrint('✅ Loaded ${roomMap.length} room names');
      }
    } else {
      debugPrint('❌ Failed to load room names: ${result.error}');
    }
  }

  Future<void> _loadDataForDay(DateTime day) async {
    setState(() => _isLoading = true);
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    // Load events
    final eventRepository = EventRepository();
    final eventsResult = await eventRepository.getEventsForDay(day);
    
    // Load bookings for current user
    final bookingRepository = BookingRepository();
    final bookingsResult = await bookingRepository.getBookingsForUser(currentUser.id);
    
    if (mounted) {
      setState(() {
        // Load events and sort by createdAt descending (newest first)
        _events = eventsResult.isSuccess 
            ? (eventsResult.data!..sort((a, b) => b.createdAt.compareTo(a.createdAt))) 
            : [];
        
        // Filter bookings for selected day and sort by createdAt descending (newest first)
        if (bookingsResult.isSuccess) {
          _bookings = bookingsResult.data!.where((booking) {
            final bookingDate = DateTime(
              booking.startTime.year,
              booking.startTime.month,
              booking.startTime.day,
            );
            final selectedDate = DateTime(day.year, day.month, day.day);
            return isSameDay(bookingDate, selectedDate);
          }).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort newest first
        } else {
          _bookings = [];
        }
        
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Calendar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      body: Column(
        children: [
        
          // Month/Year Header with Navigation and Toggle Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                    });
                  },
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isCalendarExpanded = !_isCalendarExpanded;
                        });
                      },
                      icon: Icon(
                        _isCalendarExpanded ? Icons.expand_less : Icons.expand_more,
                        color: const Color(0xFFFF6600),
                      ),
                      tooltip: _isCalendarExpanded ? 'Thu gọn lịch' : 'Mở rộng lịch',
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                        });
                      },
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Calendar Grid - AnimatedSize for smooth expand/collapse
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isCalendarExpanded
                ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    child: TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) async {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              // Ensure room names are loaded before loading bookings
              if (_roomIdToName.isEmpty) {
                await _loadRoomNames();
              }
              _loadDataForDay(selectedDay);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: (day) {
              // This would be used for showing dots on calendar
              return [];
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: const BoxDecoration(
                color: Color(0xFFFF6600),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF6600),
                  width: 2,
                ),
              ),
              weekendTextStyle: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
              defaultTextStyle: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              todayTextStyle: const TextStyle(
                color: Color(0xFFFF6600),
                fontWeight: FontWeight.w600,
              ),
            ),
            headerVisible: false,
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              weekendStyle: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
                  )
                : const SizedBox.shrink(),
          ),

          // Filter Chips
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: Center(
                      child: Text('Events (${_events.length})'),
                    ),
                    selected: _selectedFilter == CalendarFilter.events,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = CalendarFilter.events);
                    },
                    selectedColor: const Color(0xFF1A73E8),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _selectedFilter == CalendarFilter.events
                          ? Colors.white
                          : const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilterChip(
                    label: Center(
                      child: Text('My Bookings (${_bookings.length})'),
                    ),
                    selected: _selectedFilter == CalendarFilter.bookings,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = CalendarFilter.bookings);
                    },
                    selectedColor: const Color(0xFF10B981),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _selectedFilter == CalendarFilter.bookings
                          ? Colors.white
                          : const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Events for selected day header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Text(
              _selectedDay != null
                  ? '${_getDayName(_selectedDay!.weekday)}, ${_getMonthName(_selectedDay!.month)} ${_selectedDay!.day}'
                  : 'Select a date',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

        // Events for selected day
        Expanded(
          child: _buildEventsList(),
        ),
      ],
    ),
  );
  }

  Widget _buildEventsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Filter based on selected filter
    List<Widget> items = [];
    
    if (_selectedFilter == CalendarFilter.events) {
      for (final event in _events) {
        items.add(_buildEventCard(event));
      }
    }
    
    if (_selectedFilter == CalendarFilter.bookings) {
      for (final booking in _bookings) {
        items.add(_buildBookingCard(booking));
      }
    }
    
    if (items.isEmpty) {
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
              'No items for this date',
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
      onRefresh: () async {
        await _loadRoomNames(); // Reload room names
        await _loadDataForDay(_selectedDay!);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index < items.length - 1 ? 12 : 0),
            child: items[index],
          );
        },
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return _CalendarEventCard(event: event);
  }

  Widget _buildBookingCard(Booking booking) {
    return _CalendarBookingCard(booking: booking, roomIdToName: _roomIdToName);
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[weekday - 1];
  }
}

// Enhanced Event Card for Calendar with more information
class _CalendarEventCard extends ConsumerStatefulWidget {
  final Event event;

  const _CalendarEventCard({required this.event});

  @override
  ConsumerState<_CalendarEventCard> createState() => _CalendarEventCardState();
}

class _CalendarEventCardState extends ConsumerState<_CalendarEventCard> {
  List<Room> _rooms = [];
  Lab? _lab;
  bool _isLoadingInfo = true;
  app_models.User? _creator;

  @override
  void initState() {
    super.initState();
    _loadEventInfo();
  }

  Future<void> _loadEventInfo() async {
    try {
      final eventRepository = EventRepository();
      final roomRepository = RoomRepository();
      final labRepository = LabRepository();
      final userRepository = UserRepository();

      // Load creator
      final creatorResult = await userRepository.getUserById(widget.event.createdBy);
      if (creatorResult.isSuccess && creatorResult.data != null && mounted) {
        setState(() => _creator = creatorResult.data);
      }

      // Load rooms
      final roomIdsResult = await eventRepository.getEventRoomIds(widget.event.id);
      List<Room> loadedRooms = [];
      String? labId;

      if (roomIdsResult.isSuccess && roomIdsResult.data != null && roomIdsResult.data!.isNotEmpty) {
        for (final roomId in roomIdsResult.data!) {
          final roomResult = await roomRepository.getRoomById(roomId);
          if (roomResult.isSuccess && roomResult.data != null) {
            loadedRooms.add(roomResult.data!);
            if (labId == null) {
              try {
                final supabase = Supabase.instance.client;
                final roomResponse = await supabase
                    .from('tbl_rooms')
                    .select('LabId')
                    .eq('Id', roomId)
                    .maybeSingle();
                if (roomResponse != null && roomResponse['LabId'] != null) {
                  labId = roomResponse['LabId']?.toString();
                }
              } catch (e) {
                debugPrint('Error getting LabId: $e');
              }
            }
          }
        }
      }

      // Load lab
      if (labId != null && labId.isNotEmpty) {
        final labResult = await labRepository.getLabById(labId);
        if (labResult.isSuccess && labResult.data != null && mounted) {
          setState(() => _lab = labResult.data);
        }
      }

      if (mounted) {
        setState(() {
          _rooms = loadedRooms;
          _isLoadingInfo = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading event info: $e');
      if (mounted) {
        setState(() => _isLoadingInfo = false);
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Show detailed event dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(widget.event.title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.event.description != null) ...[
                    const Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.event.description!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.event.startDate != null && widget.event.endDate != null) ...[
                    const Text(
                      'Time:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatTime(widget.event.startDate!)} - ${_formatTime(widget.event.endDate!)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_creator != null) ...[
                    const Text(
                      'Lecturer:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _creator!.fullname,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_lab != null) ...[
                    const Text(
                      'Lab:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lab!.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_rooms.isNotEmpty) ...[
                    Text(
                      'Room${_rooms.length > 1 ? 's' : ''}:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _rooms.map((r) => r.name).join(', '),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.event.capacity != null) ...[
                    const Text(
                      'Capacity:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.event.capacity} people',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1A73E8), width: 2),
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
            // Header with title and badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Event',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            // Description preview
            if (widget.event.description != null && widget.event.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.event.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Time
            if (widget.event.startDate != null && widget.event.endDate != null)
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatTime(widget.event.startDate!)} - ${_formatTime(widget.event.endDate!)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            
            // Lecturer
            if (_creator != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Lecturer: ${_creator!.fullname}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            // Lab and Rooms
            if (_lab != null || _rooms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_lab != null) ...[
                    Icon(Icons.science, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Text(
                      _lab!.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_lab != null && _rooms.isNotEmpty) const SizedBox(width: 12),
                  if (_rooms.isNotEmpty) ...[
                    Icon(Icons.room, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _rooms.length == 1
                            ? _rooms.first.name
                            : '${_rooms.length} rooms',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            
            // Capacity
            if (widget.event.capacity != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Capacity: ${widget.event.capacity} people',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Enhanced Booking Card for Calendar - shows Event Name and Creator instead of Room
class _CalendarBookingCard extends ConsumerStatefulWidget {
  final Booking booking;
  final Map<String, String> roomIdToName;

  const _CalendarBookingCard({
    required this.booking,
    required this.roomIdToName,
  });

  @override
  ConsumerState<_CalendarBookingCard> createState() => _CalendarBookingCardState();
}

class _CalendarBookingCardState extends ConsumerState<_CalendarBookingCard> {
  Event? _event;
  app_models.User? _creator;
  bool _isLoadingInfo = true;

  @override
  void initState() {
    super.initState();
    _loadEventAndCreator();
  }

  Future<void> _loadEventAndCreator() async {
    if (widget.booking.eventId == null || widget.booking.eventId!.isEmpty) {
      setState(() => _isLoadingInfo = false);
      return;
    }

    try {
      final eventRepository = EventRepository();
      final userRepository = UserRepository();

      // Load event
      final eventResult = await eventRepository.getEventById(widget.booking.eventId!);
      if (eventResult.isSuccess && eventResult.data != null && mounted) {
        setState(() => _event = eventResult.data);
        
        // Load creator
        final creatorResult = await userRepository.getUserById(eventResult.data!.createdBy);
        if (creatorResult.isSuccess && creatorResult.data != null && mounted) {
          setState(() => _creator = creatorResult.data);
        }
      }

      if (mounted) {
        setState(() => _isLoadingInfo = false);
      }
    } catch (e) {
      debugPrint('Error loading event/creator: $e');
      if (mounted) {
        setState(() => _isLoadingInfo = false);
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.booking.isPending
        ? const Color(0xFFF59E0B)
        : widget.booking.isApproved
            ? const Color(0xFF10B981)
            : widget.booking.isRejected
                ? const Color(0xFFEF4444)
                : const Color(0xFF64748B);

    final borderColor = statusColor;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => BookingDetailBottomSheet(booking: widget.booking),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 5,
              height: 90,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 16),

            // Booking icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.event_note,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Booking info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Purpose + Status badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.booking.purpose,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.booking.bookingStatus.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Time
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(0xFF475569),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatTime(widget.booking.startTime)} - ${_formatTime(widget.booking.endTime)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Event Name (if it's an event booking) OR Room Name
                  if (_event != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.event,
                          size: 16,
                          color: Color(0xFF1A73E8),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _event!.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A73E8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ] else if (!_isLoadingInfo) ...[
                    // Not an event booking - show room name
                    Row(
                      children: [
                        const Icon(
                          Icons.meeting_room,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.roomIdToName[widget.booking.roomId] ??
                                'Room: ${widget.booking.roomId}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Creator Name (if available)
                  if (_creator != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Lecturer: ${_creator!.fullname}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Notes preview (if any)
                  if (widget.booking.notes != null && widget.booking.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.note,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.booking.notes!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
