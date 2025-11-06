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
    try {
      return Equipment(
        id: json['Id']?.toString() ?? '',
        name: json['Name']?.toString() ?? '',
        description: json['Description']?.toString(),
        serialNumber: json['SerialNumber']?.toString(),
        type: (json['Type'] as num?)?.toInt() ?? 0,
        status: (json['Status'] as num?)?.toInt() ?? 1,
        imageUrl: json['ImageUrl']?.toString(),
        roomId: json['RoomId']?.toString() ?? '',
        lastMaintenanceDate: json['LastMaintenanceDate'] != null
            ? DateTime.tryParse(json['LastMaintenanceDate'].toString())
            : null,
        nextMaintenanceDate: json['NextMaintenanceDate'] != null
            ? DateTime.tryParse(json['NextMaintenanceDate'].toString())
            : null,
        createdAt: json['CreatedAt'] != null
            ? DateTime.tryParse(json['CreatedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        lastUpdatedAt: json['LastUpdatedAt'] != null
            ? DateTime.tryParse(json['LastUpdatedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      throw FormatException('Failed to parse Equipment from JSON: $e\nJSON: $json');
    }
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

