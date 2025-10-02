import 'package:hive/hive.dart';

part 'lab.g.dart';

@HiveType(typeId: 1)
class Lab extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String location;

  @HiveField(3)
  final int capacity;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
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
