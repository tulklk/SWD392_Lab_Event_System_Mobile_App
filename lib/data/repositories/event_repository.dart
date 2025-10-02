import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/event.dart';
import '../../core/utils/result.dart';

class EventRepository {
  static const String _boxName = 'events';
  late Box<Event> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Event>(_boxName);
  }

  Future<Result<Event>> createEvent({
    required String labId,
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
    required String createdBy,
  }) async {
    try {
      final event = Event(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        labId: labId,
        title: title,
        description: description,
        start: start,
        end: end,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      await _box.put(event.id, event);
      return Success(event);
    } catch (e) {
      return Failure('Failed to create event: $e');
    }
  }

  Future<Result<Event?>> getEventById(String id) async {
    try {
      final event = _box.get(id);
      return Success(event);
    } catch (e) {
      return Failure('Failed to get event: $e');
    }
  }

  Future<Result<List<Event>>> getAllEvents() async {
    try {
      final events = _box.values.where((event) => event.isActive).toList();
      return Success(events);
    } catch (e) {
      return Failure('Failed to get all events: $e');
    }
  }

  Future<Result<List<Event>>> getEventsForDay(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final events = _box.values.where((event) {
        return event.isActive &&
               event.start.isAfter(startOfDay) &&
               event.start.isBefore(endOfDay);
      }).toList();
      
      return Success(events);
    } catch (e) {
      return Failure('Failed to get events for day: $e');
    }
  }

  Future<Result<List<Event>>> getEventsForLab(String labId) async {
    try {
      final events = _box.values
          .where((event) => event.isActive && event.labId == labId)
          .toList();
      return Success(events);
    } catch (e) {
      return Failure('Failed to get events for lab: $e');
    }
  }

  Future<Result<Event>> updateEvent(Event event) async {
    try {
      await _box.put(event.id, event);
      return Success(event);
    } catch (e) {
      return Failure('Failed to update event: $e');
    }
  }

  Future<Result<void>> deleteEvent(String id) async {
    try {
      final event = _box.get(id);
      if (event != null) {
        final updatedEvent = event.copyWith(isActive: false);
        await _box.put(id, updatedEvent);
      }
      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete event: $e');
    }
  }
}
