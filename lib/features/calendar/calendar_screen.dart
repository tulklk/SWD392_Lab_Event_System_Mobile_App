import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/event.dart';
import '../../domain/models/booking.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../core/utils/result.dart';
import '../auth/auth_controller.dart';
import '../bookings/booking_detail_bottomsheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

enum CalendarFilter { all, events, bookings }

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Event> _events = [];
  List<Booking> _bookings = [];
  CalendarFilter _selectedFilter = CalendarFilter.all;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadDataForDay(_selectedDay!);
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
        _events = eventsResult.isSuccess ? eventsResult.data! : [];
        
        // Filter bookings for selected day
        if (bookingsResult.isSuccess) {
          _bookings = bookingsResult.data!.where((booking) {
            final bookingDate = DateTime(
              booking.startTime.year,
              booking.startTime.month,
              booking.startTime.day,
            );
            final selectedDate = DateTime(day.year, day.month, day.day);
            return isSameDay(bookingDate, selectedDate);
          }).toList();
        } else {
          _bookings = [];
        }
        
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        
          // Month/Year Header with Navigation
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
          ),
          
          // Calendar Grid
          Container(
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
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
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
          ),

          // Filter Chips
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text('All (${_events.length + _bookings.length})'),
                    selected: _selectedFilter == CalendarFilter.all,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = CalendarFilter.all);
                    },
                    selectedColor: const Color(0xFFFF6600),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _selectedFilter == CalendarFilter.all
                          ? Colors.white
                          : const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text('Events (${_events.length})'),
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
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text('My Bookings (${_bookings.length})'),
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
                ],
            ),
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
    
    if (_selectedFilter == CalendarFilter.all || _selectedFilter == CalendarFilter.events) {
      for (final event in _events) {
        items.add(_buildEventCard(event));
      }
    }
    
    if (_selectedFilter == CalendarFilter.all || _selectedFilter == CalendarFilter.bookings) {
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
      onRefresh: () => _loadDataForDay(_selectedDay!),
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
    return GestureDetector(
      onTap: () {
        // Show event details in a dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(event.title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.description != null) ...[
                    const Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(event.description!),
                    const SizedBox(height: 12),
                  ],
                  if (event.location != null) ...[
                    const Text(
                      'Location:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(event.location!),
                    const SizedBox(height: 12),
                  ],
                  if (event.startDate != null && event.endDate != null) ...[
                    const Text(
                      'Time:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${_formatTime(event.startDate!)} - ${_formatTime(event.endDate!)}'),
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
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                color: const Color(0xFF1A73E8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                          event.title,
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
                          color: const Color(0xFF1A73E8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        child: const Text(
                          'Event',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (event.startDate != null && event.endDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_formatTime(event.startDate!)} - ${_formatTime(event.endDate!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                  if (event.location != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.location!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
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

  Widget _buildBookingCard(Booking booking) {
    final statusColor = booking.isPending ? const Color(0xFFF59E0B)
        : booking.isApproved ? const Color(0xFF10B981)
        : booking.isRejected ? const Color(0xFFEF4444)
        : const Color(0xFF64748B);
    
    final borderColor = booking.isPending ? const Color(0xFFF59E0B)
        : booking.isApproved ? const Color(0xFF10B981)
        : booking.isRejected ? const Color(0xFFEF4444)
        : const Color(0xFF64748B);
    
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => BookingDetailBottomSheet(booking: booking),
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
              height: 80,
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
                          booking.purpose,
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
                          booking.bookingStatus.displayName,
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
                        '${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Room ID
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
                          'Room: ${booking.roomId}',
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
                  
                  // Notes preview (if any)
                  if (booking.notes != null && booking.notes!.isNotEmpty) ...[
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
                            booking.notes!,
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
