import '../enums/booking_status.dart';

/// Booking model matching tbl_bookings schema
class Booking {
  final String id;
  final String userId;
  final String roomId;
  final DateTime startTime;
  final DateTime endTime;
  final String purpose;
  final int status; // 0: pending, 1: approved, 2: rejected, 3: cancelled
  final String? notes;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final String? eventId;

  Booking({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.startTime,
    required this.endTime,
    required this.purpose,
    this.status = 0,
    this.notes,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.eventId,
  });

  Booking copyWith({
    String? id,
    String? userId,
    String? roomId,
    DateTime? startTime,
    DateTime? endTime,
    String? purpose,
    int? status,
    String? notes,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    String? eventId,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      eventId: eventId ?? this.eventId,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['Id'] as String,
      userId: json['UserId'] as String,
      roomId: json['RoomId'] as String,
      startTime: DateTime.parse(json['StartTime'] as String),
      endTime: DateTime.parse(json['EndTime'] as String),
      purpose: json['Purpose'] as String,
      status: json['Status'] as int? ?? 0,
      notes: json['Notes'] as String?,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['LastUpdatedAt'] as String),
      eventId: json['EventId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'UserId': userId,
      'RoomId': roomId,
      'StartTime': startTime.toIso8601String(),
      'EndTime': endTime.toIso8601String(),
      'Purpose': purpose,
      'Status': status,
      'Notes': notes,
      'CreatedAt': createdAt.toIso8601String(),
      'LastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'EventId': eventId,
    };
  }

  // Status helpers
  bool get isPending => status == 0;
  bool get isApproved => status == 1;
  bool get isRejected => status == 2;
  bool get isCancelled => status == 3;

  BookingStatus get bookingStatus {
    switch (status) {
      case 0:
        return BookingStatus.pending;
      case 1:
        return BookingStatus.approved;
      case 2:
        return BookingStatus.rejected;
      case 3:
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  // Helper getters for backward compatibility
  DateTime get start => startTime;
  DateTime get end => endTime;
  DateTime get date => startTime;
  String get title => purpose;
  String get labId => roomId; // For compatibility

  @override
  String toString() {
    return 'Booking(id: $id, userId: $userId, roomId: $roomId, purpose: $purpose, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
