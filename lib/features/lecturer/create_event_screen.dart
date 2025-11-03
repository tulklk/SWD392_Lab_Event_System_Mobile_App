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
import '../../domain/models/event.dart';
import '../../domain/models/room.dart';
import '../../domain/models/room_slot.dart';
import '../../domain/models/booking.dart';
import '../auth/auth_controller.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  final String? eventId; // null = create, non-null = edit

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
  
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  DateTime? _deadline;
  
  bool _isPublic = true;
  bool _isLoading = false;
  bool _isSaving = false;
  Event? _existingEvent;
  
  // Image handling
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  // Room and Slot selection
  final RoomRepository _roomRepository = RoomRepository();
  final RoomSlotRepository _roomSlotRepository = RoomSlotRepository();
  final BookingRepository _bookingRepository = BookingRepository();
  
  List<Room> _rooms = [];
  List<RoomSlot> _availableSlots = [];
  List<Booking> _existingBookings = [];
  Room? _selectedRoom;
  Set<String> _selectedSlotIds = {}; // Set để lưu các slot IDs đã chọn
  
  bool _isLoadingRooms = false;
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
    if (widget.eventId != null) {
      _loadEvent();
    }
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoadingRooms = true);
    final result = await _roomRepository.getActiveRooms();
    
    if (result.isSuccess && mounted) {
      setState(() {
        _rooms = result.data!;
        _isLoadingRooms = false;
      });
    } else {
      setState(() => _isLoadingRooms = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to load rooms'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedRoom == null || _startDate == null) {
      setState(() {
        _availableSlots = [];
        _selectedSlotIds.clear();
      });
      return;
    }
    
    setState(() => _isLoadingSlots = true);
    
    // Get day of week (1 = Monday, 7 = Sunday)
    final dayOfWeek = _startDate!.weekday;
    
    // Load all slots for this room on this day of week
    final slotsResult = await _roomSlotRepository.getSlotsByRoomId(_selectedRoom!.id);
    
    if (slotsResult.isSuccess) {
      final allSlots = slotsResult.data!
          .where((slot) => slot.dayOfWeek == dayOfWeek)
          .toList();
      
      // Load existing bookings for this room and date
      final bookingsResult = await _bookingRepository.getBookingsForLab(_selectedRoom!.id);
      
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
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
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
        });
      }
    } else {
      setState(() => _isLoadingSlots = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(slotsResult.error ?? 'Failed to load slots'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isSlotBooked(RoomSlot slot) {
    if (_startDate == null) return false;
    
    // Check if this slot is already booked
    return _existingBookings.any((booking) {
      final slotStart = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        slot.startTime.hour,
        slot.startTime.minute,
      );
      final slotEnd = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        slot.endTime.hour,
        slot.endTime.minute,
      );
      
      // Check if booking overlaps with slot
      return (booking.startTime.isBefore(slotEnd) && booking.endTime.isAfter(slotStart));
    });
  }

  void _toggleSlotSelection(String slotId) {
    setState(() {
      if (_selectedSlotIds.contains(slotId)) {
        _selectedSlotIds.remove(slotId);
      } else {
        _selectedSlotIds.add(slotId);
      }
    });
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
    });

    final eventRepository = ref.read(eventRepositoryProvider);
    final result = await eventRepository.getEventById(widget.eventId!);

    if (result.isSuccess && result.data != null) {
      final event = result.data!;
      setState(() {
        _existingEvent = event;
        _titleController.text = event.title;
        _descriptionController.text = event.description ?? '';
        _capacityController.text = event.capacity?.toString() ?? '';
        _isPublic = event.visibility;
        
        if (event.startDate != null) {
          _startDate = event.startDate;
          _startTime = TimeOfDay.fromDateTime(event.startDate!);
        }
        if (event.endDate != null) {
          _endDate = event.endDate;
          _endTime = TimeOfDay.fromDateTime(event.endDate!);
        }
        
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to load event'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
      });
      // Reload slots if room is selected
      if (_selectedRoom != null) {
        _loadAvailableSlots();
      }
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: _startDate ?? DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _deadline = date;
      });
    }
  }

  DateTime? _combineDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

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
                  title: const Text('Chọn từ thư viện'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Chụp ảnh'),
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
            content: Text('Lỗi khi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImageToSupabase() async {
    if (_selectedImage == null) return null;

    try {
      // Check if user is authenticated
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception('Bạn cần đăng nhập để upload ảnh');
      }

      final fileExtension = _selectedImage!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      
      // Upload to Supabase Storage with upsert to overwrite if exists
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

      // Get public URL
      final imageUrl = Supabase.instance.client.storage
          .from('event-images')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      
      final errorString = e.toString();
      
      // Check for RLS policy error
      if (errorString.contains('row-level security') || 
          errorString.contains('violates row-level security policy') ||
          errorString.contains('403') ||
          errorString.contains('Unauthorized')) {
        throw Exception(
          'Lỗi: Bucket "event-images" chưa có quyền upload.\n\n'
          'Vui lòng thiết lập RLS Policy trong Supabase:\n'
          '1. Vào https://app.supabase.com → Project của bạn\n'
          '2. Storage → event-images bucket → Policies\n'
          '3. Click "New Policy" → "Create policy from scratch"\n'
          '4. Đặt tên: "Allow authenticated upload"\n'
          '5. Target roles: authenticated\n'
          '6. Allowed operations: SELECT, INSERT, UPDATE\n'
          '7. Policy definition:\n'
          '   (bucket_id = \'event-images\'::text)\n'
          '8. Save và thử lại'
        );
      }
      
      throw Exception('Không thể upload ảnh: $e');
    }
  }

  Future<void> _saveEvent({bool isDraft = false}) async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start date and time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_endDate == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select end date and time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() {
        _isSaving = false;
      });
      return;
    }

    final startDateTime = _combineDateTime(_startDate, _startTime)!;
    final endDateTime = _combineDateTime(_endDate, _endTime)!;

    final eventRepository = ref.read(eventRepositoryProvider);

    // Upload image if selected
    String? imageUrl;
    try {
      imageUrl = await _uploadImageToSupabase();
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (widget.eventId != null && _existingEvent != null) {
      // Update existing event
      final capacityValue = _capacityController.text.trim().isEmpty 
          ? null 
          : int.tryParse(_capacityController.text.trim());
      
      final updatedEvent = _existingEvent!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: startDateTime,
        endDate: endDateTime,
        visibility: _isPublic,
        status: isDraft ? 0 : 1,
        capacity: capacityValue,
        imageUrl: imageUrl,
      );

      final result = await eventRepository.updateEvent(updatedEvent);

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isDraft ? 'Event saved as draft' : 'Event updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true); // Return true to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to update event'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Create new event
      final capacityValue = _capacityController.text.trim().isEmpty 
          ? null 
          : int.tryParse(_capacityController.text.trim());
      
      final result = await eventRepository.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        start: startDateTime,
        end: endDateTime,
        createdBy: currentUser.id,
        visibility: _isPublic,
        status: isDraft ? 0 : 1,
        capacity: capacityValue,
        imageUrl: imageUrl,
        roomId: _selectedRoom?.id,
        roomSlotIds: _selectedSlotIds.isNotEmpty ? _selectedSlotIds.toList() : null,
      );

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isDraft ? 'Event saved as draft' : 'Event created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true); // Return true to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to create event'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventId != null ? 'Edit Event' : 'Create Event'),
        actions: [
          if (!_isSaving)
            TextButton.icon(
              onPressed: () => _saveEvent(isDraft: true),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Draft'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
            ),
        ],
      ),
      body: _isLoading
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
                        hintText: 'e.g. AI Workshop: Neural Networks',
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

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Room Selection
                    Text(
                      'Select Room',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _isLoadingRooms
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Room>(
                                value: _selectedRoom,
                                hint: const Text(
                                  'Select a room (optional)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                isExpanded: true,
                                selectedItemBuilder: (BuildContext context) {
                                  return _rooms.map<Widget>((Room room) {
                                    return Container(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        room.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList();
                                },
                                onChanged: (Room? newValue) {
                                  setState(() {
                                    _selectedRoom = newValue;
                                    _selectedSlotIds.clear();
                                  });
                                  if (_startDate != null) {
                                    _loadAvailableSlots();
                                  }
                                },
                                items: _rooms.map<DropdownMenuItem<Room>>((Room room) {
                                  return DropdownMenuItem<Room>(
                                    value: room,
                                    child: Container(
                                      constraints: const BoxConstraints(maxHeight: 56),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            room.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${room.capacity} seats',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                    // Room Slots Selection
                    if (_selectedRoom != null && _startDate != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Available Time Slots (${_startDate != null ? dateFormat.format(_startDate!) : ""})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _isLoadingSlots
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _availableSlots.isEmpty
                              ? Container(
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
                                      Expanded(
                                        child: Text(
                                          'No available slots for this room on ${dateFormat.format(_startDate!)}',
                                          style: TextStyle(color: Colors.orange[900]),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            topRight: Radius.circular(8),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Select one or more time slots for your event',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ..._availableSlots.map((slot) {
                                        final isBooked = _isSlotBooked(slot);
                                        final isSelected = _selectedSlotIds.contains(slot.id);
                                        final timeFormat = DateFormat('HH:mm');
                                        
                                        return InkWell(
                                          onTap: isBooked ? null : () => _toggleSlotSelection(slot.id),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.blue[50]
                                                  : isBooked
                                                      ? Colors.red[50]
                                                      : Colors.white,
                                              border: Border(
                                                bottom: BorderSide(color: Colors.grey[200]!),
                                                left: BorderSide(
                                                  color: isSelected
                                                      ? Colors.blue
                                                      : Colors.transparent,
                                                  width: 3,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: isSelected,
                                                  onChanged: isBooked
                                                      ? null
                                                      : (value) => _toggleSlotSelection(slot.id),
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        '${slot.dayName}',
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
                                                            color: isBooked
                                                                ? Colors.red[400]
                                                                : Colors.grey[600],
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            '${timeFormat.format(slot.startTime)} - ${timeFormat.format(slot.endTime)}',
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              color: isBooked
                                                                  ? Colors.red[700]
                                                                  : Colors.grey[700],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (isBooked)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
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
                                    ],
                                  ),
                                ),
                      if (_selectedSlotIds.isNotEmpty) ...[
                        const SizedBox(height: 8),
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
                      ],
                    ] else if (_selectedRoom != null && _startDate == null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please select start date to view available slots',
                                style: TextStyle(color: Colors.blue[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Start Date & Time
                    Text(
                      'Start Date & Time *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectStartDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _startDate != null
                                  ? dateFormat.format(_startDate!)
                                  : 'Select Date',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectStartTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              _startTime != null
                                  ? _startTime!.format(context)
                                  : 'Select Time',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // End Date & Time
                    Text(
                      'End Date & Time *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectEndDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _endDate != null
                                  ? dateFormat.format(_endDate!)
                                  : 'Select Date',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectEndTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              _endTime != null
                                  ? _endTime!.format(context)
                                  : 'Select Time',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Capacity
                    TextFormField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacity (optional)',
                        hintText: 'e.g. 50',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final capacity = int.tryParse(value.trim());
                          if (capacity == null || capacity <= 0) {
                            return 'Please enter a valid capacity number';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Image Picker
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
                                    'Chọn ảnh hoặc chụp ảnh',
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

                    // Visibility Toggle
                    SwitchListTile(
                      title: const Text('Public Event'),
                      subtitle: Text(
                        _isPublic
                            ? 'Visible to all students'
                            : 'Only visible to invited students',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                      secondary: Icon(
                        _isPublic ? Icons.public : Icons.lock,
                        color: _isPublic ? Colors.blue : Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 24),

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
                            onPressed: _isSaving ? null : () => _saveEvent(isDraft: false),
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
                            label: Text(_isSaving
                                ? 'Saving...'
                                : widget.eventId != null
                                    ? 'Update Event'
                                    : 'Publish Event'),
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }
}

