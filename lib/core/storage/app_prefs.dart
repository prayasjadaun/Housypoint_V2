import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive app flags. (Tokens live in [SecureStorageService].)
/// Uses SharedPreferences on purpose: unlike the iOS keychain it is wiped
/// on uninstall, so a reinstall shows onboarding again.
class AppPrefs {
  AppPrefs._();

  static late final SharedPreferences _prefs;

  static const _onboardingSeenKey = 'onboarding_seen';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get onboardingSeen => _prefs.getBool(_onboardingSeenKey) ?? false;

  static Future<void> setOnboardingSeen() =>
      _prefs.setBool(_onboardingSeenKey, true);
}
