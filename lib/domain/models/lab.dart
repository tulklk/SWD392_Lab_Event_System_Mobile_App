/// Lab model matching tbl_labs schema
class Lab {
  final String id;
  final String name;
  final String? location;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final int status; // 0: inactive, 1: active, 2: maintenance
  final String? roomId; // Made nullable as it might not exist in database

  Lab({
    required this.id,
    required this.name,
    this.location,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.status = 1,
    this.roomId,
  });

  Lab copyWith({
    String? id,
    String? name,
    String? location,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    int? status,
    String? roomId,
  }) {
    return Lab(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
    );
  }

  factory Lab.fromJson(Map<String, dynamic> json) {
    return Lab(
      id: json['Id']?.toString() ?? '',
      name: json['Name']?.toString() ?? '',
      location: json['Location']?.toString(),
      createdAt: json['CreatedAt'] != null 
          ? DateTime.parse(json['CreatedAt'].toString())
          : DateTime.now(),
      lastUpdatedAt: json['LastUpdatedAt'] != null
          ? DateTime.parse(json['LastUpdatedAt'].toString())
          : DateTime.now(),
      status: json['Status'] as int? ?? 1,
      roomId: json['RoomId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'Location': location,
      'CreatedAt': createdAt.toIso8601String(),
      'LastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'Status': status,
      'RoomId': roomId,
    };
  }

  bool get isActive => status == 1;
  bool get isInMaintenance => status == 2;

  @override
  String toString() {
    return 'Lab(id: $id, name: $name, location: $location, status: $status, roomId: $roomId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lab && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
