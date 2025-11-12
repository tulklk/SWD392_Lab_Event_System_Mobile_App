import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/room_slot_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/lab_repository.dart';
import '../../domain/models/room.dart';
import '../../domain/models/room_slot.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/lab.dart';
import '../auth/auth_controller.dart';

/// Simplified Create Event Screen for Lecturer
/// Flow: Select Lab → Select Date → View Rooms with Available Slots → Select Slots → Create
class CreateEventScreen extends ConsumerStatefulWidget {
  final String? eventId;

  const CreateEventScreen({
    super.key,
    this.eventId,
  });

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();

  // Step 1: Select Lab
  Lab? _selectedLab;
  List<Lab> _labs = [];
  bool _isLoadingLabs = false;

  // Step 1.5: Choose Booking Mode
  bool _bookEntireLab = true; // true = entire lab (multiple rooms), false = single room
  Room? _selectedRoom; // For single room mode only
  List<Room> _allRoomsInLab = []; // All rooms in selected lab (for dropdown)

  // Step 2: Select Date (only date, no time)
  DateTime? _selectedDate;

  // Step 3: Load Rooms with Available Slots
  List<Room> _roomsWithSlots = []; // Rooms to display with slots
  Map<String, List<RoomSlot>> _roomSlotMap = {}; // roomId -> List<RoomSlot>
  Map<String, List<Booking>> _roomBookingMap = {}; // roomId -> List<Booking>
  bool _isLoadingRooms = false;

  // Step 4: Select Slots
  Set<String> _selectedSlotIds = {};

  // Other fields
  bool _isSaving = false;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  final LabRepository _labRepository = LabRepository();
  final RoomRepository _roomRepository = RoomRepository();
  final RoomSlotRepository _roomSlotRepository = RoomSlotRepository();
  final BookingRepository _bookingRepository = BookingRepository();

