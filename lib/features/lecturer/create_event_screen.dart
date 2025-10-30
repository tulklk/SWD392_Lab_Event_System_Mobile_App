import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/event_repository.dart';
import '../../domain/models/event.dart';
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
  final _locationController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      _loadEvent();
    }
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
        _locationController.text = event.location ?? '';
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

    if (widget.eventId != null && _existingEvent != null) {
      // Update existing event
      final updatedEvent = _existingEvent!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        startDate: startDateTime,
        endDate: endDateTime,
        visibility: _isPublic,
        status: isDraft ? 0 : 1,
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
      final result = await eventRepository.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        start: startDateTime,
        end: endDateTime,
        createdBy: currentUser.id,
        visibility: _isPublic,
        status: isDraft ? 0 : 1,
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

                    const SizedBox(height: 16),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location *',
                        hintText: 'Building A, Floor 3, Room 301',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter location';
                        }
                        return null;
                      },
                    ),

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
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }
}

