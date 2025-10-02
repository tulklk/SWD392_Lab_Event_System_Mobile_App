# Setup Instructions

## Quick Start

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```

## First Launch

1. The app will automatically seed initial data:
   - 3 labs (Lab A, Lab B, Lab C)
   - Sample events for the week
   - Admin user account

2. **Login with any role:**
   - **Student**: Basic access to calendar, labs, and bookings
   - **Lab Manager**: Student features + admin panel access
   - **Admin**: Full system access

3. **Explore features:**
   - Calendar: View events and create bookings
   - Labs: Browse available labs and their schedules
   - My Bookings: Manage your personal bookings
   - Admin Panel: Manage labs and events (Admin/Lab Manager only)

## Features Working

✅ **Authentication System**
- Role-based login
- User persistence with Hive

✅ **Calendar View**
- Interactive month calendar
- Daily event listing
- Event joining and booking

✅ **Lab Management**
- Lab browsing with grid view
- Detailed lab information
- Schedule viewing

✅ **Booking System**
- Create bookings with validation
- Conflict detection
- Status management
- Personal booking history

✅ **QR Tickets**
- QR code generation for bookings
- QR ticket viewing

✅ **Admin Panel**
- Lab CRUD operations
- Event management
- Role-based access control

## Troubleshooting

### If you encounter issues:

1. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Check device connection:**
   ```bash
   flutter devices
   ```

3. **For Android emulator:**
   - Ensure emulator is running
   - Enable USB debugging if using physical device

## Architecture

- **State Management**: Riverpod
- **Navigation**: go_router
- **Local Storage**: Hive (offline-first)
- **UI**: Material 3 with custom theming
- **Localization**: English/Vietnamese support

## Next Steps

The app is fully functional with all core features implemented. Future enhancements could include:
- Cloud synchronization
- Push notifications
- Advanced analytics
- Dark mode toggle
- Export functionality
