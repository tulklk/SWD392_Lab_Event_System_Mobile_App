import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/lab_repository.dart';
import '../../domain/models/event.dart';
import '../../domain/models/room.dart';
import '../../domain/models/lab.dart';
import '../auth/auth_controller.dart';

class LecturerEventsScreen extends ConsumerStatefulWidget {
  const LecturerEventsScreen({super.key});

  @override
  ConsumerState<LecturerEventsScreen> createState() => _LecturerEventsScreenState();
}

class _LecturerEventsScreenState extends ConsumerState<LecturerEventsScreen> {
  bool _isLoading = false;
  List<Event> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _deleteEvent(Event event) async {
    // Show confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Event'),
        content: Text('Bạn có chắc chắn muốn xóa event "${event.title}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final eventRepository = ref.read(eventRepositoryProvider);
    final result = await eventRepository.deleteEvent(event.id);

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event đã được xóa thành công'),
          backgroundColor: Colors.green,
        ),
      );
      _loadEvents(); // Reload events list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Không thể xóa event'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final eventRepository = ref.read(eventRepositoryProvider);
    // Only load events created by current lecturer
    final result = await eventRepository.getEventsByCreator(currentUser.id);

    if (result.isSuccess) {
      setState(() {
        _events = result.data ?? [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEvents,
              child: _events.isEmpty
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
                            'No events yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first event',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        return _EventCard(
                          event: event,
                          onTap: () {
                            // Navigate to event registrations
                            context.push('/lecturer/events/${event.id}/registrations');
                          },
                          onEdit: () async {
                            final result = await context.push('/lecturer/events/${event.id}/edit');
                            if (result == true) {
                              _loadEvents();
                            }
                          },
                          onDelete: () => _deleteEvent(event),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/lecturer/events/create');
        },
        backgroundColor: const Color(0xFFFF6600),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Event',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EventCard extends ConsumerStatefulWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _EventCard({
    required this.event,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  ConsumerState<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<_EventCard> {
  Room? _room;
  Lab? _lab;
  bool _isLoadingRoomLab = false;

  @override
  void initState() {
    super.initState();
    _loadRoomAndLab();
  }

  Future<void> _loadRoomAndLab() async {
    setState(() => _isLoadingRoomLab = true);
    
    try {
      debugPrint('🔄 Loading room and lab for event: ${widget.event.id}');
      final eventRepository = ref.read(eventRepositoryProvider);
      final roomRepository = RoomRepository();
      final labRepository = LabRepository();
      
      // Get roomId and labId for event
      final infoResult = await eventRepository.getEventRoomAndLabInfo(widget.event.id);
      
      debugPrint('   Info result success: ${infoResult.isSuccess}');
      debugPrint('   Data: ${infoResult.data}');
      
      if (infoResult.isSuccess && infoResult.data != null) {
        final roomId = infoResult.data!['roomId'];
        final labId = infoResult.data!['labId'];
        
        debugPrint('   Extracted roomId: $roomId, labId: $labId');
        
        // Load Room
        if (roomId != null && roomId.isNotEmpty) {
          debugPrint('   Loading room: $roomId');
          final roomResult = await roomRepository.getRoomById(roomId);
          if (roomResult.isSuccess && roomResult.data != null) {
            debugPrint('   ✅ Room loaded: ${roomResult.data!.name}');
            if (mounted) {
              setState(() => _room = roomResult.data);
            }
          } else {
            debugPrint('   ❌ Failed to load room: ${roomResult.error}');
          }
        } else {
          debugPrint('   ⚠️ No roomId found for event');
        }
        
        // Load Lab
        if (labId != null && labId.isNotEmpty) {
          debugPrint('   Loading lab: $labId');
          final labResult = await labRepository.getLabById(labId);
          if (labResult.isSuccess && labResult.data != null) {
            debugPrint('   ✅ Lab loaded from Hive: ${labResult.data!.name}');
            if (mounted) {
              setState(() => _lab = labResult.data);
            }
          } else {
            debugPrint('   ⚠️ Lab not in Hive, trying Supabase...');
            // Try from Supabase if not in Hive
            final labsResult = await labRepository.getLabsFromSupabase();
            if (labsResult.isSuccess && labsResult.data != null) {
              try {
                final lab = labsResult.data!.firstWhere(
                  (l) => l.id == labId,
                );
                debugPrint('   ✅ Lab loaded from Supabase: ${lab.name}');
                if (mounted) {
                  setState(() => _lab = lab);
                }
              } catch (e) {
                debugPrint('   ❌ Lab with id $labId not found in Supabase');
              }
            }
          }
        } else {
          debugPrint('   ⚠️ No labId found for event');
        }
      } else {
        debugPrint('   ❌ Failed to get event room/lab info: ${infoResult.error}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading room/lab: $e');
      debugPrint('   Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() => _isLoadingRoomLab = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: widget.onTap,
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
              if (_lab != null || _room != null) ...[
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
                      if (_room != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.room, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          _room!.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ] else if (_room != null) ...[
                      Icon(Icons.room, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        _room!.name,
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
              // Capacity
              if (widget.event.capacity != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Capacity: ${widget.event.capacity} people',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              if (widget.onEdit != null || widget.onDelete != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (widget.onEdit != null)
                      TextButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Event'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF6600),
                        ),
                      ),
                    if (widget.onEdit != null && widget.onDelete != null)
                      const SizedBox(width: 8),
                    if (widget.onDelete != null)
                      TextButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
}

