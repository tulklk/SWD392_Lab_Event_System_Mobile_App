import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../domain/models/equipment.dart';
import '../../domain/models/room.dart';
import 'equipment_providers.dart';

class EquipmentScreen extends ConsumerStatefulWidget {
  const EquipmentScreen({super.key});

  @override
  ConsumerState<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends ConsumerState<EquipmentScreen>
    with AutomaticKeepAliveClientMixin {
  String _selectedRoomId = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final roomsAsync = ref.watch(roomsProvider);
    final equipmentAsync = ref.watch(filteredEquipmentProvider((
      roomId: _selectedRoomId == 'all' ? null : _selectedRoomId,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    )));

    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search equipment...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Room Filter
          roomsAsync.when(
            data: (rooms) {
              if (rooms.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _RoomFilterChip(
                      label: 'All Rooms',
                      isSelected: _selectedRoomId == 'all',
                      onTap: () {
                        setState(() => _selectedRoomId = 'all');
                      },
                    ),
                    const SizedBox(width: 8),
                    ...rooms.map((room) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _RoomFilterChip(
                            label: room.name,
                            isSelected: _selectedRoomId == room.id,
                            onTap: () {
                              setState(() => _selectedRoomId = room.id);
                            },
                          ),
                        )),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Equipment List
          Expanded(
            child: equipmentAsync.when(
              data: (equipmentList) {
                if (equipmentList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No equipment found'
                              : 'No equipment available',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Equipment will appear here',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(roomsProvider);
                    ref.invalidate(filteredEquipmentProvider((
                      roomId: _selectedRoomId == 'all' ? null : _selectedRoomId,
                      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
                    )));
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: equipmentList.length,
                    itemBuilder: (context, index) {
                      final equipment = equipmentList[index];
                      return _EquipmentCard(
                        equipment: equipment,
                        onTap: () => _showEquipmentDetails(context, equipment),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load equipment',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(filteredEquipmentProvider((
                          roomId: _selectedRoomId == 'all' ? null : _selectedRoomId,
                          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
                        )));
                      },
                      child: const Text('Retry'),
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

  void _showEquipmentDetails(BuildContext context, Equipment equipment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EquipmentDetailSheet(equipment: equipment),
    );
  }
}

class _RoomFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoomFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _EquipmentCard extends ConsumerWidget {
  final Equipment equipment;
  final VoidCallback onTap;

  const _EquipmentCard({
    required this.equipment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomProvider(equipment.roomId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Equipment Image/Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getStatusColor(equipment.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: equipment.imageUrl != null && equipment.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: equipment.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _getStatusColor(equipment.status),
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            _getEquipmentIcon(equipment.type),
                            size: 40,
                            color: _getStatusColor(equipment.status),
                          ),
                        ),
                      )
                    : Icon(
                        _getEquipmentIcon(equipment.type),
                        size: 40,
                        color: _getStatusColor(equipment.status),
                      ),
              ),
              const SizedBox(width: 16),
              // Equipment Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            equipment.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        _StatusBadge(status: equipment.status),
                      ],
                    ),
                    if (equipment.description != null &&
                        equipment.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        equipment.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Room Info
                    roomAsync.when(
                      data: (room) => Row(
                        children: [
                          Icon(
                            Icons.room,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            room?.name ?? 'Unknown Room',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.blue[700],
                                ),
                          ),
                        ],
                      ),
                      loading: () => const SizedBox(
                        height: 16,
                        child: LinearProgressIndicator(),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    if (equipment.serialNumber != null &&
                        equipment.serialNumber!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'SN: ${equipment.serialNumber}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 11,
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
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getEquipmentIcon(int type) {
    // You can customize icons based on equipment type
    return Icons.devices;
  }
}

class _StatusBadge extends StatelessWidget {
  final int status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (status) {
      case 0:
        label = 'Inactive';
        color = Colors.grey;
        break;
      case 1:
        label = 'Available';
        color = Colors.green;
        break;
      case 2:
        label = 'Maintenance';
        color = Colors.orange;
        break;
      default:
        label = 'Unknown';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EquipmentDetailSheet extends ConsumerWidget {
  final Equipment equipment;

  const _EquipmentDetailSheet({required this.equipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomProvider(equipment.roomId));

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      equipment.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    if (equipment.imageUrl != null &&
                        equipment.imageUrl!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 200,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: equipment.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.devices,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ),

                    // Status
                    _StatusBadge(status: equipment.status),
                    const SizedBox(height: 20),

                    // Description
                    if (equipment.description != null &&
                        equipment.description!.isNotEmpty) ...[
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        equipment.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Details
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.room,
                      label: 'Room',
                      value: roomAsync.when(
                        data: (room) => room?.name ?? 'Unknown',
                        loading: () => 'Loading...',
                        error: (_, __) => 'Unknown',
                      ),
                    ),
                    if (equipment.serialNumber != null &&
                        equipment.serialNumber!.isNotEmpty)
                      _DetailRow(
                        icon: Icons.qr_code,
                        label: 'Serial Number',
                        value: equipment.serialNumber!,
                      ),
                    _DetailRow(
                      icon: Icons.category,
                      label: 'Type',
                      value: 'Type ${equipment.type}',
                    ),
                    if (equipment.lastMaintenanceDate != null)
                      _DetailRow(
                        icon: Icons.build,
                        label: 'Last Maintenance',
                        value: DateFormat('MMM d, yyyy')
                            .format(equipment.lastMaintenanceDate!),
                      ),
                    if (equipment.nextMaintenanceDate != null)
                      _DetailRow(
                        icon: Icons.schedule,
                        label: 'Next Maintenance',
                        value: DateFormat('MMM d, yyyy')
                            .format(equipment.nextMaintenanceDate!),
                      ),
                    const SizedBox(height: 20),

                    // Borrow Button
                    if (equipment.isActive)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showBorrowDialog(context, equipment);
                          },
                          icon: const Icon(Icons.handshake_outlined),
                          label: const Text('Request to Borrow'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBorrowDialog(BuildContext context, Equipment equipment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request to Borrow Equipment'),
        content: Text(
          'You are requesting to borrow "${equipment.name}". '
          'This request will be sent to the lab administrator for approval.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Borrow request for "${equipment.name}" submitted'),
                  backgroundColor: Colors.green,
                ),
              );
              // TODO: Implement actual borrow request logic
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

