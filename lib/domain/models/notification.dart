/// Notification model matching tbl_notifications schema
class Notification {
  final String id;
  final String title;
  final String content;
  final String targetGroup; // 'all', 'student', 'lecturer', 'admin'
  final DateTime? startDate;
  final DateTime? endDate;
  final int status; // 0: draft, 1: active, 2: expired
  final String createdBy; // userId
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  Notification({
    required this.id,
    required this.title,
    required this.content,
    required this.targetGroup,
    this.startDate,
    this.endDate,
    this.status = 1,
    required this.createdBy,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  Notification copyWith({
    String? id,
    String? title,
    String? content,
    String? targetGroup,
    DateTime? startDate,
    DateTime? endDate,
    int? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      targetGroup: targetGroup ?? this.targetGroup,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['Id'] as String,
      title: json['Title'] as String,
      content: json['Content'] as String,
      targetGroup: json['TargetGroup'] as String,
      startDate: json['StartDate'] != null
          ? DateTime.parse(json['StartDate'] as String)
          : null,
      endDate: json['EndDate'] != null
          ? DateTime.parse(json['EndDate'] as String)
          : null,
      status: json['Status'] as int? ?? 1,
      createdBy: json['CreatedBy'] as String,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['LastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Title': title,
      'Content': content,
      'TargetGroup': targetGroup,
      'StartDate': startDate?.toIso8601String(),
      'EndDate': endDate?.toIso8601String(),
      'Status': status,
      'CreatedBy': createdBy,
      'CreatedAt': createdAt.toIso8601String(),
      'LastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 1;
  bool get isDraft => status == 0;
  bool get isExpired => status == 2;

  @override
  String toString() {
    return 'Notification(id: $id, title: $title, targetGroup: $targetGroup, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Notification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

