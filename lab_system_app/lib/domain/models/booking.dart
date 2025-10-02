import 'package:hive/hive.dart';
import '../enums/booking_status.dart';
import '../enums/repeat_rule.dart';

part 'booking.g.dart';

@HiveType(typeId: 3)
class Booking extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? eventId; // nullable when booking ad-hoc

  @HiveField(2)
  final String labId;

  @HiveField(3)
  final String userId;

  @HiveField(4)
  final String title;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final DateTime start;

  @HiveField(7)
  final DateTime end;

  @HiveField(8)
  final RepeatRule repeatRule;

  @HiveField(9)
  final BookingStatus status;

  @HiveField(10)
  final int participants;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final String? notes;

  Booking({
    required this.id,
    this.eventId,
    required this.labId,
    required this.userId,
    required this.title,
    required this.date,
    required this.start,
    required this.end,
    required this.repeatRule,
    required this.status,
    required this.participants,
    required this.createdAt,
    this.notes,
  });

  Booking copyWith({
    String? id,
    String? eventId,
    String? labId,
    String? userId,
    String? title,
    DateTime? date,
    DateTime? start,
    DateTime? end,
    RepeatRule? repeatRule,
    BookingStatus? status,
    int? participants,
    DateTime? createdAt,
    String? notes,
  }) {
    return Booking(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      labId: labId ?? this.labId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      date: date ?? this.date,
      start: start ?? this.start,
      end: end ?? this.end,
      repeatRule: repeatRule ?? this.repeatRule,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'Booking(id: $id, eventId: $eventId, labId: $labId, userId: $userId, title: $title, date: $date, start: $start, end: $end, repeatRule: $repeatRule, status: $status, participants: $participants, createdAt: $createdAt, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booking &&
        other.id == id &&
        other.eventId == eventId &&
        other.labId == labId &&
        other.userId == userId &&
        other.title == title &&
        other.date == date &&
        other.start == start &&
        other.end == end &&
        other.repeatRule == repeatRule &&
        other.status == status &&
        other.participants == participants &&
        other.createdAt == createdAt &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        eventId.hashCode ^
        labId.hashCode ^
        userId.hashCode ^
        title.hashCode ^
        date.hashCode ^
        start.hashCode ^
        end.hashCode ^
        repeatRule.hashCode ^
        status.hashCode ^
        participants.hashCode ^
        createdAt.hashCode ^
        notes.hashCode;
  }
}
