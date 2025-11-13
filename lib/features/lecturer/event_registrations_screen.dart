import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../data/repositories/event_registration_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../domain/models/event_registration.dart';
import '../../domain/models/user.dart';
import '../../domain/models/event.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/room.dart';
import 'pending_bookings_screen.dart';

final eventRegistrationsProvider = FutureProvider.family<List<EventRegistration>, String>(
  (ref, eventId) async {
    debugPrint('🔍 [EventRegistrationsProvider] Called with eventId: $eventId');
    final repo = ref.watch(eventRegistrationRepositoryProvider);
    final result = await repo.getRegistrationsForEvent(eventId);
    debugPrint('📊 [EventRegistrationsProvider] Result: ${result.isSuccess ? '${result.data?.length ?? 0} registrations' : result.error}');
    return result.data ?? [];
  },
);

// Provider to get bookings with roomId for an event
final eventBookingsProvider = FutureProvider.family<List<Booking>, String>(
  (ref, eventId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('tbl_bookings')
          .select()
          .eq('EventId', eventId)
          .order('CreatedAt', ascending: false);

      if (response == null || response.isEmpty) {
        return [];
      }

      final bookings = (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();

      return bookings;
    } catch (e) {
      debugPrint('Error getting bookings: $e');
      return [];
    }
  },
);

// Provider to get room IDs from event (from room slots)
final eventRoomIdsProvider = FutureProvider.family<List<String>, String>(
  (ref, eventId) async {
    try {
      final eventRepository = ref.watch(eventRepositoryProvider);
      final result = await eventRepository.getEventRoomIds(eventId);
      if (result.isSuccess && result.data != null) {
        return result.data!;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting event room IDs: $e');
      return [];
    }
  },
);

final eventDetailsProvider = FutureProvider.family<Event?, String>(
  (ref, eventId) async {
    final repo = ref.watch(eventRepositoryProvider);
    final result = await repo.getEventById(eventId);
    return result.data;
  },
);

class EventRegistrationsScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventRegistrationsScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<EventRegistrationsScreen> createState() => _EventRegistrationsScreenState();
}

