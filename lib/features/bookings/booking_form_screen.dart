import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/room.dart';
import '../../domain/models/room_slot.dart';
import '../../domain/models/booking.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/room_slot_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../auth/auth_controller.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  final String? roomId;
  final DateTime? selectedDate;
  final DateTime? selectedStartTime;
  final DateTime? selectedEndTime;
  
  const BookingFormScreen({
    super.key,
    this.roomId,
    this.selectedDate,
    this.selectedStartTime,
    this.selectedEndTime,
  });

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomRepository = RoomRepository();
  final _roomSlotRepository = RoomSlotRepository();
  final _bookingRepository = BookingRepository();
  
  List<Room> _rooms = [];
  List<RoomSlot> _availableSlots = [];
  List<Booking> _existingBookings = [];
  
  bool _isLoadingRooms = true;
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;
  
  String? _selectedRoomId;
  DateTime? _selectedDate;
  RoomSlot? _selectedSlot;
  
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRooms();
    
    // Pre-fill from params
    if (widget.roomId != null) {
      _selectedRoomId = widget.roomId;
    }
    if (widget.selectedDate != null) {
      _selectedDate = widget.selectedDate;
      if (_selectedRoomId != null) {
        _loadSlotsForRoomAndDate();
      }
    }
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoadingRooms = true);
    final result = await _roomRepository.getAllRooms();
    
    if (result.isSuccess && mounted) {
      setState(() {
        _rooms = result.data!.where((room) => room.isActive).toList();
        _isLoadingRooms = false;
      });
    } else {
      setState(() => _isLoadingRooms = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Failed to load rooms')),
        );
      }
    }
  }

  Future<void> _loadSlotsForRoomAndDate() async {
    if (_selectedRoomId == null || _selectedDate == null) return;
    
    setState(() => _isLoadingSlots = true);
    
    // Get day of week (1 = Monday, 7 = Sunday)
    final dayOfWeek = _selectedDate!.weekday;
    
    // Load all slots for this room on this day of week
    final slotsResult = await _roomSlotRepository.getSlotsByRoomId(_selectedRoomId!);
    
    if (slotsResult.isSuccess) {
      final allSlots = slotsResult.data!
          .where((slot) => slot.dayOfWeek == dayOfWeek)
          .toList();
      
      // Load existing bookings for this room and date
      final bookingsResult = await _bookingRepository.getBookingsForLab(_selectedRoomId!);
      
      List<Booking> existingBookings = [];
      if (bookingsResult.isSuccess) {
        // Filter bookings for selected date
        existingBookings = bookingsResult.data!.where((booking) {
          final bookingDate = DateTime(
            booking.startTime.year,
            booking.startTime.month,
            booking.startTime.day,
          );
          final selectedDateOnly = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
          );
          return bookingDate.isAtSameMomentAs(selectedDateOnly) && 
                 !booking.isCancelled && 
                 !booking.isRejected;
        }).toList();
      }
      
      if (mounted) {
        setState(() {
          _availableSlots = allSlots;
          _existingBookings = existingBookings;
          _isLoadingSlots = false;
          _selectedSlot = null; // Reset selected slot when date/room changes
        });
      }
    } else {
      setState(() => _isLoadingSlots = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(slotsResult.error ?? 'Failed to load slots')),
        );
      }
    }
  }

  bool _isSlotBooked(RoomSlot slot) {
    // Check if this slot is already booked
    return _existingBookings.any((booking) {
      final slotStart = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        slot.startTime.hour,
        slot.startTime.minute,
      );
      final slotEnd = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        slot.endTime.hour,
        slot.endTime.minute,
      );
      
      // Check if booking overlaps with slot
      return (booking.startTime.isBefore(slotEnd) && booking.endTime.isAfter(slotStart));
    });
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
          'New Booking',
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Choose Room
              const Text(
                'Choose Room *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              _isLoadingRooms
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRoomId,
                          hint: const Text(
                            'Select a room',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                            ),
                          ),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedRoomId = newValue;
                              _selectedSlot = null;
                            });
                            if (_selectedDate != null) {
                              _loadSlotsForRoomAndDate();
                            }
                          },
                          items: _rooms.map<DropdownMenuItem<String>>((Room room) {
                            return DropdownMenuItem<String>(
                              value: room.id,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(room.name),
                                  Text(
                                    room.location ?? 'No location',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),

              // Date
              const Text(
                'Date *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                      _selectedSlot = null;
                    });
                    if (_selectedRoomId != null) {
                      _loadSlotsForRoomAndDate();
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Select date',
                        style: TextStyle(
                          color: _selectedDate != null
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Available Slots
              if (_selectedRoomId != null && _selectedDate != null) ...[
                Row(
                  children: [
                    const Text(
                      'Select Time Slot *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                const SizedBox(height: 12),
                if (!_isLoadingSlots && _availableSlots.isEmpty)
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
                            'No slots available for this room on selected day.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!_isLoadingSlots && _availableSlots.isNotEmpty)
                  ...List.generate(_availableSlots.length, (index) {
                    final slot = _availableSlots[index];
                    final isBooked = _isSlotBooked(slot);
                    final isSelected = _selectedSlot?.id == slot.id;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: isBooked ? null : () {
                          setState(() => _selectedSlot = slot);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isBooked 
                                ? Colors.grey.shade100 
                                : isSelected 
                                    ? const Color(0xFFFF6600).withOpacity(0.1)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFFFF6600)
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isBooked 
                                      ? Colors.grey.shade300 
                                      : const Color(0xFF1A73E8).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Slot ${index + 1}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isBooked 
                                        ? Colors.grey.shade600 
                                        : const Color(0xFF1A73E8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isBooked 
                                        ? Colors.grey.shade600 
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              if (isBooked)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Booked',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              if (!isBooked && isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFFFF6600),
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),
              ],

              // Purpose
              const Text(
                'Purpose *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _purposeController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the purpose of booking';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'e.g. Machine Learning Workshop',
                  hintStyle: TextStyle(
                    color: Color(0xFF64748B),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF6600)),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Notes
              const Text(
                'Notes (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Additional notes or requirements (optional)',
                  hintStyle: TextStyle(
                    color: Color(0xFF64748B),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF6600)),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
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
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_canSubmit() && !_isSubmitting) ? _submitBooking : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6600),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              disabledForegroundColor: const Color(0xFF64748B),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Confirm Booking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  bool _canSubmit() {
    return _selectedRoomId != null &&
           _selectedDate != null &&
           _selectedSlot != null &&
           _purposeController.text.isNotEmpty;
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }
    
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      // Create DateTime objects for start and end times using selected slot
      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedSlot!.startTime.hour,
        _selectedSlot!.startTime.minute,
      );
      
      final endDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedSlot!.endTime.hour,
        _selectedSlot!.endTime.minute,
      );
      
      // Create booking
      final result = await _bookingRepository.createBooking(
        roomId: _selectedRoomId!,
        userId: currentUser.id,
        purpose: _purposeController.text.trim(),
        startTime: startDateTime,
        endTime: endDateTime,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        
        if (result.isSuccess) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Booking Submitted'),
                content: const Text(
                  'Your booking has been successfully submitted and is pending approval.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context, true); // Go back with success result
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to create booking'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
