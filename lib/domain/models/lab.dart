import 'package:hive/hive.dart';

class Lab extends HiveObject {
  final String id;
  final String name;
  final String location;
  final int capacity;
  final String description;
  final DateTime createdAt;
  final bool isActive;

  Lab({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.description,
    required this.createdAt,
    this.isActive = true,
  });

  Lab copyWith({
    String? id,
    String? name,
    String? location,
    int? capacity,
    String? description,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Lab(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Lab(id: $id, name: $name, location: $location, capacity: $capacity, description: $description, createdAt: $createdAt, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lab &&
        other.id == id &&
        other.name == name &&
        other.location == location &&
        other.capacity == capacity &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        location.hashCode ^
        capacity.hashCode ^
        description.hashCode ^
        createdAt.hashCode ^
        isActive.hashCode;
  }
}
