import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/event.dart';
import '../../domain/models/room.dart';
import '../../domain/models/lab.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/lab_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/models/user.dart' as app_models;
import '../auth/auth_controller.dart';
import '../bookings/booking_providers.dart';

class StudentEventsScreen extends ConsumerStatefulWidget {
  const StudentEventsScreen({super.key});

  @override
  ConsumerState<StudentEventsScreen> createState() => _StudentEventsScreenState();
}

class _StudentEventsScreenState extends ConsumerState<StudentEventsScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DateTime? _lastRefreshTime;
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadEvents();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      debugPrint('📱 Events: App resumed, refreshing...');
      _refreshData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndRefresh();
  }

  void _checkAndRefresh() {
    final now = DateTime.now();
    if (_lastRefreshTime == null ||
        now.difference(_lastRefreshTime!).inSeconds > 5) {
      debugPrint('🔄 Events: Checking for refresh...');
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (_isLoading) {
      debugPrint('⏭️ Events: Already loading, skipping...');
      return;
    }

    debugPrint('🔄 Events: Refreshing data...');
    _lastRefreshTime = DateTime.now();
    await _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    final eventRepository = EventRepository();
    final result = await eventRepository.getPublicEvents();

    if (result.isSuccess && mounted) {
      // Sort events by createdAt descending (newest first)
      final sortedEvents = result.data!..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _allEvents = sortedEvents;
        _filteredEvents = _allEvents;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to load events'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterEvents() {
    setState(() {
      _filteredEvents = _allEvents.where((event) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final titleMatch = event.title.toLowerCase().contains(_searchQuery.toLowerCase());
          final descMatch = event.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
          if (!titleMatch && !descMatch) return false;
        }

        // Only show active events
        return event.isActive;
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by createdAt descending (newest first)
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6600),
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
          'Events',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadEvents,
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterEvents();
              },
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search events...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _filterEvents();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: const Color(0xFFFF6600).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Results Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredEvents.length} Events',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Events list
          Expanded(
            child: _filteredEvents.isEmpty
                ? Center(
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
                          'No events found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadEvents,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = _filteredEvents[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _StudentEventCard(event: event),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

}

// Event Card Widget for Student
class _StudentEventCard extends ConsumerStatefulWidget {
  final Event event;

  const _StudentEventCard({
    required this.event,
  });

  @override
  ConsumerState<_StudentEventCard> createState() => _StudentEventCardState();
}

class _StudentEventCardState extends ConsumerState<_StudentEventCard> {
  List<Room> _rooms = [];
  Lab? _lab;
  bool _isLoadingRoomLab = false;
  bool _isRegistered = false;
  bool _isCheckingRegistration = true;
  app_models.User? _creator;
  bool _isLoadingCreator = false;

  @override
  void initState() {
    super.initState();
    _loadRoomAndLab();
    _checkRegistration();
    _loadCreator();
  }

  Future<void> _loadCreator() async {
    setState(() => _isLoadingCreator = true);
    try {
      final userRepository = ref.read(userRepositoryProvider);
      final result = await userRepository.getUserById(widget.event.createdBy);
      if (result.isSuccess && result.data != null) {
        setState(() {
          _creator = result.data;
          _isLoadingCreator = false;
        });
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
      final eventRepository = EventRepository();
      final roomRepository = RoomRepository();
      final labRepository = LabRepository();

      // Get all room IDs for event (for entire lab booking)
      final roomIdsResult = await eventRepository.getEventRoomIds(widget.event.id);

      List<Room> loadedRooms = [];
      String? labId;

      if (roomIdsResult.isSuccess && roomIdsResult.data != null && roomIdsResult.data!.isNotEmpty) {
        // Load all rooms
        for (final roomId in roomIdsResult.data!) {
          final roomResult = await roomRepository.getRoomById(roomId);
          if (roomResult.isSuccess && roomResult.data != null) {
            loadedRooms.add(roomResult.data!);

            // Get labId from first room
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
                debugPrint('Could not get LabId from room: $e');
              }
            }
          }
        }
      } else {
        // Fallback: try to get single roomId and labId (for single room booking)
        final infoResult = await eventRepository.getEventRoomAndLabInfo(widget.event.id);

        if (infoResult.isSuccess && infoResult.data != null) {
          final roomId = infoResult.data!['roomId'];
          labId = infoResult.data!['labId'];

          if (roomId != null && roomId.isNotEmpty) {
            final roomResult = await roomRepository.getRoomById(roomId);
            if (roomResult.isSuccess && roomResult.data != null) {
              loadedRooms.add(roomResult.data!);
            }
          }
        }
      }

      // Load Lab
      if (labId != null && labId.isNotEmpty) {
        final labResult = await labRepository.getLabById(labId);
        if (labResult.isSuccess && labResult.data != null && mounted) {
          setState(() => _lab = labResult.data);
        } else {
          final labsResult = await labRepository.getLabsFromSupabase();
          if (labsResult.isSuccess && labsResult.data != null && mounted) {
            try {
              final lab = labsResult.data!.firstWhere(
                (l) => l.id == labId,
              );
              setState(() => _lab = lab);
            } catch (e) {
              debugPrint('Lab with id $labId not found');
            }
          }
        }
      }

      if (mounted) {
        setState(() => _rooms = loadedRooms);
      }
    } catch (e) {
      debugPrint('Error loading rooms/lab: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingRoomLab = false);
      }
    }
  }

  Future<void> _checkRegistration() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() => _isCheckingRegistration = false);
      return;
    }

    try {
      final bookingRepository = BookingRepository();
      final result = await bookingRepository.hasUserBookedEvent(
        widget.event.id,
        currentUser.id,
      );

      if (result.isSuccess && mounted) {
        setState(() {
          _isRegistered = result.data!;
          _isCheckingRegistration = false;
        });
      } else {
        setState(() => _isCheckingRegistration = false);
      }
    } catch (e) {
      debugPrint('Error checking registration: $e');
      setState(() => _isCheckingRegistration = false);
    }
  }

  Future<void> _registerForEvent() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to register for events'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if event has required data
    if (widget.event.startDate == null || widget.event.endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event dates are not set. Cannot register.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get room ID(s) from event
    if (_rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room information not available. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If multiple rooms, let user choose
    Room? selectedRoom = _rooms.first;
    if (_rooms.length > 1) {
      final roomResult = await showDialog<Room>(
        context: context,
        builder: (context) {
          Room? tempSelectedRoom = _rooms.first;
          
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.room, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    const Text('Select Room'),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _rooms.map((room) {
                      return RadioListTile<Room>(
                        title: Text(
                          room.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Capacity: ${room.capacity} seats'),
                        value: room,
                        groupValue: tempSelectedRoom,
                        activeColor: const Color(0xFFFF6600),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              tempSelectedRoom = value;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, tempSelectedRoom),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6600),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Select'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (roomResult == null) return; // User cancelled
      selectedRoom = roomResult;
    }

    // Check capacity (from rooms)
    if (_rooms.isNotEmpty) {
      final totalCapacity = _rooms.fold<int>(0, (sum, room) => sum + room.capacity);
      final bookingRepository = BookingRepository();
      final bookingsResult = await bookingRepository.getBookingsForEvent(widget.event.id);
      
      if (bookingsResult.isSuccess) {
        final approvedCount = bookingsResult.data!
            .where((b) => b.status == 1) // approved
            .length;
        
        if (approvedCount >= totalCapacity) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Event is full. Cannot register.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Register for Event'),
        content: Text('Do you want to register for "${widget.event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6600),
              foregroundColor: Colors.white,
            ),
            child: const Text('Register'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Register for event (create booking)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registering...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    try {
      final bookingRepository = BookingRepository();
      final result = await bookingRepository.createEventBooking(
        eventId: widget.event.id,
        roomId: selectedRoom!.id,
        userId: currentUser.id,
        startTime: widget.event.startDate!,
        endTime: widget.event.endDate!,
        notes: 'Event registration for ${widget.event.title}',
      );

      if (mounted) {
        if (result.isSuccess) {
          setState(() => _isRegistered = true);
          
          // Trigger refresh of Registrations screen by incrementing the provider
          ref.read(myBookingsRefreshProvider.notifier).refresh();
          // Signal navigation to Registrations tab (index 3 for students)
          ref.read(navigateToMyBookingsProvider.notifier).navigate();
          debugPrint('✅ Event booking created successfully. Registrations refresh signal sent.');
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully registered for event!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to register'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 0:
        return Icons.edit_outlined;
      case 1:
        return Icons.check_circle_outline;
      case 2:
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'Draft';
      case 1:
        return 'Active';
      case 2:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          // Show event details
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
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(widget.event.description!),
                      const SizedBox(height: 12),
                    ],
                    if (widget.event.startDate != null && widget.event.endDate != null) ...[
                      const Text(
                        'Time:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${timeFormat.format(widget.event.startDate!)} - ${timeFormat.format(widget.event.endDate!)}'),
                      const SizedBox(height: 12),
                    ],
                    if (_lab != null) ...[
                      const Text(
                        'Lab:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_lab!.name),
                      const SizedBox(height: 12),
                    ],
                    if (_rooms.isNotEmpty) ...[
                      Text(
                        'Room${_rooms.length > 1 ? 's' : ''}:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_rooms.map((r) => r.name).join(', ')),
                      const SizedBox(height: 12),
                      const Text(
                        'Capacity:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${_rooms.fold<int>(0, (sum, room) => sum + room.capacity)} people'),
                      const SizedBox(height: 12),
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Image
              if (widget.event.imageUrl != null && widget.event.imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: widget.event.imageUrl!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.event.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(widget.event.status),
                          size: 14,
                          color: _getStatusColor(widget.event.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(widget.event.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(widget.event.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (widget.event.visibility)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.public, size: 12, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'Public',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.event.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.event.description != null) ...[
                const SizedBox(height: 4),
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
              // Lecturer info
              if (_creator != null || _isLoadingCreator) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
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
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    widget.event.startDate != null
                        ? dateFormat.format(widget.event.startDate!)
                        : 'No date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (widget.event.startDate != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${timeFormat.format(widget.event.startDate!)} - ${widget.event.endDate != null ? timeFormat.format(widget.event.endDate!) : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              // Lab and Room info
              if (_lab != null || _rooms.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_lab != null) ...[
                      Icon(Icons.science, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Text(
                        _lab!.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (_rooms.isNotEmpty) ...[
                      if (_lab != null) const SizedBox(width: 8),
                      Icon(Icons.room, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        _rooms.length == 1
                            ? _rooms.first.name
                            : '${_rooms.length} rooms: ${_rooms.map((r) => r.name).join(', ')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              // Capacity (from rooms)
              if (_rooms.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Capacity: ${_rooms.fold<int>(0, (sum, room) => sum + room.capacity)} people',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              // Register Button
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: _isCheckingRegistration
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _isRegistered
                        ? OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text('Registered'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: widget.event.isActive ? _registerForEvent : null,
                            icon: const Icon(Icons.event_available, size: 18),
                            label: const Text('Book Event'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6600),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

