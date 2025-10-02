import 'package:hive/hive.dart';
import '../enums/role.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? studentId;

  @HiveField(3)
  final Role role;

  @HiveField(4)
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    this.studentId,
    required this.role,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? studentId,
    Role? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, studentId: $studentId, role: $role, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.studentId == studentId &&
        other.role == role &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        studentId.hashCode ^
        role.hashCode ^
        createdAt.hashCode;
  }
}
