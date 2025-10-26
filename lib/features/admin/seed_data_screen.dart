import 'package:flutter/material.dart';
import '../../data/seed/seed_room_slots.dart';

class SeedDataScreen extends StatefulWidget {
  const SeedDataScreen({super.key});

  @override
  State<SeedDataScreen> createState() => _SeedDataScreenState();
}

class _SeedDataScreenState extends State<SeedDataScreen> {
  final _seedRoomSlots = SeedRoomSlots();
  bool _isLoading = false;
  String _message = '';

  Future<void> _seedAllRoomSlots() async {
    setState(() {
      _isLoading = true;
      _message = 'Seeding room slots...';
    });

    final result = await _seedRoomSlots.seedSlotsForAllRooms();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _message = result.isSuccess
            ? '✅ Successfully seeded room slots for all rooms!'
            : '❌ ${result.error ?? "Failed to seed"}';
      });
    }
  }

  Future<void> _clearAllSlots() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Slots'),
        content: const Text('Are you sure you want to delete all room slots?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _message = 'Clearing all slots...';
    });

    final result = await _seedRoomSlots.clearAllSlots();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _message = result.isSuccess
            ? '✅ Successfully cleared all room slots!'
            : '❌ ${result.error ?? "Failed to clear"}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Seed Data',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This screen helps you seed initial data for testing. Use with caution!',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Room Slots Section
            const Text(
              'Room Slots',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create time slots (8 slots, Monday-Friday) for all active rooms',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),

            // Seed Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _seedAllRoomSlots,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.add_circle_outline),
                label: const Text(
                  'Seed Room Slots',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Clear Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _clearAllSlots,
                icon: const Icon(Icons.delete_outline),
                label: const Text(
                  'Clear All Slots',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Message Display
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _message.startsWith('✅')
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _message.startsWith('✅')
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.startsWith('✅')
                        ? Colors.green.shade900
                        : Colors.orange.shade900,
                    fontSize: 14,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Slot Schedule Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Default Slot Schedule',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSlotInfo('Slot 1', '07:00 - 08:30'),
                  _buildSlotInfo('Slot 2', '08:45 - 10:15'),
                  _buildSlotInfo('Slot 3', '10:30 - 12:00'),
                  _buildSlotInfo('Slot 4', '12:30 - 14:00'),
                  _buildSlotInfo('Slot 5', '14:15 - 15:45'),
                  _buildSlotInfo('Slot 6', '16:00 - 17:30'),
                  _buildSlotInfo('Slot 7', '17:45 - 19:15'),
                  _buildSlotInfo('Slot 8', '19:30 - 21:00'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotInfo(String slot, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              slot,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A73E8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

