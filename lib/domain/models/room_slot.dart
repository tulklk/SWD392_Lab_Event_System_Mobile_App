/// Room Slot model matching tbl_room_slots schema
class RoomSlot {
  final String id;
  final String roomId;
  final int dayOfWeek; // 1: Monday, 2: Tuesday, ..., 7: Sunday
  final DateTime startTime; // Time only
  final DateTime endTime; // Time only
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  RoomSlot({
    required this.id,
    required this.roomId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  RoomSlot copyWith({
    String? id,
    String? roomId,
    int? dayOfWeek,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return RoomSlot(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  factory RoomSlot.fromJson(Map<String, dynamic> json) {
    return RoomSlot(
      id: json['Id'] as String,
      roomId: json['RoomId'] as String,
      dayOfWeek: json['DayOfWeek'] as int,
      startTime: DateTime.parse(json['StartTime'] as String),
      endTime: DateTime.parse(json['EndTime'] as String),
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['LastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'RoomId': roomId,
      'DayOfWeek': dayOfWeek,
      'StartTime': startTime.toIso8601String(),
      'EndTime': endTime.toIso8601String(),
      'CreatedAt': createdAt.toIso8601String(),
      'LastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'RoomSlot(id: $id, roomId: $roomId, dayOfWeek: $dayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomSlot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