  @override
  void initState() {
    super.initState();
    _loadLabs();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  // STEP 1: Load Labs
  Future<void> _loadLabs() async {
    setState(() => _isLoadingLabs = true);
    final result = await _labRepository.getLabsFromSupabase();

    if (result.isSuccess && mounted) {
      setState(() {
        _labs = result.data!;
        _isLoadingLabs = false;
      });
    } else {
      setState(() => _isLoadingLabs = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to load labs'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Load Rooms for Lab (without slots, just for dropdown)
  Future<void> _loadRoomsForLab() async {
    if (_selectedLab == null) return;

    try {
      final roomsResult = await _roomRepository.getRoomsByLabId(_selectedLab!.id);
      if (roomsResult.isSuccess && roomsResult.data != null && mounted) {
        setState(() {
          _allRoomsInLab = roomsResult.data!;
        });
      }
    } catch (e) {
      debugPrint('Error loading rooms: $e');
    }
  }

  // STEP 2: Date Selected → Reset Room & Slots
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _roomSlotMap = {};
      _roomBookingMap = {};
      _selectedSlotIds.clear();
    });
    
    // Load rooms with slots for this date
    if (_selectedLab != null) {
      _loadRoomsWithSlots();
    }
  }

  // STEP 3: Load Rooms with Available Slots for Selected Date
  Future<void> _loadRoomsWithSlots() async {
    if (_selectedLab == null || _selectedDate == null) return;
    
    // For single room mode, need a selected room
    if (!_bookEntireLab && _selectedRoom == null) return;

    setState(() => _isLoadingRooms = true);

    try {
      // Determine which rooms to load slots for
      List<Room> rooms;
      if (_bookEntireLab) {
        // Load all rooms in lab
        final roomsResult = await _roomRepository.getRoomsByLabId(_selectedLab!.id);
        if (!roomsResult.isSuccess || roomsResult.data == null) {
          setState(() => _isLoadingRooms = false);
          return;
        }
        rooms = roomsResult.data!;
      } else {
        // Only load the selected room
        rooms = [_selectedRoom!];
      }

      final dayOfWeek = _selectedDate!.weekday;
      
      Map<String, List<RoomSlot>> slotsMap = {};
      Map<String, List<Booking>> bookingsMap = {};

      // For each room, load slots for this day of week
      for (final room in rooms) {
        // Load slots
        final slotsResult = await _roomSlotRepository.getSlotsByRoomId(room.id);
        if (slotsResult.isSuccess && slotsResult.data != null) {
          final roomSlots = slotsResult.data!
              .where((slot) => slot.dayOfWeek == dayOfWeek)
              .toList();
          slotsMap[room.id] = roomSlots;
        }

        // Load bookings for this date
        final bookingsResult = await _bookingRepository.getBookingsForLab(room.id);
        if (bookingsResult.isSuccess && bookingsResult.data != null) {
          final roomBookings = bookingsResult.data!.where((booking) {
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
          bookingsMap[room.id] = roomBookings;
        }
      }

      if (mounted) {
        setState(() {
          // For display purposes, store the rooms we're showing slots for
          if (!_bookEntireLab) {
            // In single room mode, only keep the selected room in display list
            _roomsWithSlots = [_selectedRoom!];
          } else {
            _roomsWithSlots = rooms;
          }
          _roomSlotMap = slotsMap;
          _roomBookingMap = bookingsMap;
          _isLoadingRooms = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading rooms with slots: $e');
      setState(() => _isLoadingRooms = false);
    }
  }

  // STEP 4: Check if slot is booked
  bool _isSlotBooked(String roomId, RoomSlot slot) {
    final bookings = _roomBookingMap[roomId] ?? [];
    
    return bookings.any((booking) {
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

      return booking.startTime.isBefore(slotEnd) && booking.endTime.isAfter(slotStart);
    });
  }

  // STEP 5: Toggle Slot Selection
  void _toggleSlot(String slotId) {
    setState(() {
      if (_selectedSlotIds.contains(slotId)) {
        _selectedSlotIds.remove(slotId);
      } else {
        _selectedSlotIds.add(slotId);
      }
    });
  }

  // Calculate Start/End DateTime from Selected Slots
  (DateTime?, DateTime?) _calculateEventTimes() {
    if (_selectedDate == null || _selectedSlotIds.isEmpty) {
      return (null, null);
    }

    DateTime? earliestStart;
    DateTime? latestEnd;

    for (final roomSlots in _roomSlotMap.values) {
      for (final slot in roomSlots) {
        if (_selectedSlotIds.contains(slot.id)) {
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

          if (earliestStart == null || slotStart.isBefore(earliestStart)) {
            earliestStart = slotStart;
          }
          if (latestEnd == null || slotEnd.isAfter(latestEnd)) {
            latestEnd = slotEnd;
          }
        }
      }
    }

    return (earliestStart, latestEnd);
  }

  // Upload Image
  Future<String?> _uploadImageToSupabase() async {
    if (_selectedImage == null) return null;

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception('You need to login to upload images');
      }

      final fileExtension = _selectedImage!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await Supabase.instance.client.storage
          .from('event-images')
          .upload(
            fileName,
            _selectedImage!,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/*',
            ),
          );

      final imageUrl = Supabase.instance.client.storage
          .from('event-images')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Pick Image
  Future<void> _pickImage() async {
    try {
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take a photo'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          );
        },
      );

      if (source != null) {
        final XFile? image = await _imagePicker.pickImage(source: source);
        if (image != null && mounted) {
          setState(() {
            _selectedImage = File(image.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Save Event
  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation
    if (_selectedLab == null) {
      _showError('Please select a lab');
      return;
    }

    // For single room mode, must select a room
    if (!_bookEntireLab && _selectedRoom == null) {
      _showError('Please select a room');
      return;
    }

    if (_selectedDate == null) {
      _showError('Please select a date');
      return;
    }

    if (_selectedSlotIds.isEmpty) {
      _showError('Please select at least one time slot');
      return;
    }

    final capacityValue = int.tryParse(_capacityController.text.trim());
    if (capacityValue == null || capacityValue <= 0) {
      _showError('Please enter a valid capacity');
      return;
    }

    setState(() => _isSaving = true);

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      // Calculate start/end times from selected slots
      final (startTime, endTime) = _calculateEventTimes();
      if (startTime == null || endTime == null) {
        _showError('Failed to calculate event times');
        setState(() => _isSaving = false);
        return;
      }

      // Upload image
      String? imageUrl;
      try {
        imageUrl = await _uploadImageToSupabase();
      } catch (e) {
        _showError('Failed to upload image: $e');
        setState(() => _isSaving = false);
        return;
      }

      // Create event
      final eventRepository = ref.read(eventRepositoryProvider);
      final result = await eventRepository.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        start: startTime,
        end: endTime,
        createdBy: currentUser.id,
        visibility: true, // Always public
        status: 0, // Pending approval
        capacity: capacityValue,
        imageUrl: imageUrl,
        labId: _selectedLab!.id,
        roomId: _bookEntireLab ? null : _selectedRoom?.id, // Only set roomId for single room mode
        roomSlotIds: _selectedSlotIds.toList(),
      );

      setState(() => _isSaving = false);

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event created successfully! Waiting for Admin approval.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          context.pop(true);
        } else {
          _showError(result.error ?? 'Failed to create event');
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Error creating event: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingLabs
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title *',
                        hintText: 'e.g. AI Workshop',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter event title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Describe your event...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Capacity
                    TextFormField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacity *',
                        hintText: 'e.g. 50',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter capacity';
                        }
                        final capacity = int.tryParse(value.trim());
                        if (capacity == null || capacity <= 0) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // STEP 1: Select Lab
                    Text(
                      '1. Select Lab *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Lab>(
                          value: _selectedLab,
                          hint: const Text('Select a lab'),
                          isExpanded: true,
                          onChanged: (Lab? newValue) {
                            setState(() {
                              _selectedLab = newValue;
                              _selectedDate = null;
                              _selectedRoom = null;
                              _roomsWithSlots = [];
                              _roomSlotMap = {};
                              _selectedSlotIds.clear();
                            });
                            // Load rooms for this lab (for single room dropdown)
                            if (newValue != null) {
                              _loadRoomsForLab();
                            }
                          },
                          items: _labs.map<DropdownMenuItem<Lab>>((Lab lab) {
                            return DropdownMenuItem<Lab>(
                              value: lab,
                              child: Text(lab.name),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // STEP 1.5: Choose Booking Mode
                    if (_selectedLab != null) ...[
                      Text(
                        '📌 Booking Type *',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<bool>(
                              title: const Text('🏢 Book Entire Lab'),
                              subtitle: const Text(
                                'Select multiple rooms and slots across the lab',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: true,
                              groupValue: _bookEntireLab,
                              onChanged: (bool? value) {
                                setState(() {
                                  _bookEntireLab = value ?? true;
                                  _selectedRoom = null;
                                  _selectedDate = null;
                                  _roomsWithSlots = [];
                                  _roomSlotMap = {};
                                  _selectedSlotIds.clear();
                                });
                              },
                              activeColor: const Color(0xFFFF6600),
                            ),
                            const Divider(height: 1),
                            RadioListTile<bool>(
                              title: const Text('📍 Book Single Room'),
                              subtitle: const Text(
                                'Select one specific room and its slots',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: false,
                              groupValue: _bookEntireLab,
                              onChanged: (bool? value) {
                                setState(() {
                                  _bookEntireLab = value ?? true;
                                  _selectedRoom = null;
                                  _selectedDate = null;
                                  _roomsWithSlots = [];
                                  _roomSlotMap = {};
                                  _selectedSlotIds.clear();
                                });
                              },
                              activeColor: const Color(0xFFFF6600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // STEP 1.75: Select Room (for Single Room mode only)
                    if (_selectedLab != null && !_bookEntireLab) ...[
                      Text(
                        '🚪 Select Room *',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Room>(
                            value: _selectedRoom,
                            hint: const Text('Select a room'),
                            isExpanded: true,
                            onChanged: (Room? newValue) {
                              setState(() {
                                _selectedRoom = newValue;
                                _roomsWithSlots = [];
                                _roomSlotMap = {};
                                _selectedSlotIds.clear();
                              });
                              // If date is already selected, load slots for this room
                              if (newValue != null && _selectedDate != null) {
                                _loadRoomsWithSlots();
                              }
                            },
                            items: _allRoomsInLab.map<DropdownMenuItem<Room>>((Room room) {
                              return DropdownMenuItem<Room>(
                                value: room,
                                child: Text('${room.name} (${room.capacity} seats)'),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // STEP 2: Select Date
                    if (_selectedLab != null && (_bookEntireLab || _selectedRoom != null)) ...[
                      Text(
                        '2. Select Date *',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              _onDateSelected(date);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _selectedDate != null
                                ? dateFormat.format(_selectedDate!)
                                : 'Select Date',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // STEP 3: View Rooms with Slots
                    if (_selectedDate != null) ...[
                      Text(
                        '3. Select Time Slots *',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingRooms)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_roomsWithSlots.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange[700]),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('No rooms or slots available for this lab on selected date'),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._roomsWithSlots.map((room) {
                          final slots = _roomSlotMap[room.id] ?? [];
                          if (slots.isEmpty) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Room Header
                              Container(
                                margin: const EdgeInsets.only(bottom: 8, top: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.room, size: 20, color: Colors.blue[700]),
                                    const SizedBox(width: 8),
                                    Text(
                                      room.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${room.capacity} seats)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Slots for this room
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: slots.map((slot) {
                                    final isBooked = _isSlotBooked(room.id, slot);
                                    final isSelected = _selectedSlotIds.contains(slot.id);

                                    return InkWell(
                                      onTap: isBooked ? null : () => _toggleSlot(slot.id),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.green[50]
                                              : isBooked
                                                  ? Colors.red[50]
                                                  : Colors.white,
                                          border: Border(
                                            bottom: BorderSide(color: Colors.grey[200]!),
                                            left: BorderSide(
                                              color: isSelected ? Colors.green : Colors.transparent,
                                              width: 4,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: isSelected,
                                              onChanged: isBooked ? null : (value) => _toggleSlot(slot.id),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    slot.dayName,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: isBooked ? Colors.grey : null,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.access_time,
                                                        size: 14,
                                                        color: isBooked ? Colors.red[400] : Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${timeFormat.format(slot.startTime)} - ${timeFormat.format(slot.endTime)}',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: isBooked ? Colors.red[700] : Colors.grey[700],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isBooked)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.red[100],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Booked',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.red[900],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),

                      // Selected Slots Summary
                      if (_selectedSlotIds.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_selectedSlotIds.length} slot(s) selected',
                                  style: TextStyle(
                                    color: Colors.green[900],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],

                    // Image Picker
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Event Image (optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _selectedImage != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Choose or take a photo',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : () => context.pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveEvent,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: Text(_isSaving ? 'Creating...' : 'Create Event'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6600),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

