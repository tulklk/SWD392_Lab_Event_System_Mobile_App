import 'package:hive/hive.dart';
import '../enums/booking_status.dart';
import '../enums/repeat_rule.dart';

class Booking extends HiveObject {
  final String id;
  final String? eventId; // nullable when booking ad-hoc
  final String labId;
  final String userId;
  final String title;
  final DateTime date;
  final DateTime start;
  final DateTime end;
  final RepeatRule repeatRule;
  final BookingStatus status;
  final int participants;
  final DateTime createdAt;
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
