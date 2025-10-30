import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/supabase_config.dart';
import '../../domain/models/event.dart';
import '../../core/utils/result.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

class EventRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // No need for init with Supabase
  Future<void> init() async {
    // Empty - kept for compatibility
  }

  // Create new event
  Future<Result<Event>> createEvent({
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
    required String createdBy,
    String? location,
    bool visibility = true,
    int status = 1, // 0: draft, 1: active, 2: cancelled
  }) async {
    try {
      final now = DateTime.now();
      final eventId = _uuid.v4();
      
      final response = await _supabase
          .from('tbl_events')
          .insert({
            'Id': eventId,
            'Title': title,
            'Description': description,
            'StartDate': start.toIso8601String(),
            'EndDate': end.toIso8601String(),
            'CreatedBy': createdBy,
            'Location': location,
            'Visibility': visibility,
            'Status': status,
            'CreatedAt': now.toIso8601String(),
            'LastUpdatedAt': now.toIso8601String(),
          })
          .select()
          .single();

      final event = Event.fromJson(response as Map<String, dynamic>);
      return Success(event);
    } catch (e) {
      return Failure('Failed to create event: $e');
    }
  }

  // Get event by ID
  Future<Result<Event?>> getEventById(String id) async {
    try {
      final response = await _supabase
          .from('tbl_events')
          .select()
          .eq('Id', id)
          .maybeSingle();

      if (response == null) {
        return const Success(null);
      }

      final event = Event.fromJson(response as Map<String, dynamic>);
      return Success(event);
    } catch (e) {
      return Failure('Failed to get event: $e');
    }
  }

  // Get all events (including drafts)
  Future<Result<List<Event>>> getAllEvents() async {
    try {
      final response = await _supabase
          .from('tbl_events')
          .select()
          .neq('Status', 2) // exclude cancelled
          .order('StartDate', ascending: true);

      final events = (response as List)
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(events);
    } catch (e) {
      return Failure('Failed to get all events: $e');
    }
  }

  // Get events for specific day
  Future<Result<List<Event>>> getEventsForDay(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('tbl_events')
          .select()
          .eq('Status', 1) // active only
          .gte('StartDate', startOfDay.toIso8601String())
          .lt('StartDate', endOfDay.toIso8601String())
          .order('StartDate', ascending: true);

      final events = (response as List)
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(events);
    } catch (e) {
      return Failure('Failed to get events for day: $e');
    }
  }

  // Get events for specific location
  Future<Result<List<Event>>> getEventsForLocation(String location) async {
    try {
      final response = await _supabase
          .from('tbl_events')
          .select()
          .eq('Status', 1) // active only
          .eq('Location', location)
          .order('StartDate', ascending: true);

      final events = (response as List)
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(events);
    } catch (e) {
      return Failure('Failed to get events for location: $e');
    }
  }

  // Get upcoming events (from now onwards)
  Future<Result<List<Event>>> getUpcomingEvents() async {
    try {
      final now = DateTime.now();
      
      final response = await _supabase
          .from('tbl_events')
          .select()
          .eq('Status', 1) // active only
          .gte('StartDate', now.toIso8601String())
          .order('StartDate', ascending: true)
          .limit(10);

      final events = (response as List)
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(events);
    } catch (e) {
      return Failure('Failed to get upcoming events: $e');
    }
  }

  // Get events in date range
  Future<Result<List<Event>>> getEventsInRange(DateTime start, DateTime end) async {
    try {
      final response = await _supabase
          .from('tbl_events')
          .select()
          .eq('Status', 1) // active only
          .gte('StartDate', start.toIso8601String())
          .lte('StartDate', end.toIso8601String())
          .order('StartDate', ascending: true);

      final events = (response as List)
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(events);
    } catch (e) {
      return Failure('Failed to get events in range: $e');
    }
  }

  // Update event
  Future<Result<Event>> updateEvent(Event event) async {
    try {
      final response = await _supabase
          .from('tbl_events')
          .update({
            ...event.toJson(),
            'LastUpdatedAt': DateTime.now().toIso8601String(),
          })
          .eq('Id', event.id)
          .select()
          .single();

      final updatedEvent = Event.fromJson(response as Map<String, dynamic>);
      return Success(updatedEvent);
    } catch (e) {
      return Failure('Failed to update event: $e');
    }
  }

  // Cancel event (soft delete)
  Future<Result<void>> deleteEvent(String id) async {
    try {
      await _supabase
          .from('tbl_events')
          .update({
            'Status': 2, // cancelled
            'LastUpdatedAt': DateTime.now().toIso8601String(),
          })
          .eq('Id', id);

      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete event: $e');
    }
  }

  // Hard delete event (permanent)
  Future<Result<void>> hardDeleteEvent(String id) async {
    try {
      await _supabase
          .from('tbl_events')
          .delete()
          .eq('Id', id);

      return const Success(null);
    } catch (e) {
      return Failure('Failed to hard delete event: $e');
    }
  }

  // Get public events only
  Future<Result<List<Event>>> getPublicEvents() async {
    try {
      final response = await _supabase
          .from('tbl_events')
          .select()
          .eq('Status', 1) // active only
          .eq('Visibility', true) // public only
          .order('StartDate', ascending: true);

      final events = (response as List)
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(events);
    } catch (e) {
      return Failure('Failed to get public events: $e');
    }
  }

  // Get events created by specific user
  Future<Result<List<Event>>> getEventsByCreator(String userId) async {
    try {
      final response = await _supabase
          .from('tbl_events')
          .select()
          .eq('CreatedBy', userId)
          .order('CreatedAt', ascending: false);

      final events = (response as List)
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(events);
    } catch (e) {
      return Failure('Failed to get events by creator: $e');
    }
  }
}
