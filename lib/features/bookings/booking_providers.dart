import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A simple counter to signal a refresh for the My Bookings screen.
/// Increment its state to trigger a refresh.
class MyBookingsRefreshNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }
  
  void refresh() {
    state = state + 1;
  }
}

final myBookingsRefreshProvider = NotifierProvider<MyBookingsRefreshNotifier, int>(() {
  return MyBookingsRefreshNotifier();
});

/// A provider to signal navigation to My Bookings tab.
/// Set to true to trigger navigation.
class NavigateToMyBookingsNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }
  
  void navigate() {
    state = true;
    // Reset to false after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      state = false;
    });
  }
}

final navigateToMyBookingsProvider = NotifierProvider<NavigateToMyBookingsNotifier, bool>(() {
  return NavigateToMyBookingsNotifier();
});

