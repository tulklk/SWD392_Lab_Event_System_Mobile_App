import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/event_registration_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/event_repository.dart';
import '../../domain/models/event_registration.dart';
import '../../domain/models/user.dart';
import '../../domain/models/event.dart';

final eventRegistrationsProvider = FutureProvider.family<List<EventRegistration>, String>(
  (ref, eventId) async {
    final repo = ref.watch(eventRegistrationRepositoryProvider);
    final result = await repo.getRegistrationsForEvent(eventId);
    return result.data ?? [];
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
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          event.location ?? 'No location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
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
    final repo = ref.read(eventRegistrationRepositoryProvider);
    final result = await repo.approveRegistration(id);

    if (mounted) {
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Registration approved'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(eventRegistrationsProvider(widget.eventId));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to approve'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