class _EventRegistrationsScreenState extends ConsumerState<EventRegistrationsScreen> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    debugPrint('🎯 EventRegistrationsScreen: Building with eventId = ${widget.eventId}');
    
    final registrationsAsync = ref.watch(eventRegistrationsProvider(widget.eventId));
    final eventAsync = ref.watch(eventDetailsProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Registrations'),
        actions: [
          if (_isSelectionMode) ...[
            TextButton.icon(
              onPressed: _selectedIds.isEmpty ? null : _handleBulkApprove,
              icon: const Icon(Icons.check_circle, size: 18),
              label: Text('Approve (${_selectedIds.length})'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedIds.clear();
                });
              },
              icon: const Icon(Icons.close),
            ),
          ] else ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
              icon: const Icon(Icons.checklist),
              tooltip: 'Bulk Approve Mode',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Event Info Header
          eventAsync.when(
            data: (event) {
              if (event == null) return const SizedBox();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6600).withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          event.startDate != null
                              ? DateFormat('MMM dd, yyyy').format(event.startDate!)
                              : 'No date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),

          // Registrations List
          Expanded(
            child: registrationsAsync.when(
              data: (registrations) {
                if (registrations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No registrations yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final pendingCount = registrations.where((r) => r.isPending).length;
                final approvedCount = registrations.where((r) => r.isApproved).length;
                final rejectedCount = registrations.where((r) => r.isRejected).length;

                // Check if event has multiple rooms from event slots
                final eventRoomIdsAsync = ref.watch(eventRoomIdsProvider(widget.eventId));
                final bookingsAsync = ref.watch(eventBookingsProvider(widget.eventId));
                
                return eventRoomIdsAsync.when(
                  data: (eventRoomIds) {
                    // Check if event has multiple rooms
                    final hasMultipleRooms = eventRoomIds.length > 1;
                    
                    debugPrint('🔍 Event has ${eventRoomIds.length} rooms: $eventRoomIds');
                    debugPrint('   Has multiple rooms: $hasMultipleRooms');

                    if (hasMultipleRooms) {
                      // Group by room - use event room IDs
                      return bookingsAsync.when(
                        data: (bookings) {
                          return _buildGroupedByRoom(
                            registrations: registrations,
                            bookings: bookings,
                            roomIds: eventRoomIds, // Use event room IDs, not booking room IDs
                            pendingCount: pendingCount,
                            approvedCount: approvedCount,
                            rejectedCount: rejectedCount,
                            ref: ref,
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => _buildGroupedByRoom(
                          registrations: registrations,
                          bookings: [],
                          roomIds: eventRoomIds,
                          pendingCount: pendingCount,
                          approvedCount: approvedCount,
                          rejectedCount: rejectedCount,
                          ref: ref,
                        ),
                      );
                    } else {
                      // Single room - show flat list
                      return _buildFlatList(
                        registrations: registrations,
                        pendingCount: pendingCount,
                        approvedCount: approvedCount,
                        rejectedCount: rejectedCount,
                        ref: ref,
                      );
                    }
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => bookingsAsync.when(
                    data: (bookings) {
                      // Fallback: check from bookings
                      final roomIds = bookings.map((b) => b.roomId).toSet().toList();
                      final hasMultipleRooms = roomIds.length > 1;
                      
                      if (hasMultipleRooms) {
                        return _buildGroupedByRoom(
                          registrations: registrations,
                          bookings: bookings,
                          roomIds: roomIds,
                          pendingCount: pendingCount,
                          approvedCount: approvedCount,
                          rejectedCount: rejectedCount,
                          ref: ref,
                        );
                      } else {
                        return _buildFlatList(
                          registrations: registrations,
                          pendingCount: pendingCount,
                          approvedCount: approvedCount,
                          rejectedCount: rejectedCount,
                          ref: ref,
                        );
                      }
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _buildFlatList(
                      registrations: registrations,
                      pendingCount: pendingCount,
                      approvedCount: approvedCount,
                      rejectedCount: rejectedCount,
                      ref: ref,
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading registrations',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(String id) async {
    debugPrint('🎯 EventRegistrationsScreen: _handleApprove called with ID: $id');
    debugPrint('   Event ID: ${widget.eventId}');
    
    final repo = ref.read(eventRegistrationRepositoryProvider);
    debugPrint('✅ EventRegistrationsScreen: Repository obtained, calling approveRegistration...');
    
    final result = await repo.approveRegistration(id);
    
    debugPrint('📋 EventRegistrationsScreen: approveRegistration result:');
    debugPrint('   Success: ${result.isSuccess}');
    if (!result.isSuccess) {
      debugPrint('   Error: ${result.error}');
    }

    if (mounted) {
      if (result.isSuccess) {
        debugPrint('✅ EventRegistrationsScreen: Approval successful, showing success message');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Registration approved'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(eventRegistrationsProvider(widget.eventId));
        ref.invalidate(eventBookingsProvider(widget.eventId));
        // Also refresh pending bookings in Approvals tab
        ref.invalidate(pendingBookingsProvider);
      } else {
        debugPrint('❌ EventRegistrationsScreen: Approval failed, showing error message');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to approve'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      debugPrint('⚠️ EventRegistrationsScreen: Widget not mounted, cannot show message');
    }
  }

  Future<void> _handleReject(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Registration'),
        content: const Text('Are you sure you want to reject this registration?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(eventRegistrationRepositoryProvider);
      final result = await repo.rejectRegistration(id);

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration rejected'),
              backgroundColor: Colors.orange,
            ),
          );
          ref.invalidate(eventRegistrationsProvider(widget.eventId));
          ref.invalidate(eventBookingsProvider(widget.eventId));
          // Also refresh pending bookings in Approvals tab
          ref.invalidate(pendingBookingsProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to reject'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleBulkApprove() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Approve'),
        content: Text('Approve ${_selectedIds.length} registration(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(eventRegistrationRepositoryProvider);
      final result = await repo.bulkApproveRegistrations(_selectedIds.toList());

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${_selectedIds.length} registration(s) approved'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isSelectionMode = false;
            _selectedIds.clear();
          });
          ref.invalidate(eventRegistrationsProvider(widget.eventId));
          ref.invalidate(eventBookingsProvider(widget.eventId));
          // Also refresh pending bookings in Approvals tab
          ref.invalidate(pendingBookingsProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to bulk approve'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildFlatList({
    required List<EventRegistration> registrations,
    required int pendingCount,
    required int approvedCount,
    required int rejectedCount,
    required WidgetRef ref,
  }) {
    return Column(
      children: [
        // Stats Row
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _StatChip(
                label: 'Pending',
                count: pendingCount,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Approved',
                count: approvedCount,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Rejected',
                count: rejectedCount,
                color: Colors.red,
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(eventRegistrationsProvider(widget.eventId));
              ref.invalidate(eventBookingsProvider(widget.eventId));
              ref.invalidate(eventRoomIdsProvider(widget.eventId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: registrations.length,
              itemBuilder: (context, index) {
                final registration = registrations[index];
                final isSelected = _selectedIds.contains(registration.id);

                return _RegistrationCard(
                  registration: registration,
                  isSelectionMode: _isSelectionMode,
                  isSelected: isSelected,
                  onSelectionChanged: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedIds.add(registration.id);
                      } else {
                        _selectedIds.remove(registration.id);
                      }
                    });
                  },
                  onApprove: () => _handleApprove(registration.id),
                  onReject: () => _handleReject(registration.id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedByRoom({
    required List<EventRegistration> registrations,
    required List<Booking> bookings,
    required List<String> roomIds,
    required int pendingCount,
    required int approvedCount,
    required int rejectedCount,
    required WidgetRef ref,
  }) {
    // Create a map of registrationId -> booking (to get roomId)
    final registrationIdToBooking = <String, Booking>{};
    for (final booking in bookings) {
      registrationIdToBooking[booking.id] = booking;
    }

    // Group registrations by roomId
    final registrationsByRoom = <String, List<EventRegistration>>{};
    for (final registration in registrations) {
      final booking = registrationIdToBooking[registration.id];
      if (booking != null) {
        final roomId = booking.roomId;
        if (!registrationsByRoom.containsKey(roomId)) {
          registrationsByRoom[roomId] = [];
        }
        registrationsByRoom[roomId]!.add(registration);
      }
    }

    return Column(
      children: [
        // Stats Row
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _StatChip(
                label: 'Pending',
                count: pendingCount,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Approved',
                count: approvedCount,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Rejected',
                count: rejectedCount,
                color: Colors.red,
              ),
            ],
          ),
        ),

        // Grouped List by Room
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(eventRegistrationsProvider(widget.eventId));
              ref.invalidate(eventBookingsProvider(widget.eventId));
              ref.invalidate(eventRoomIdsProvider(widget.eventId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: roomIds.length,
              itemBuilder: (context, roomIndex) {
                final roomId = roomIds[roomIndex];
                final roomRegistrations = registrationsByRoom[roomId] ?? [];

                return _RoomGroupSection(
                  roomId: roomId,
                  registrations: roomRegistrations,
                  bookings: bookings,
                  isSelectionMode: _isSelectionMode,
                  selectedIds: _selectedIds,
                  onSelectionChanged: (registrationId, selected) {
                    setState(() {
                      if (selected) {
                        _selectedIds.add(registrationId);
                      } else {
                        _selectedIds.remove(registrationId);
                      }
                    });
                  },
                  onApprove: (id) => _handleApprove(id),
                  onReject: (id) => _handleReject(id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationCard extends ConsumerWidget {
  final EventRegistration registration;
  final bool isSelectionMode;
  final bool isSelected;
  final Function(bool) onSelectionChanged;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RegistrationCard({
    required this.registration,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFFFF6600)
              : registration.isPending
                  ? Colors.orange[200]!
                  : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: isSelectionMode && registration.isPending
            ? () => onSelectionChanged(!isSelected)
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isSelectionMode && registration.isPending)
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) => onSelectionChanged(value ?? false),
                    ),
                  _StatusBadge(status: registration.status),
                  const Spacer(),
                  Text(
                    _getTimeAgo(registration.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // User info
              FutureBuilder<User?>(
                future: _getUser(ref, registration.userId),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  return Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6600), Color(0xFFFF8533)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            user?.fullname[0].toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullname ?? 'Loading...',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (user?.mssv != null)
                              Text(
                                'MSSV: ${user!.mssv}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              if (registration.notes != null && registration.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    registration.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],

              if (registration.isApproved && registration.attendanceCode != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Attendance Code: ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        registration.attendanceCode!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: registration.attendanceCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copy code',
                      ),
                    ],
                  ),
                ),
              ],

              if (registration.isPending && !isSelectionMode) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
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

  Future<User?> _getUser(WidgetRef ref, String userId) async {
    final userRepository = ref.read(userRepositoryProvider);
    final result = await userRepository.getUserById(userId);
    return result.data;
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final int status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 0:
        color = Colors.orange;
        icon = Icons.pending_actions;
        label = 'Pending';
        break;
      case 1:
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Approved';
        break;
      case 2:
        color = Colors.red;
        icon = Icons.cancel;
        label = 'Rejected';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Room Group Section Widget
class _RoomGroupSection extends ConsumerStatefulWidget {
  final String roomId;
  final List<EventRegistration> registrations;
  final List<Booking> bookings;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final Function(String, bool) onSelectionChanged;
  final Function(String) onApprove;
  final Function(String) onReject;

  const _RoomGroupSection({
    required this.roomId,
    required this.registrations,
    required this.bookings,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.onApprove,
    required this.onReject,
  });

  @override
  ConsumerState<_RoomGroupSection> createState() => _RoomGroupSectionState();
}

class _RoomGroupSectionState extends ConsumerState<_RoomGroupSection> {
  Room? _room;
  bool _isLoadingRoom = true;

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  Future<void> _loadRoom() async {
    try {
      final roomRepository = RoomRepository();
      final result = await roomRepository.getRoomById(widget.roomId);
      if (result.isSuccess && result.data != null && mounted) {
        setState(() {
          _room = result.data;
          _isLoadingRoom = false;
        });
      } else {
        setState(() => _isLoadingRoom = false);
      }
    } catch (e) {
      debugPrint('Error loading room: $e');
      if (mounted) {
        setState(() => _isLoadingRoom = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.registrations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.room, size: 20, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isLoadingRoom
                      ? 'Loading...'
                      : _room?.name ?? 'Room ${widget.roomId}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.registrations.length} student${widget.registrations.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Registrations for this room
        ...widget.registrations.map((registration) {
          final isSelected = widget.selectedIds.contains(registration.id);
          return _RegistrationCard(
            registration: registration,
            isSelectionMode: widget.isSelectionMode,
            isSelected: isSelected,
            onSelectionChanged: (selected) => widget.onSelectionChanged(registration.id, selected),
            onApprove: () => widget.onApprove(registration.id),
            onReject: () => widget.onReject(registration.id),
          );
        }),

        const SizedBox(height: 16),
      ],
    );
  }
}

