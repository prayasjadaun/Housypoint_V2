import 'package:flutter/widgets.dart';

/// Bottom-nav tabs, in order.
enum ShellTab { home, listings, saved, refer, menu }

/// Which bottom-nav tab is showing. Any screen can switch tabs, e.g. a home
/// count tile opens the Listings tab.
class ShellController extends ChangeNotifier {
  ShellTab tab = ShellTab.home;

  /// Har tab ka primary scroll controller — MainShellScreen inhe
  /// PrimaryScrollController se tab ke page tak pahunchata hai, to tab ki
  /// main list (jiska apna controller nahi) khud attach ho jaati hai.
  final Map<ShellTab, ScrollController> scrollControllers = {
    for (final t in ShellTab.values) t: ScrollController(),
  };

  void go(ShellTab value) {
    if (tab == value) return;
    tab = value;
    notifyListeners();
  }

  /// Bottom nav tap. Jo tab pehle se khula hai us par tap (single ya double)
  /// → us tab ki list top par; doosre tab par tap → tab switch.
  void tap(ShellTab value) {
    if (tab == value) {
      scrollToTop(value);
    } else {
      go(value);
    }
  }

  void scrollToTop(ShellTab value) {
    final c = scrollControllers[value]!;
    if (!c.hasClients) return;
    c.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  /// Back to Home after logout so the next login starts fresh.
  void reset() => tab = ShellTab.home;

  @override
  void dispose() {
    for (final c in scrollControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
