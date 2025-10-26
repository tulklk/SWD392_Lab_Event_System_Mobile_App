/// Lab Member model matching tbl_lab_members schema
class LabMember {
  final String id;
  final String labId;
  final String userId;
  final int role; // 0: member, 1: leader, 2: assistant
  final int status; // 0: inactive, 1: active
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  LabMember({
    required this.id,
    required this.labId,
    required this.userId,
    this.role = 0,
    this.status = 1,
    this.joinedAt,
    this.leftAt,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  LabMember copyWith({
    String? id,
    String? labId,
    String? userId,
    int? role,
    int? status,
    DateTime? joinedAt,
    DateTime? leftAt,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return LabMember(
      id: id ?? this.id,
      labId: labId ?? this.labId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  factory LabMember.fromJson(Map<String, dynamic> json) {
    return LabMember(
      id: json['Id'] as String,
      labId: json['LabId'] as String,
      userId: json['UserId'] as String,
      role: json['Role'] as int? ?? 0,
      status: json['Status'] as int? ?? 1,
      joinedAt: json['JoinedAt'] != null
          ? DateTime.parse(json['JoinedAt'] as String)
          : null,
      leftAt: json['LeftAt'] != null
          ? DateTime.parse(json['LeftAt'] as String)
          : null,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['LastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'LabId': labId,
      'UserId': userId,
      'Role': role,
      'Status': status,
      'JoinedAt': joinedAt?.toIso8601String(),
      'LeftAt': leftAt?.toIso8601String(),
      'CreatedAt': createdAt.toIso8601String(),
      'LastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 1;
  bool get isMember => role == 0;
  bool get isLeader => role == 1;
  bool get isAssistant => role == 2;

  String get roleString {
    switch (role) {
      case 0:
        return 'Member';
      case 1:
        return 'Leader';
      case 2:
        return 'Assistant';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'LabMember(id: $id, labId: $labId, userId: $userId, role: $roleString, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LabMember && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

