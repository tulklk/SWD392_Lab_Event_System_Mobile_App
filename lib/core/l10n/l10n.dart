import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Temporary localization setup until flutter_gen is generated
class AppLocalizations {
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('vi', ''),
  ];
  
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  // Basic strings - will be replaced by generated ones
  String get appTitle => 'FPT Lab System';
  String get login => 'Login';
  String get name => 'Name';
  String get studentId => 'Student ID';
  String get role => 'Role';
  String get student => 'Student';
  String get labManager => 'Lab Manager';
  String get admin => 'Admin';
  String get calendar => 'Calendar';
  String get labs => 'Labs';
  String get myBookings => 'My Bookings';
  String get adminPanel => 'Admin';
  String get book => 'Book';
  String get create => 'Create';
  String get cancel => 'Cancel';
  String get save => 'Save';
  String get delete => 'Delete';
  String get edit => 'Edit';
  String get viewSchedule => 'View Schedule';
  String get bookNow => 'Book Now';
  String get qrTicket => 'QR Ticket';
  String get scanQR => 'Scan QR';
  String get capacity => 'Capacity';
  String get location => 'Location';
  String get description => 'Description';
  String get title => 'Title';
  String get date => 'Date';
  String get startTime => 'Start Time';
  String get endTime => 'End Time';
  String get participants => 'Participants';
  String get repeat => 'Repeat';
  String get none => 'None';
  String get weekly => 'Weekly';
  String get pending => 'Pending';
  String get approved => 'Approved';
  String get rejected => 'Rejected';
  String get cancelled => 'Cancelled';
  String get manageLabs => 'Manage Labs';
  String get manageEvents => 'Manage Events';
  String get noEventsToday => 'No events scheduled for today';
  String get noBookings => 'No bookings found';
  String get bookingCreated => 'Booking created successfully';
  String get bookingCancelled => 'Booking cancelled';
  String get conflictDetected => 'Time conflict detected';
  String get required => 'This field is required';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'vi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
