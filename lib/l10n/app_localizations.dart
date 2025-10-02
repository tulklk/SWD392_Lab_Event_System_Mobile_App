import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'FPT Lab System'**
  String get appTitle;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Student ID field label
  ///
  /// In en, this message translates to:
  /// **'Student ID'**
  String get studentId;

  /// Role field label
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// Student role
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// Lab Manager role
  ///
  /// In en, this message translates to:
  /// **'Lab Manager'**
  String get labManager;

  /// Admin role
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// Calendar tab title
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// Labs tab title
  ///
  /// In en, this message translates to:
  /// **'Labs'**
  String get labs;

  /// My Bookings tab title
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// Admin tab title
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminPanel;

  /// Book button text
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// Create button text
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// View Schedule button text
  ///
  /// In en, this message translates to:
  /// **'View Schedule'**
  String get viewSchedule;

  /// Book Now button text
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// QR Ticket button text
  ///
  /// In en, this message translates to:
  /// **'QR Ticket'**
  String get qrTicket;

  /// Scan QR button text
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQR;

  /// Capacity field label
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// Location field label
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Description field label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Title field label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Date field label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Start Time field label
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// End Time field label
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// Participants field label
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// Repeat field label
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// None option
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// Weekly option
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// Pending status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Approved status
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// Rejected status
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// Cancelled status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// Manage Labs title
  ///
  /// In en, this message translates to:
  /// **'Manage Labs'**
  String get manageLabs;

  /// Manage Events title
  ///
  /// In en, this message translates to:
  /// **'Manage Events'**
  String get manageEvents;

  /// Message when no events are scheduled for the selected day
  ///
  /// In en, this message translates to:
  /// **'No events scheduled for today'**
  String get noEventsToday;

  /// Message when user has no bookings
  ///
  /// In en, this message translates to:
  /// **'No bookings found'**
  String get noBookings;

  /// Success message when booking is created
  ///
  /// In en, this message translates to:
  /// **'Booking created successfully'**
  String get bookingCreated;

  /// Success message when booking is cancelled
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get bookingCancelled;

  /// Error message when there's a time conflict
  ///
  /// In en, this message translates to:
  /// **'Time conflict detected'**
  String get conflictDetected;

  /// Validation message for required fields
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get required;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
