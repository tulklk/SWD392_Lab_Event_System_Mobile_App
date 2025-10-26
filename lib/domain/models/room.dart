/// Room model matching tbl_rooms schema
class Room {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final int capacity;
  final int status; // 0: inactive, 1: active
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  Room({
    required this.id,
    required this.name,
    this.description,
    this.location,
    required this.capacity,
    this.status = 1,
    this.imageUrl,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  Room copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    int? capacity,
    int? status,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['Id'] as String,
      name: json['Name'] as String,
      description: json['Description'] as String?,
      location: json['Location'] as String?,
      capacity: json['Capacity'] as int,
      status: json['Status'] as int? ?? 1,
      imageUrl: json['ImageUrl'] as String?,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['LastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'Description': description,
      'Location': location,
      'Capacity': capacity,
      'Status': status,
      'ImageUrl': imageUrl,
      'CreatedAt': createdAt.toIso8601String(),
      'LastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 1;

  @override
  String toString() {
    return 'Room(id: $id, name: $name, location: $location, capacity: $capacity, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Room && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

