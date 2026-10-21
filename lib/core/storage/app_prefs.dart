import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive app flags. (Tokens live in [SecureStorageService].)
/// Uses SharedPreferences on purpose: unlike the iOS keychain it is wiped
/// on uninstall, so a reinstall shows onboarding again.
class AppPrefs {
  AppPrefs._();

  static late final SharedPreferences _prefs;

  static const _onboardingSeenKey = 'onboarding_seen';
  static const _selectedCityKey = 'selected_city';
  static const _themeModeKey = 'theme_mode';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get onboardingSeen => _prefs.getBool(_onboardingSeenKey) ?? false;

  static Future<void> setOnboardingSeen() =>
      _prefs.setBool(_onboardingSeenKey, true);

  /// City picked on the home filter; null = all cities.
  static String? get selectedCity => _prefs.getString(_selectedCityKey);

  static Future<void> setSelectedCity(String? city) => city == null
      ? _prefs.remove(_selectedCityKey)
      : _prefs.setString(_selectedCityKey, city);

  /// ThemeMode name (light / dark / system); null = never chosen.
  static String? get themeMode => _prefs.getString(_themeModeKey);

  static Future<void> setThemeMode(String mode) =>
      _prefs.setString(_themeModeKey, mode);
}
