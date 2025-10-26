/// Booking Apply model matching tbl_booking_applies schema
class BookingApply {
  final String id;
  final String bookingId;
  final String roomSlotId;
  final String status; // text: 'pending', 'approved', 'rejected'
  final String? note;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  BookingApply({
    required this.id,
    required this.bookingId,
    required this.roomSlotId,
    this.status = 'pending',
    this.note,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  BookingApply copyWith({
    String? id,
    String? bookingId,
    String? roomSlotId,
    String? status,
    String? note,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return BookingApply(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      roomSlotId: roomSlotId ?? this.roomSlotId,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  factory BookingApply.fromJson(Map<String, dynamic> json) {
    return BookingApply(
      id: json['Id'] as String,
      bookingId: json['BookingId'] as String,
      roomSlotId: json['RoomSlotId'] as String,
      status: json['Status'] as String? ?? 'pending',
      note: json['Note'] as String?,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['LastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'BookingId': bookingId,
      'RoomSlotId': roomSlotId,
      'Status': status,
      'Note': note,
      'CreatedAt': createdAt.toIso8601String(),
      'LastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  @override
  String toString() {
    return 'BookingApply(id: $id, bookingId: $bookingId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingApply && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

