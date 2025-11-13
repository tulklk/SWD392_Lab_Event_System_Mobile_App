import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/room.dart';
import '../../domain/models/lab.dart';
import '../../domain/models/user.dart' as app_models;
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/lab_repository.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QRTicketScreen extends ConsumerStatefulWidget {
  final Booking booking;
  
  const QRTicketScreen({super.key, required this.booking});

  @override
  ConsumerState<QRTicketScreen> createState() => _QRTicketScreenState();
}

class _QRTicketScreenState extends ConsumerState<QRTicketScreen> {
  Room? _room;
  Lab? _lab;
  app_models.User? _lecturer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    
    try {
      // Load Room
      final roomRepository = RoomRepository();
      final roomResult = await roomRepository.getRoomById(widget.booking.roomId);
      
      if (roomResult.isSuccess && roomResult.data != null) {
        _room = roomResult.data;
        
        // Load Lab from Room
        try {
          final supabase = Supabase.instance.client;
          final roomResponse = await supabase
              .from('tbl_rooms')
              .select('LabId')
              .eq('Id', widget.booking.roomId)
              .maybeSingle();
          
          if (roomResponse != null && roomResponse['LabId'] != null) {
            final labId = roomResponse['LabId']?.toString();
            if (labId != null) {
              final labRepository = LabRepository();
              final labResult = await labRepository.getLabById(labId);
              if (labResult.isSuccess && labResult.data != null) {
                _lab = labResult.data;
              }
            }
          }
        } catch (e) {
          debugPrint('Error loading lab: $e');
        }
      }
      
      // Load Lecturer from Event
      if (widget.booking.eventId != null) {
        final eventRepository = ref.read(eventRepositoryProvider);
        final eventResult = await eventRepository.getEventById(widget.booking.eventId!);
        
        if (eventResult.isSuccess && eventResult.data != null) {
          final event = eventResult.data!;
          
          // Load lecturer
          final userRepository = ref.read(userRepositoryProvider);
          final lecturerResult = await userRepository.getUserById(event.createdBy);
          
          if (lecturerResult.isSuccess && lecturerResult.data != null) {
            _lecturer = lecturerResult.data;
          }
        }
      }
      
    } catch (e) {
      debugPrint('Error loading details: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'QR Ticket',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.booking.bookingStatus.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
          children: [
            // QR Code Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
              child: Column(
                children: [
                  const Text(
                    'Room Access QR Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Show this QR code at the room entrance',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // QR Code
                        QrImageView(
                          data: widget.booking.id,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'FPT-LAB-${widget.booking.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Booking Details
            Container(
              width: double.infinity,
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
                  Text(
                    widget.booking.purpose,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailRow(
                    Icons.access_time,
                    '${_formatLongDate(widget.booking.date)}\n${_formatTime(widget.booking.start)} - ${_formatTime(widget.booking.end)}',
                  ),
                  const SizedBox(height: 12),
                  
                  // Loading indicator
                  if (_isLoading) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ] else ...[
                    // Lab
                    if (_lab != null) ...[
                      _buildDetailRow(
                        Icons.science,
                        _lab!.name,
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Room
                    if (_room != null) ...[
                      _buildDetailRow(
                        Icons.meeting_room,
                        _room!.name,
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Lecturer
                    if (_lecturer != null) ...[
                      _buildDetailRow(
                        Icons.person_outline,
                        'Lecturer: ${_lecturer!.fullname}',
                      ),
                    ],
                  ],
                  
                  if (widget.booking.notes != null && widget.booking.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.note,
                      widget.booking.notes!,
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Booking ID',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'FPT-LAB-${widget.booking.id.substring(0, 12)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0EA5E9),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildInstruction('• Arrive 5 minutes before your scheduled time'),
                  _buildInstruction('• Show this QR code to the room supervisor'),
                  _buildInstruction('• Keep your student ID with you'),
                  _buildInstruction('• Follow lab safety guidelines'),
                  _buildInstruction('• Return equipment to original location after use'),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download feature coming soon!')),
                  );
                },
                icon: const Icon(
                  Icons.download,
                  color: Color(0xFF64748B),
                ),
                label: const Text(
                  'Download',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share feature coming soon!')),
                  );
                },
                icon: const Icon(
                  Icons.share,
                  color: Colors.white,
                ),
                label: const Text(
                  'Share',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (widget.booking.isApproved) {
      return const Color(0xFF10B981);
    } else if (widget.booking.isPending) {
      return const Color(0xFFF59E0B);
    } else if (widget.booking.isRejected) {
      return const Color(0xFFEF4444);
    } else {
      return const Color(0xFF64748B);
    }
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF0369A1),
          height: 1.4,
        ),
      ),
    );
  }

  String _formatLongDate(DateTime date) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
