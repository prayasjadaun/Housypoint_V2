import 'package:flutter/foundation.dart';

/// Bottom-nav tabs, in order.
enum ShellTab { home, listings, saved, refer, menu }

/// Which bottom-nav tab is showing. Any screen can switch tabs, e.g. a home
/// count tile opens the Listings tab.
class ShellController extends ChangeNotifier {
  ShellTab tab = ShellTab.home;

  void go(ShellTab value) {
    if (tab == value) return;
    tab = value;
    notifyListeners();
  }

  /// Back to Home after logout so the next login starts fresh.
  void reset() => tab = ShellTab.home;
}
