enum Role {
  student('Student'),
  labManager('Lab Manager'),
  admin('Admin');

  const Role(this.displayName);
  final String displayName;
}
