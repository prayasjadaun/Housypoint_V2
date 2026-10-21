import 'package:flutter/material.dart';

import '../core/storage/app_prefs.dart';
import '../theme/app_colors.dart';

/// Holds the light/dark/system theme preference, persists it on-device and
/// keeps [AppColors.isDark] in sync (including OS dark-mode changes while
/// set to System).
class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  ThemeController() {
    mode = ThemeMode.values.where((m) => m.name == AppPrefs.themeMode).firstOrNull ?? ThemeMode.system;
    AppColors.isDark = _resolveDark();
    WidgetsBinding.instance.addObserver(this);
  }

  late ThemeMode mode;

  bool get isDark => AppColors.isDark;

  bool _resolveDark() => switch (mode) {
    ThemeMode.light => false,
    ThemeMode.dark => true,
    ThemeMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark,
  };

  void _apply() {
    final dark = _resolveDark();
    if (dark == AppColors.isDark) return;
    AppColors.isDark = dark;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode newMode) async {
    if (mode == newMode) return;
    mode = newMode;
    _apply();
    // Mode changed but brightness didn't (e.g. Light → System on a light
    // phone) — still notify so the Preferences label updates.
    notifyListeners();
    await AppPrefs.setThemeMode(newMode.name);
  }

  @override
  void didChangePlatformBrightness() {
    if (mode == ThemeMode.system) _apply();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
