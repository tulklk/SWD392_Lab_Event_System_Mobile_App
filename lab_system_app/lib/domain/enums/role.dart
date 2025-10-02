import 'package:hive/hive.dart';

part 'role.g.dart';

@HiveType(typeId: 1)
enum Role {
  @HiveField(0)
  student('Student'),
  @HiveField(1)
  labManager('Lab Manager'),
  @HiveField(2)
  admin('Admin');

  const Role(this.displayName);
  final String displayName;
}
