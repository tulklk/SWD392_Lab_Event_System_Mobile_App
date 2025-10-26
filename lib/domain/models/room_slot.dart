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
      startTime: _parseTime(json['StartTime'] as String),
      endTime: _parseTime(json['EndTime'] as String),
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['LastUpdatedAt'] as String),
    );
  }

  // Parse time string (HH:mm:ss) from Supabase to DateTime
  static DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]), // hour
      int.parse(parts[1]), // minute
      parts.length > 2 ? int.parse(parts[2].split('.')[0]) : 0, // second
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'RoomId': roomId,
      'DayOfWeek': dayOfWeek,
      'StartTime': _formatTime(startTime),
      'EndTime': _formatTime(endTime),
      'CreatedAt': createdAt.toIso8601String(),
      'LastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  // Format DateTime to time string (HH:mm:ss) for Supabase
  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
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

