import 'package:hive/hive.dart';

part 'event.g.dart';

@HiveType(typeId: 2)
class Event extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String labId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final DateTime start;

  @HiveField(5)
  final DateTime end;

  @HiveField(6)
  final String createdBy;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final bool isActive;

  Event({
    required this.id,
    required this.labId,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    required this.createdBy,
    required this.createdAt,
    this.isActive = true,
  });

  Event copyWith({
    String? id,
    String? labId,
    String? title,
    String? description,
    DateTime? start,
    DateTime? end,
    String? createdBy,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Event(
      id: id ?? this.id,
      labId: labId ?? this.labId,
      title: title ?? this.title,
      description: description ?? this.description,
      start: start ?? this.start,
      end: end ?? this.end,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Event(id: $id, labId: $labId, title: $title, description: $description, start: $start, end: $end, createdBy: $createdBy, createdAt: $createdAt, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event &&
        other.id == id &&
        other.labId == labId &&
        other.title == title &&
        other.description == description &&
        other.start == start &&
        other.end == end &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        labId.hashCode ^
        title.hashCode ^
        description.hashCode ^
        start.hashCode ^
        end.hashCode ^
        createdBy.hashCode ^
        createdAt.hashCode ^
        isActive.hashCode;
  }
}
