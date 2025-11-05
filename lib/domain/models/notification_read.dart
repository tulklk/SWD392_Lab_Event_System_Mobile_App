/// NotificationRead model matching tbl_notification_reads schema
class NotificationRead {
  final String id;
  final String notificationId;
  final String userId;
  final DateTime readAt;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  NotificationRead({
    required this.id,
    required this.notificationId,
    required this.userId,
    required this.readAt,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  factory NotificationRead.fromJson(Map<String, dynamic> json) {
    return NotificationRead(
      id: json['Id'] as String,
      notificationId: json['NotificationId'] as String,
      userId: json['UserId'] as String,
      readAt: DateTime.parse(json['ReadAt'] as String),
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['LastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'NotificationId': notificationId,
      'UserId': userId,
      'ReadAt': readAt.toIso8601String(),
      'CreatedAt': createdAt.toIso8601String(),
      'LastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }
}

