/// Room model matching tbl_rooms schema
class Room {
  final String id;
  final String name;
  final int capacity;
  final int status; // 0: inactive, 1: active
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  Room({
    required this.id,
    required this.name,
    required this.capacity,
    this.status = 1,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  Room copyWith({
    String? id,
    String? name,
    int? capacity,
    int? status,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['Id'] as String,
      name: json['Name'] as String,
      capacity: json['Capacity'] as int,
      status: json['Status'] as int? ?? 1,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['LastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'Capacity': capacity,
      'Status': status,
      'CreatedAt': createdAt.toIso8601String(),
      'LastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 1;

  @override
  String toString() {
    return 'Room(id: $id, name: $name, capacity: $capacity, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Room && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

