/// Equipment model matching tbl_equipments schema
class Equipment {
  final String id;
  final String name;
  final String? description;
  final String? serialNumber;
  final int type; // Equipment type category
  final int status; // 0: inactive, 1: active, 2: maintenance
  final String? imageUrl;
  final String roomId;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  Equipment({
    required this.id,
    required this.name,
    this.description,
    this.serialNumber,
    required this.type,
    this.status = 1,
    this.imageUrl,
    required this.roomId,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  Equipment copyWith({
    String? id,
    String? name,
    String? description,
    String? serialNumber,
    int? type,
    int? status,
    String? imageUrl,
    String? roomId,
    DateTime? lastMaintenanceDate,
    DateTime? nextMaintenanceDate,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      serialNumber: serialNumber ?? this.serialNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      roomId: roomId ?? this.roomId,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['Id'] as String,
      name: json['Name'] as String,
      description: json['Description'] as String?,
      serialNumber: json['SerialNumber'] as String?,
      type: json['Type'] as int,
      status: json['Status'] as int? ?? 1,
      imageUrl: json['ImageUrl'] as String?,
      roomId: json['RoomId'] as String,
      lastMaintenanceDate: json['LastMaintenanceDate'] != null
          ? DateTime.parse(json['LastMaintenanceDate'] as String)
          : null,
      nextMaintenanceDate: json['NextMaintenanceDate'] != null
          ? DateTime.parse(json['NextMaintenanceDate'] as String)
          : null,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['LastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'Description': description,
      'SerialNumber': serialNumber,
      'Type': type,
      'Status': status,
      'ImageUrl': imageUrl,
      'RoomId': roomId,
      'LastMaintenanceDate': lastMaintenanceDate?.toIso8601String(),
      'NextMaintenanceDate': nextMaintenanceDate?.toIso8601String(),
      'CreatedAt': createdAt.toIso8601String(),
      'LastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 1;
  bool get needsMaintenance => status == 2;

  @override
  String toString() {
    return 'Equipment(id: $id, name: $name, serialNumber: $serialNumber, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Equipment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

