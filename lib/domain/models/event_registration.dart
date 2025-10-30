/// Event Registration model 
/// For students registering to events
class EventRegistration {
  final String id;
  final String eventId;
  final String userId;
  final int status; // 0: pending, 1: approved, 2: rejected
  final String? notes;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final String? attendanceCode;

  EventRegistration({
    required this.id,
    required this.eventId,
    required this.userId,
    this.status = 0,
    this.notes,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.attendanceCode,
  });

  EventRegistration copyWith({
    String? id,
    String? eventId,
    String? userId,
    int? status,
    String? notes,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    String? attendanceCode,
  }) {
    return EventRegistration(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      attendanceCode: attendanceCode ?? this.attendanceCode,
    );
  }

  factory EventRegistration.fromJson(Map<String, dynamic> json) {
    return EventRegistration(
      id: json['Id'] as String,
      eventId: json['EventId'] as String,
      userId: json['UserId'] as String,
      status: json['Status'] as int? ?? 0,
      notes: json['Notes'] as String?,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['LastUpdatedAt'] as String),
      attendanceCode: json['AttendanceCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'EventId': eventId,
      'UserId': userId,
      'Status': status,
      'Notes': notes,
      'CreatedAt': createdAt.toIso8601String(),
      'LastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'AttendanceCode': attendanceCode,
    };
  }

  bool get isPending => status == 0;
  bool get isApproved => status == 1;
  bool get isRejected => status == 2;

  @override
  String toString() {
    return 'EventRegistration(id: $id, eventId: $eventId, userId: $userId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventRegistration && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

