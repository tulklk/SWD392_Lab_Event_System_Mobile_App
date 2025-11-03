import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/room.dart';
import '../../domain/models/room_slot.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/room_slot_repository.dart';
import '../../core/utils/result.dart';

class LabsScreen extends ConsumerStatefulWidget {
  const LabsScreen({super.key});

  @override
  ConsumerState<LabsScreen> createState() => _LabsScreenState();
}

class _LabsScreenState extends ConsumerState<LabsScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<Room> _allRooms = [];
  List<Room> _filteredRooms = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int? _selectedCapacity;
  int? _selectedStatus; // 0: all, 1: active, 2: maintenance
  DateTime? _lastRefreshTime;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRooms();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      debugPrint('📱 Labs: App resumed, refreshing...');
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
      debugPrint('🔄 Labs: Checking for refresh...');
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (_isLoading) {
      debugPrint('⏭️ Labs: Already loading, skipping...');
      return;
    }
    
    debugPrint('🔄 Labs: Refreshing data...');
    _lastRefreshTime = DateTime.now();
    await _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
    });

    final roomRepository = ref.read(roomRepositoryProvider);
    final result = await roomRepository.getAllRooms();
    
    if (result.isSuccess) {
      setState(() {
        _allRooms = result.data!;
        _filteredRooms = _allRooms;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterRooms() {
    setState(() {
      _filteredRooms = _allRooms.where((room) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final nameMatch = room.name.toLowerCase().contains(_searchQuery.toLowerCase());
          if (!nameMatch) return false;
        }

        // Capacity filter
        if (_selectedCapacity != null && room.capacity < _selectedCapacity!) {
          return false;
        }

        // Status filter
        if (_selectedStatus != null && room.status != _selectedStatus) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Rooms & Labs',
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

    final totalRooms = _allRooms.length;
    final activeRooms = _allRooms.where((r) => r.status == 1).length;
    final maintenanceRooms = _allRooms.where((r) => r.status == 2).length;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Rooms & Labs',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadRooms,
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
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterRooms();
              },
              decoration: const InputDecoration(
                hintText: 'Search rooms...',
                hintStyle: TextStyle(color: Color(0xFF64748B)),
                prefixIcon: Icon(Icons.search, color: Color(0xFF64748B)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(
                  'All',
                  _selectedStatus == null,
                  () {
                    setState(() {
                      _selectedStatus = null;
                    });
                    _filterRooms();
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Active',
                  _selectedStatus == 1,
                  () {
                    setState(() {
                      _selectedStatus = 1;
                    });
                    _filterRooms();
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Maintenance',
                  _selectedStatus == 2,
                  () {
                    setState(() {
                      _selectedStatus = 2;
                    });
                    _filterRooms();
                  },
                ),
                const SizedBox(width: 8),
                _buildCapacityFilter(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Room Stats
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    totalRooms.toString(),
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
                    activeRooms.toString(),
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
                    maintenanceRooms.toString(),
                    'Maintenance',
                    const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Results Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredRooms.length} Rooms',
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
        
          // Rooms list
          Expanded(
            child: _filteredRooms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No rooms found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = _filteredRooms[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildRoomCard(room),
                      );
                    },
                  ),
          ),
      ],
    ),
  );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6600) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6600) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCapacityFilter() {
    return PopupMenuButton<int>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedCapacity != null ? const Color(0xFFFF6600) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedCapacity != null
                ? const Color(0xFFFF6600)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCapacity != null ? 'Capacity: $_selectedCapacity+' : 'Capacity',
              style: TextStyle(
                color: _selectedCapacity != null ? Colors.white : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: _selectedCapacity != null ? Colors.white : const Color(0xFF64748B),
              size: 20,
            ),
          ],
        ),
      ),
      onSelected: (value) {
        setState(() {
          _selectedCapacity = value == 0 ? null : value;
        });
        _filterRooms();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 0, child: Text('All')),
        const PopupMenuItem(value: 10, child: Text('10+ people')),
        const PopupMenuItem(value: 20, child: Text('20+ people')),
        const PopupMenuItem(value: 30, child: Text('30+ people')),
        const PopupMenuItem(value: 50, child: Text('50+ people')),
      ],
    );
  }

  Widget _buildRoomCard(Room room) {
    final statusColor = room.status == 1
        ? const Color(0xFF10B981)
        : room.status == 2
            ? const Color(0xFFF59E0B)
            : const Color(0xFF64748B);
    
    final statusText = room.status == 1
        ? 'Active'
        : room.status == 2
            ? 'Maintenance'
            : 'Inactive';

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room image placeholder
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A73E8).withOpacity(0.8),
                  const Color(0xFFFF6600).withOpacity(0.6),
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.meeting_room,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Room name and status
          Row(
            children: [
              Expanded(
                child: Text(
                  room.name,
                  style: const TextStyle(
                    fontSize: 18,
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
                  statusText,
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

          // Capacity
          Row(
            children: [
              const Icon(
                Icons.people,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                'Capacity: ${room.capacity} people',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showRoomDetails(room);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (room.isActive) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _bookRoom(room);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6600),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
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

  void _showRoomDetails(Room room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RoomDetailsSheet(room: room),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bookRoom(Room room) async {
    // Navigate to booking form and wait for result
    await context.push('/bookings/new', extra: {
      'roomId': room.id,
      'roomName': room.name,
    });
    // Note: Booking form will return true if booking was successful
    // Parent screens (like My Bookings) can listen to this result
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

// Room Details Bottom Sheet with Slots
class _RoomDetailsSheet extends StatefulWidget {
  final Room room;
  
  const _RoomDetailsSheet({required this.room});

  @override
  State<_RoomDetailsSheet> createState() => _RoomDetailsSheetState();
}

class _RoomDetailsSheetState extends State<_RoomDetailsSheet> {
  final _roomSlotRepository = RoomSlotRepository();
  List<RoomSlot> _roomSlots = [];
  bool _isLoadingSlots = true;

  @override
  void initState() {
    super.initState();
    _loadRoomSlots();
  }

  Future<void> _loadRoomSlots() async {
    setState(() => _isLoadingSlots = true);
    
    final result = await _roomSlotRepository.getSlotsByRoomId(widget.room.id);
    
    if (result.isSuccess && mounted) {
      setState(() {
        _roomSlots = result.data!;
        _isLoadingSlots = false;
      });
    } else {
      setState(() => _isLoadingSlots = false);
    }
  }

  Map<int, List<RoomSlot>> _groupSlotsByDay() {
    final Map<int, List<RoomSlot>> grouped = {};
    
    for (final slot in _roomSlots) {
      if (!grouped.containsKey(slot.dayOfWeek)) {
        grouped[slot.dayOfWeek] = [];
      }
      grouped[slot.dayOfWeek]!.add(slot);
    }
    
    // Sort slots within each day by start time
    for (final slots in grouped.values) {
      slots.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    
    return grouped;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final slotsByDay = _groupSlotsByDay();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Room details content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room Name
                  Text(
                    widget.room.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Room Info
                  _buildDetailRow(
                    Icons.people,
                    'Capacity',
                    '${widget.room.capacity} people',
                  ),
                  _buildDetailRow(
                    Icons.info_outline,
                    'Status',
                    widget.room.isActive ? 'Active' : 'Maintenance',
                  ),
                  
                  // Room Slots Section
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        color: Color(0xFF1A73E8),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Available Time Slots',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      if (_isLoadingSlots)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Slots by Day
                  if (!_isLoadingSlots) ...[
                    if (_roomSlots.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No time slots configured for this room yet.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...List.generate(7, (dayIndex) {
                        final dayOfWeek = dayIndex + 1; // 1-7
                        final slots = slotsByDay[dayOfWeek] ?? [];
                        
                        if (slots.isEmpty) return const SizedBox.shrink();
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Day Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A73E8).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: const Color(0xFF1A73E8),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getDayName(dayOfWeek),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A73E8),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${slots.length} slots',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: const Color(0xFF1A73E8).withOpacity(0.7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Slots for this day
                              ...slots.asMap().entries.map((entry) {
                                final index = entry.key;
                                final slot = entry.value;
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Slot ${index + 1}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      }),
                  ],
                ],
              ),
            ),
          ),
          
          // Action button
          if (widget.room.isActive)
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to booking form
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SizedBox(), // Will be replaced by router
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6600),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Book This Room',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }
}
