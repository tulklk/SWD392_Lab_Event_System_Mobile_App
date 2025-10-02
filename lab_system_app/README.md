# FPT University Lab Events Management System

A comprehensive Flutter application for managing lab events, activity booking, and scheduling at FPT University. Built with modern Flutter architecture and Material 3 design.

## Features

### 🎯 Core Features
- **User Authentication**: Role-based login (Student, Lab Manager, Admin)
- **Calendar View**: Interactive calendar with event scheduling
- **Lab Management**: View and manage laboratory facilities
- **Booking System**: Create, manage, and track lab bookings
- **QR Tickets**: Generate and scan QR codes for booking verification
- **Admin Panel**: Comprehensive management tools for administrators

### 🏗️ Architecture
- **State Management**: Riverpod with hooks_riverpod
- **Navigation**: go_router for declarative routing
- **Local Storage**: Hive for offline-first data persistence
- **UI Framework**: Material 3 with custom theming
- **Internationalization**: English and Vietnamese support

## Tech Stack

- **Flutter**: 3.x with Dart latest
- **State Management**: flutter_riverpod ^2.5.1
- **Navigation**: go_router ^14.2.0
- **Calendar**: table_calendar ^3.0.9
- **Local Storage**: hive ^2.2.3, hive_flutter ^1.1.0
- **QR Code**: qr_flutter ^4.1.0
- **Utilities**: uuid ^4.4.0, intl ^0.20.2

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # App configuration and initialization
├── core/                     # Core utilities and themes
│   ├── theme/               # Material 3 theming
│   ├── utils/               # Utility classes (Result, etc.)
│   └── l10n/                # Localization configuration
├── data/                     # Data layer
│   ├── local/               # Hive adapters and local storage
│   ├── repositories/        # Repository implementations
│   └── seed/                # Seed data for initial setup
├── domain/                   # Domain layer
│   ├── models/              # Data models (User, Lab, Event, Booking)
│   └── enums/               # Enumerations (Role, Status, etc.)
├── features/                 # Feature modules
│   ├── auth/                # Authentication
│   ├── home/                # Home screen and navigation
│   ├── calendar/            # Calendar functionality
│   ├── labs/                # Lab management
│   ├── bookings/            # Booking system
│   └── admin/               # Admin features
└── routes/                   # Navigation configuration
```

## Getting Started

### Prerequisites
- Flutter SDK 3.x or later
- Dart SDK latest
- Android Studio / VS Code with Flutter extensions
- Android emulator or physical device

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd lab_system_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code (if needed)**
   ```bash
   # Generate Hive adapters
   flutter packages pub run build_runner build --delete-conflicting-outputs
   
   # Generate localization files
   flutter gen-l10n
   ```

4. **Run the application**
   ```bash
   # For Android emulator
   flutter run -d emulator-5554
   
   # Or simply
   flutter run
   ```

### Android Emulator Setup

1. **Enable Android SDK components**
   - Open Android Studio
   - Go to SDK Manager
   - Install Android SDK Platform 34 (API 34)
   - Install Android SDK Build-Tools 34.0.0

2. **Create AVD (Android Virtual Device)**
   - Open AVD Manager in Android Studio
   - Create new virtual device
   - Recommended: Pixel 8a API 36
   - Start the emulator

3. **Troubleshooting**
   - Ensure emulator is running before `flutter run`
   - Check device connection: `flutter devices`
   - Enable USB debugging if using physical device

## Usage

### First Launch
1. The app will automatically seed initial data (3 labs, sample events)
2. Login with any role (Student, Lab Manager, Admin)
3. Explore the different features based on your role

### User Roles

#### Student
- View calendar and upcoming events
- Browse available labs
- Create and manage personal bookings
- Generate QR tickets for bookings

#### Lab Manager
- All Student features
- Access to admin panel
- Manage labs and events
- View booking analytics

#### Admin
- All Lab Manager features
- Full system administration
- User management capabilities
- System-wide analytics

### Key Features

#### Calendar
- Month view with event indicators
- Tap dates to view daily events
- Join events or create new bookings

#### Labs
- Grid view of available labs
- Detailed lab information
- Schedule viewing and booking

#### Bookings
- Personal booking management
- Status tracking (Pending, Approved, Rejected, Cancelled)
- QR ticket generation
- Conflict detection

#### Admin Panel
- Lab CRUD operations
- Event management
- Booking oversight
- System analytics

## Development

### Code Generation
The app uses code generation for:
- Hive type adapters (models)
- Localization files

Run these commands when models change:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

### Adding New Features
1. Create feature folder in `lib/features/`
2. Add domain models if needed
3. Implement repository methods
4. Create UI screens
5. Update routing configuration
6. Add localization strings

### State Management
The app uses Riverpod for state management:
- `StateNotifierProvider` for complex state
- `Provider` for simple dependencies
- `AsyncNotifier` for async operations

### Local Storage
Hive is used for local storage:
- Type-safe with generated adapters
- Offline-first approach
- Easy migration to cloud storage later

## Future Enhancements

### Planned Features
- [ ] Dark mode toggle
- [ ] Export bookings as .ics files
- [ ] Advanced search and filtering
- [ ] Push notifications
- [ ] Cloud synchronization (Firebase/Supabase)
- [ ] Real-time booking updates
- [ ] Advanced analytics dashboard
- [ ] Multi-language support expansion

### Technical Improvements
- [ ] Unit and widget tests
- [ ] Integration tests
- [ ] Performance optimization
- [ ] Error handling improvements
- [ ] Accessibility enhancements
- [ ] CI/CD pipeline setup

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## Acknowledgments

- FPT University for the project requirements
- Flutter team for the excellent framework
- Open source community for the packages used