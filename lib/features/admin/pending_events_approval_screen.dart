import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/event.dart';
import '../../domain/models/user.dart' as app_models;
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/user_repository.dart';

/// Screen for Admin to approve or reject pending events created by Lecturers
class PendingEventsApprovalScreen extends ConsumerStatefulWidget {
  const PendingEventsApprovalScreen({super.key});

  @override
  ConsumerState<PendingEventsApprovalScreen> createState() => _PendingEventsApprovalScreenState();
}

class _PendingEventsApprovalScreenState extends ConsumerState<PendingEventsApprovalScreen> {
  List<Event> _pendingEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingEvents();
  }

  Future<void> _loadPendingEvents() async {
    setState(() => _isLoading = true);

    final eventRepository = EventRepository();
    final result = await eventRepository.getPendingEvents();

    if (result.isSuccess && mounted) {
      setState(() {
        _pendingEvents = result.data!;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to load pending events'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveEvent(Event event) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Approve Event'),
          ],
        ),
        content: Text('Do you want to approve the event "${event.title}"?\n\nThis will make it visible to all students.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Approving event...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    // Approve event
    final eventRepository = EventRepository();
    final result = await eventRepository.approveEvent(event.id);

    if (mounted) {
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload list
        _loadPendingEvents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to approve event'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectEvent(Event event) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('Reject Event'),
          ],
        ),
        content: Text('Do you want to reject the event "${event.title}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rejecting event...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    // Reject event
    final eventRepository = EventRepository();
    final result = await eventRepository.rejectEvent(event.id);

    if (mounted) {
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event rejected successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
        // Reload list
        _loadPendingEvents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to reject event'),
            backgroundColor: Colors.red,
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
        title: const Text(
          'Pending Events Approval',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadPendingEvents,
            icon: const Icon(Icons.refresh, color: Color(0xFF1E293B)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6600),
              ),
            )
          : _pendingEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending events',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All events have been reviewed',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingEvents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingEvents.length,
                    itemBuilder: (context, index) {
                      final event = _pendingEvents[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _PendingEventCard(
                          event: event,
                          onApprove: () => _approveEvent(event),
                          onReject: () => _rejectEvent(event),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _PendingEventCard extends ConsumerStatefulWidget {
  final Event event;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingEventCard({
    required this.event,
    required this.onApprove,
    required this.onReject,
  });

  @override
  ConsumerState<_PendingEventCard> createState() => _PendingEventCardState();
}

class _PendingEventCardState extends ConsumerState<_PendingEventCard> {
  app_models.User? _creator;
  bool _isLoadingCreator = false;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange[200]!, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pending Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_empty, size: 16, color: Colors.orange[900]),
                      const SizedBox(width: 4),
                      Text(
                        'PENDING APPROVAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange[900],
                          letterSpacing: 0.5,
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
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Event Title
            Text(
              widget.event.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),

            // Event Description
            if (widget.event.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.event.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Creator Info
            if (_creator != null || _isLoadingCreator) ...[
              Row(
                children: [
                  Icon(Icons.person_outline, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  if (_isLoadingCreator)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey[600],
                      ),
                    )
                  else
                    Expanded(
                      child: Text(
                        'Created by: ${_creator?.fullname ?? 'Unknown'} (${_creator?.role.displayName ?? 'N/A'})',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Date & Time
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  widget.event.startDate != null
                      ? dateFormat.format(widget.event.startDate!)
                      : 'No date',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.event.startDate != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '${timeFormat.format(widget.event.startDate!)} - ${widget.event.endDate != null ? timeFormat.format(widget.event.endDate!) : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),

            // Capacity
            if (widget.event.capacity != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Capacity: ${widget.event.capacity} people',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: widget.onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

