/// Report model matching tbl_reports schema
class Report {
  final String id;
  final String title;
  final String? description;
  final int type; // 0: bug, 1: feedback, 2: equipment issue, etc.
  final String? imageUrl;
  final DateTime reportedDate;
  final int status; // 0: pending, 1: resolved, 2: rejected
  final String reporterId; // userId
  final String? adminResponse;
  final DateTime? resolvedAt;
  final String? resolvedBy; // admin userId
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  Report({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.imageUrl,
    required this.reportedDate,
    this.status = 0,
    required this.reporterId,
    this.adminResponse,
    this.resolvedAt,
    this.resolvedBy,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  Report copyWith({
    String? id,
    String? title,
    String? description,
    int? type,
    String? imageUrl,
    DateTime? reportedDate,
    int? status,
    String? reporterId,
    String? adminResponse,
    DateTime? resolvedAt,
    String? resolvedBy,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      reportedDate: reportedDate ?? this.reportedDate,
      status: status ?? this.status,
      reporterId: reporterId ?? this.reporterId,
      adminResponse: adminResponse ?? this.adminResponse,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['Id'] as String,
      title: json['Title'] as String,
      description: json['Description'] as String?,
      type: json['Type'] as int,
      imageUrl: json['ImageUrl'] as String?,
      reportedDate: DateTime.parse(json['ReportedDate'] as String),
      status: json['Status'] as int? ?? 0,
      reporterId: json['ReporterId'] as String,
      adminResponse: json['AdminResponse'] as String?,
      resolvedAt: json['ResolvedAt'] != null
          ? DateTime.parse(json['ResolvedAt'] as String)
          : null,
      resolvedBy: json['ResolvedBy'] as String?,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['LastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Title': title,
      'Description': description,
      'Type': type,
      'ImageUrl': imageUrl,
      'ReportedDate': reportedDate.toIso8601String(),
      'Status': status,
      'ReporterId': reporterId,
      'AdminResponse': adminResponse,
      'ResolvedAt': resolvedAt?.toIso8601String(),
      'ResolvedBy': resolvedBy,
      'CreatedAt': createdAt.toIso8601String(),
      'LastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  bool get isPending => status == 0;
  bool get isResolved => status == 1;
  bool get isRejected => status == 2;

  String get typeString {
    switch (type) {
      case 0:
        return 'Bug';
      case 1:
        return 'Feedback';
      case 2:
        return 'Equipment Issue';
      default:
        return 'Other';
    }
  }

  @override
  String toString() {
    return 'Report(id: $id, title: $title, type: $typeString, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Report && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

