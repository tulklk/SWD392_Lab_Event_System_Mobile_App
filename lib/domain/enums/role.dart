enum Role {
  student('Student'),
  lecturer('Lecturer'),
  admin('Admin');

  const Role(this.displayName);
  final String displayName;
}
