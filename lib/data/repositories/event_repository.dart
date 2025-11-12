import 'package:flutter/foundation.dart';
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
    bool visibility = true,
    int status = 1, // 0: draft, 1: active, 2: cancelled
    String? imageUrl,
    String? roomId,
    String? labId,
    List<String>? roomSlotIds,
  }) async {
    try {
      final now = DateTime.now();
      final eventId = _uuid.v4();
      
      final eventData = {
        'Id': eventId,
        'Title': title,
        'Description': description,
        'StartDate': start.toIso8601String(),
        'EndDate': end.toIso8601String(),
        'CreatedBy': createdBy,
        'Visibility': visibility,
        'Status': status,
        'CreatedAt': now.toIso8601String(),
        'LastUpdatedAt': now.toIso8601String(),
      };

      // Add optional fields if provided
      // Note: Location and RecurrenceRule are not included as they don't exist in database schema
      if (imageUrl != null) {
        eventData['ImageUrl'] = imageUrl;
      }

      // Note: roomId, labId, and roomSlotIds are not stored in tbl_events table
      // They should be stored in a separate linking table (e.g., tbl_event_room_slots)
      // This would require additional API calls or a separate repository method
      // For now, we'll include labId in the request if provided
      
      final response = await _supabase
          .from('tbl_events')
          .insert(eventData)
          .select()
          .single();

      final event = Event.fromJson(response as Map<String, dynamic>);
      
      // Update room slots with EventId if roomSlotIds provided
      if (roomSlotIds != null && roomSlotIds.isNotEmpty) {
        try {
          for (final slotId in roomSlotIds) {
            await _supabase
                .from('tbl_room_slots')
                .update({'EventId': eventId})
                .eq('Id', slotId);
          }
          debugPrint('✅ Updated ${roomSlotIds.length} room slots with EventId');
        } catch (e) {
          debugPrint('⚠️ Failed to update room slots with EventId: $e');
          // Don't fail the event creation if slot update fails
        }
      }
      
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
  // NOTE: Removed because Location column doesn't exist in database
  // Future<Result<List<Event>>> getEventsForLocation(String location) async {
  //   try {
  //     final response = await _supabase
  //         .from('tbl_events')
  //         .select()
  //         .eq('Status', 1) // active only
  //         .eq('Location', location)
  //         .order('StartDate', ascending: true);
  //
  //     final events = (response as List)
  //         .map((json) => Event.fromJson(json as Map<String, dynamic>))
  //         .toList();
  //
  //     return Success(events);
  //   } catch (e) {
  //     return Failure('Failed to get events for location: $e');
  //   }
  // }

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
      // Get JSON data (Location and RecurrenceRule are already removed from model)
      final jsonData = event.toJson();
      
      final response = await _supabase
          .from('tbl_events')
          .update({
            ...jsonData,
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

  // Get RoomId and LabId for an event
  // This tries multiple approaches to find room and lab associated with event
  Future<Result<Map<String, String?>>> getEventRoomAndLabInfo(String eventId) async {
    try {
      debugPrint('🔍 Getting room and lab info for event: $eventId');
      
      String? roomId;
      String? labId;

      // Approach 1: Query room_slots to find RoomId for this event
      try {
        final slotsResponse = await _supabase
            .from('tbl_room_slots')
            .select('RoomId, EventId')
            .eq('EventId', eventId)
            .limit(1)
            .maybeSingle();

        debugPrint('   Room slots response: $slotsResponse');
        
        if (slotsResponse != null && slotsResponse['RoomId'] != null) {
          roomId = slotsResponse['RoomId']?.toString();
          debugPrint('   ✅ Found RoomId from room_slots: $roomId');
        } else {
          debugPrint('   ⚠️ No room slots found with EventId: $eventId');
          // Try querying all slots to see what's in the table
          try {
            final allSlots = await _supabase
                .from('tbl_room_slots')
                .select('RoomId, EventId')
                .limit(5);
            debugPrint('   Sample slots in table: $allSlots');
          } catch (e) {
            debugPrint('   Could not query sample slots: $e');
          }
        }
      } catch (e) {
        debugPrint('   ⚠️ Error querying room_slots: $e');
      }

      // Approach 2: Try to find in a linking table (e.g., tbl_event_rooms)
      if (roomId == null) {
        try {
          final linkResponse = await _supabase
              .from('tbl_event_rooms')
              .select('RoomId, LabId, EventId')
              .eq('EventId', eventId)
              .limit(1)
              .maybeSingle();
          
          if (linkResponse != null) {
            roomId = linkResponse['RoomId']?.toString();
            labId = linkResponse['LabId']?.toString();
            debugPrint('   ✅ Found from linking table - RoomId: $roomId, LabId: $labId');
          }
        } catch (e) {
          debugPrint('   ⚠️ Linking table approach failed (may not exist): $e');
        }
      }

      // Approach 3: Query rooms directly if we have roomId but need labId
      if (roomId != null && roomId.isNotEmpty && labId == null) {
        try {
          final roomResponse = await _supabase
              .from('tbl_rooms')
              .select('LabId')
              .eq('Id', roomId)
              .maybeSingle();
          
          debugPrint('   Room response: $roomResponse');
          
          if (roomResponse != null && roomResponse['LabId'] != null) {
            labId = roomResponse['LabId']?.toString();
            debugPrint('   ✅ Found LabId from room: $labId');
          } else {
            debugPrint('   ⚠️ Room found but no LabId in room record');
          }
        } catch (e) {
          debugPrint('   ⚠️ Error getting LabId from room: $e');
        }
      }

      // Approach 4: Try to get all room_slots and check if any have this event (without limit)
      if (roomId == null) {
        try {
          final allSlotsResponse = await _supabase
              .from('tbl_room_slots')
              .select('RoomId, EventId')
              .eq('EventId', eventId);
          
          if (allSlotsResponse != null && (allSlotsResponse as List).isNotEmpty) {
            final firstSlot = (allSlotsResponse as List).first as Map<String, dynamic>;
            roomId = firstSlot['RoomId']?.toString();
            debugPrint('   ✅ Found RoomId from all slots query: $roomId');
          } else {
            debugPrint('   ⚠️ No slots found even with full query');
          }
        } catch (e) {
          debugPrint('   ⚠️ Error in all slots query: $e');
        }
      }

      debugPrint('   📊 Final result - RoomId: $roomId, LabId: $labId');

      return Success({
        'roomId': roomId,
        'labId': labId,
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting event room/lab info: $e');
      debugPrint('   Stack trace: $stackTrace');
      return Success({
        'roomId': null,
        'labId': null,
      });
    }
  }

  // Get all rooms for an event (when event is booked for entire lab)
  Future<Result<List<String>>> getEventRoomIds(String eventId) async {
    try {
      debugPrint('🔍 Getting all room IDs for event: $eventId');
      
      // Query all room_slots that have this event
      final slotsResponse = await _supabase
          .from('tbl_room_slots')
          .select('RoomId')
          .eq('EventId', eventId);

      debugPrint('   Room slots response: $slotsResponse');
      
      if (slotsResponse != null && (slotsResponse as List).isNotEmpty) {
        // Get unique room IDs
        final roomIds = (slotsResponse as List)
            .map((slot) => slot['RoomId']?.toString())
            .where((id) => id != null && id.isNotEmpty)
            .toSet()
            .toList()
            .cast<String>();
        
        debugPrint('   ✅ Found ${roomIds.length} unique room IDs: $roomIds');
        return Success(roomIds);
      } else {
        debugPrint('   ⚠️ No room slots found for event: $eventId');
        return Success([]);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting event room IDs: $e');
      debugPrint('   Stack trace: $stackTrace');
      return Success([]);
    }
  }

  // Get pending events (for Admin approval)
  Future<Result<List<Event>>> getPendingEvents() async {
    try {
      final response = await _supabase
          .from('tbl_events')
          .select()
          .eq('Status', 0) // pending only
          .order('CreatedAt', ascending: false);

      final events = (response as List)
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(events);
    } catch (e) {
      return Failure('Failed to get pending events: $e');
    }
  }

  // Approve event (Admin only)
  Future<Result<void>> approveEvent(String eventId) async {
    try {
      debugPrint('✅ Approving event: $eventId');
      
      await _supabase
          .from('tbl_events')
          .update({
            'Status': 1, // active
            'LastUpdatedAt': DateTime.now().toIso8601String(),
          })
          .eq('Id', eventId);

      debugPrint('✅ Event approved successfully');
      return const Success(null);
    } catch (e) {
      debugPrint('❌ Failed to approve event: $e');
      return Failure('Failed to approve event: $e');
    }
  }

  // Reject event (Admin only)
  Future<Result<void>> rejectEvent(String eventId) async {
    try {
      debugPrint('❌ Rejecting event: $eventId');
      
      await _supabase
          .from('tbl_events')
          .update({
            'Status': 2, // cancelled/rejected
            'LastUpdatedAt': DateTime.now().toIso8601String(),
          })
          .eq('Id', eventId);

      debugPrint('✅ Event rejected successfully');
      return const Success(null);
    } catch (e) {
      debugPrint('❌ Failed to reject event: $e');
      return Failure('Failed to reject event: $e');
    }
  }
}
