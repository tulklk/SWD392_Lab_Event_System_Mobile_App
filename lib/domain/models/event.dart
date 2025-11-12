/// Event model matching tbl_events schema
class Event {
  final String id;
  final String createdBy; // userId
  final String title;
  final String? description;
  final bool visibility; // true: public, false: private
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final DateTime? endDate;
  final DateTime? startDate;
  final int status; // 0: draft, 1: active, 2: cancelled
  final String? imageUrl; // URL to event image

  Event({
    required this.id,
    required this.createdBy,
    required this.title,
    this.description,
    this.visibility = true,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.endDate,
    this.startDate,
    this.status = 1,
    this.imageUrl,
  });

  Event copyWith({
    String? id,
    String? createdBy,
    String? title,
    String? description,
    bool? visibility,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    DateTime? endDate,
    DateTime? startDate,
    int? status,
    String? imageUrl,
  }) {
    return Event(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      endDate: endDate ?? this.endDate,
      startDate: startDate ?? this.startDate,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['Id'] as String,
      createdBy: json['CreatedBy'] as String,
      title: json['Title'] as String,
      description: json['Description'] as String?,
      visibility: json['Visibility'] as bool? ?? true,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['LastUpdatedAt'] as String),
      endDate: json['EndDate'] != null
          ? DateTime.parse(json['EndDate'] as String)
          : null,
      startDate: json['StartDate'] != null
          ? DateTime.parse(json['StartDate'] as String)
          : null,
      status: json['Status'] as int? ?? 1,
      imageUrl: json['ImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'CreatedBy': createdBy,
      'Title': title,
      'Description': description,
      'Visibility': visibility,
      'CreatedAt': createdAt.toIso8601String(),
      'LastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'EndDate': endDate?.toIso8601String(),
      'StartDate': startDate?.toIso8601String(),
      'Status': status,
      'ImageUrl': imageUrl,
    };
  }

  bool get isDraft => status == 0;
  bool get isActive => status == 1;
  bool get isCancelled => status == 2;
  bool get isPublic => visibility;
  bool get isPrivate => !visibility;

  // Helper getters for backward compatibility
  DateTime get start => startDate ?? createdAt;
  DateTime get end => endDate ?? createdAt;

  @override
  String toString() {
    return 'Event(id: $id, title: $title, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
