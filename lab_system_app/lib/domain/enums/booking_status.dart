enum BookingStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),
  cancelled('Cancelled');

  const BookingStatus(this.displayName);
  final String displayName;
}
