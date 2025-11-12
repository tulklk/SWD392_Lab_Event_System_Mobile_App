import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_controller.dart';
import '../../domain/models/event.dart';
import '../../domain/models/room.dart';
import '../../domain/models/lab.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/lab_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/models/user.dart' as app_models;

class StudentDashboardPage extends ConsumerStatefulWidget {
  final Function(int)? onTabChange;
  
  const StudentDashboardPage({
    super.key,
    this.onTabChange,
  });

  @override
  ConsumerState<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends ConsumerState<StudentDashboardPage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<Event> _upcomingEvents = [];
  List<Event> _allEvents = [];
  bool _isLoadingEvents = true;
  DateTime? _lastRefreshTime;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUpcomingEvents();
    _loadAllEvents(); // Load all events for stats
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      debugPrint('📱 Home: App resumed, refreshing...');
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
      debugPrint('🔄 Home: Checking for refresh...');
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (_isLoadingEvents) {
      debugPrint('⏭️ Home: Already loading, skipping...');
      return;
    }
    
    debugPrint('🔄 Home: Refreshing data...');
    _lastRefreshTime = DateTime.now();
    await _loadUpcomingEvents();
    await _loadAllEvents();
  }

  Future<void> _loadUpcomingEvents() async {
    setState(() => _isLoadingEvents = true);
    
    final eventRepository = EventRepository();
    final result = await eventRepository.getUpcomingEvents();
    
    if (mounted) {
      setState(() {
        if (result.isSuccess && result.data != null) {
          // Sort by CreatedAt descending (newest first) and take only 3
          final sortedEvents = List<Event>.from(result.data!)
            ..sort((a, b) {
              // Sort by CreatedAt descending (newest first)
              final aCreated = a.createdAt ?? DateTime(1970);
              final bCreated = b.createdAt ?? DateTime(1970);
              return bCreated.compareTo(aCreated);
            });
          _upcomingEvents = sortedEvents.take(3).toList();
        } else {
          _upcomingEvents = [];
        }
        _isLoadingEvents = false;
      });
    }
  }

  Future<void> _loadAllEvents() async {
    final eventRepository = EventRepository();
    final result = await eventRepository.getPublicEvents();
    
    debugPrint('📊 Loading all events for stats...');
    debugPrint('   Result success: ${result.isSuccess}');
    debugPrint('   Events count: ${result.data?.length ?? 0}');
    
    if (mounted && result.isSuccess) {
      setState(() {
        _allEvents = result.data!;
      });
      debugPrint('   ✅ Loaded ${_allEvents.length} events');
      debugPrint('   Active: ${_allEvents.where((e) => e.isActive).length}');
      debugPrint('   Upcoming: ${_allEvents.where((e) {
        if (e.startDate == null) return false;
        return e.startDate!.isAfter(DateTime.now());
      }).length}');
    } else if (mounted) {
      debugPrint('   ❌ Failed to load events: ${result.error}');
    }
  }

  String _formatEventTime(Event event) {
    if (event.startDate == null || event.endDate == null) return '';
    final startTime = DateFormat('h:mm a').format(event.startDate!);
    final endTime = DateFormat('h:mm a').format(event.endDate!);
    return '$startTime - $endTime';
  }

  String _getEventStatus(Event event) {
    if (event.startDate == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(
      event.startDate!.year,
      event.startDate!.month,
      event.startDate!.day,
    );
    
    final diff = eventDate.difference(today).inDays;
    
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('EEE, MMM d').format(eventDate);
  }

  Color _getEventStatusColor(Event event) {
    if (event.startDate == null) return const Color(0xFF64748B);
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(
      event.startDate!.year,
      event.startDate!.month,
      event.startDate!.day,
    );
    
    final diff = eventDate.difference(today).inDays;
    
    if (diff == 0) return const Color(0xFFEF4444); // Red for today
    if (diff == 1) return const Color(0xFFF59E0B); // Orange for tomorrow
    return const Color(0xFF1A73E8); // Blue for future
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final currentUser = ref.watch(currentUserProvider);
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome back section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
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
                        const Text(
                          'Welcome back!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUser?.fullname ?? 'Student',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    icon: Icons.event,
                    iconColor: const Color(0xFF1A73E8),
                    iconBackgroundColor: const Color(0xFF1A73E8).withOpacity(0.1),
                    title: 'View Events',
                    onTap: () {
                      // Switch to Events tab (index 2 for student)
                      widget.onTabChange?.call(2);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    icon: Icons.check_circle,
                    iconColor: const Color(0xFF10B981),
                    iconBackgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                    title: 'My Bookings',
                    onTap: () {
                      // Switch to My Bookings tab (index 3 for student)
                      widget.onTabChange?.call(3);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Event Status
            const Text(
              'Event Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),

            // Event Stats
            Container(
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
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      _allEvents.length.toString(),
                      'Total',
                      const Color(0xFF1A73E8),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      _allEvents.where((e) => e.isActive).length.toString(),
                      'Active',
                      const Color(0xFF10B981),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      _allEvents.where((e) {
                        if (e.startDate == null) return false;
                        return e.startDate!.isAfter(DateTime.now());
                      }).length.toString(),
                      'Upcoming',
                      const Color(0xFFFF6600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Upcoming Events
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (!_isLoadingEvents)
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
            const SizedBox(height: 12),
            
            // Event Cards - Load from database
            if (_isLoadingEvents)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_upcomingEvents.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No upcoming events',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._upcomingEvents.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StudentEventCard(event: event),
              )).toList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBackgroundColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildStatItem(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
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
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Event Card Widget for Student Dashboard (similar to Lecturer but without Edit/Delete)
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
  app_models.User? _creator;
  bool _isLoadingCreator = false;

  @override
  void initState() {
    super.initState();
    _loadRoomAndLab();
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
      debugPrint('🔄 Loading rooms and lab for event: ${widget.event.id}');
      final eventRepository = EventRepository();
      final roomRepository = RoomRepository();
      final labRepository = LabRepository();
      
      // Get all room IDs for event
      final roomIdsResult = await eventRepository.getEventRoomIds(widget.event.id);
      
      List<Room> loadedRooms = [];
      String? labId;
      
      if (roomIdsResult.isSuccess && roomIdsResult.data != null && roomIdsResult.data!.isNotEmpty) {
        // Load all rooms
        for (final roomId in roomIdsResult.data!) {
          final roomResult = await roomRepository.getRoomById(roomId);
          if (roomResult.isSuccess && roomResult.data != null) {
            loadedRooms.add(roomResult.data!);
            // Get lab ID from first room
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
      
      // Load Lab
      if (labId != null && labId.isNotEmpty) {
        final labResult = await labRepository.getLabById(labId);
        if (labResult.isSuccess && labResult.data != null) {
          if (mounted) {
            setState(() => _lab = labResult.data);
          }
        } else {
          // Try from Supabase if not in Hive
          final labsResult = await labRepository.getLabsFromSupabase();
          if (labsResult.isSuccess && labsResult.data != null) {
            try {
              final lab = labsResult.data!.firstWhere(
                (l) => l.id == labId,
              );
              if (mounted) {
                setState(() => _lab = lab);
              }
            } catch (e) {
              debugPrint('Lab with id $labId not found in Supabase');
            }
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _rooms = loadedRooms;
          _isLoadingRoomLab = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading rooms/lab: $e');
      if (mounted) {
        setState(() => _isLoadingRoomLab = false);
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
          // Show event details dialog
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
                    ],
                    if (_lab != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Lab:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_lab!.name),
                    ],
                    if (_rooms.isNotEmpty) ...[
                      const SizedBox(height: 12),
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
                Row(
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
                      if (_rooms.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.room, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _rooms.length == 1
                                ? _rooms.first.name
                                : '${_rooms.length} rooms',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ] else if (_rooms.isNotEmpty) ...[
                      Icon(Icons.room, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _rooms.length == 1
                              ? _rooms.first.name
                              : '${_rooms.length} rooms',
                          style: TextStyle(
                            fontSize: 12,
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
            ],
          ),
        ),
      ),
    );
  }
}
