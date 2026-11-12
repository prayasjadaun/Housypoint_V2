import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive app flags. (Tokens live in [SecureStorageService].)
class AppPrefs {
  AppPrefs._();

  static late final SharedPreferences _prefs;

  static const _selectedCityKey = 'selected_city';
  static const _themeModeKey = 'theme_mode';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

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
