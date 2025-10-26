import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/booking.dart';
import '../../domain/enums/booking_status.dart';
import '../../domain/enums/repeat_rule.dart';
import '../../core/utils/result.dart';

class BookingRepository {
  static const String _boxName = 'bookings';
  late Box<Booking> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Booking>(_boxName);
  }

  Future<Result<Booking>> createBooking({
    String? eventId,
    required String roomId,
    required String userId,
    required String purpose,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final booking = Booking(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        eventId: eventId,
        roomId: roomId,
        userId: userId,
        purpose: purpose,
        startTime: startTime,
        endTime: endTime,
        status: 0, // pending
        notes: notes,
        createdAt: now,
        lastUpdatedAt: now,
      );

      await _box.put(booking.id, booking);
      return Success(booking);
    } catch (e) {
      return Failure('Failed to create booking: $e');
    }
  }

  Future<Result<Booking?>> getBookingById(String id) async {
    try {
      final booking = _box.get(id);
      return Success(booking);
    } catch (e) {
      return Failure('Failed to get booking: $e');
    }
  }

  Future<Result<List<Booking>>> getAllBookings() async {
    try {
      final bookings = _box.values.toList();
      return Success(bookings);
    } catch (e) {
      return Failure('Failed to get all bookings: $e');
    }
  }

  Future<Result<List<Booking>>> getBookingsForUser(String userId) async {
    try {
      final bookings = _box.values
          .where((booking) => booking.userId == userId)
          .toList();
      return Success(bookings);
    } catch (e) {
      return Failure('Failed to get bookings for user: $e');
    }
  }

  Future<Result<List<Booking>>> getBookingsForLab(String labId) async {
    try {
      final bookings = _box.values
          .where((booking) => booking.labId == labId)
          .toList();
      return Success(bookings);
    } catch (e) {
      return Failure('Failed to get bookings for lab: $e');
    }
  }

  Future<Result<List<Booking>>> getBookingsForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final bookings = _box.values.where((booking) {
        return booking.start.isAfter(startOfDay) &&
               booking.start.isBefore(endOfDay);
      }).toList();
      
      return Success(bookings);
    } catch (e) {
      return Failure('Failed to get bookings for date: $e');
    }
  }

  Future<Result<bool>> hasConflict(
    String labId,
    DateTime date,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final bookings = await getBookingsForLab(labId);
      if (bookings.isFailure) {
        return Failure(bookings.error!);
      }

      // Check for overlapping bookings
      for (final booking in bookings.data!) {
        if (booking.status == BookingStatus.approved ||
            booking.status == BookingStatus.pending) {
          // Check if the new booking overlaps with existing booking
          if (start.isBefore(booking.end) && end.isAfter(booking.start)) {
            return const Success(true);
          }
        }
      }

      return const Success(false);
    } catch (e) {
      return Failure('Failed to check conflict: $e');
    }
  }

  Future<Result<Booking>> updateBooking(Booking booking) async {
    try {
      await _box.put(booking.id, booking);
      return Success(booking);
    } catch (e) {
      return Failure('Failed to update booking: $e');
    }
  }

  Future<Result<void>> cancelBooking(String id) async {
    try {
      final booking = _box.get(id);
      if (booking != null) {
        final updatedBooking = booking.copyWith(
          status: 3, // cancelled
        );
        await _box.put(id, updatedBooking);
      }
      return const Success(null);
    } catch (e) {
      return Failure('Failed to cancel booking: $e');
    }
  }

  Future<Result<void>> deleteBooking(String id) async {
    try {
      await _box.delete(id);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete booking: $e');
    }
  }
}
