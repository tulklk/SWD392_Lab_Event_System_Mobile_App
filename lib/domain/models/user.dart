import 'package:hive/hive.dart';
import '../enums/role.dart';

/// User model for FPT Lab System
/// Updated to match Supabase tbl_users schema
class User extends HiveObject {
  final String id;
  final String username;
  final String fullname;
  final String email;
  final String? mssv; // Mã số sinh viên
  final int status; // 0: inactive, 1: active, etc.
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final List<Role> roles; // Multiple roles support

  User({
    required this.id,
    required this.username,
    required this.fullname,
    required this.email,
    this.mssv,
    this.status = 1,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.roles = const [],
  });

  // Helper getter for backward compatibility
  String get name => fullname;
  String? get studentId => mssv;
  Role get role => roles.isNotEmpty ? roles.first : Role.student;

  User copyWith({
    String? id,
    String? username,
    String? fullname,
    String? email,
    String? mssv,
    int? status,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    List<Role>? roles,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullname: fullname ?? this.fullname,
      email: email ?? this.email,
      mssv: mssv ?? this.mssv,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      roles: roles ?? this.roles,
    );
  }

  // From JSON (from Supabase)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['Id'] as String,
      username: json['Username'] as String,
      fullname: json['Fullname'] as String,
      email: json['Email'] as String,
      mssv: json['MSSV'] as String?,
      status: json['status'] as int? ?? 1,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['LastUpdatedAt'] as String),
      roles: [], // Will be populated from join
    );
  }

  // To JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Username': username,
      'Fullname': fullname,
      'Email': email,
      'MSSV': mssv,
      'status': status,
      'CreatedAt': createdAt.toIso8601String(),
      'LastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, fullname: $fullname, email: $email, mssv: $mssv, status: $status, roles: $roles)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.username == username &&
        other.fullname == fullname &&
        other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        username.hashCode ^
        fullname.hashCode ^
        email.hashCode;
  }
}
