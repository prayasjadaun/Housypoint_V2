import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Typed access to Firebase Remote Config.
///
/// Keys (create them in the Firebase console, project `housypoint-48b1f`):
/// - `force_update` (bool) + `minimum_required_version` (e.g. "2.0.0")
/// - `latest_version`, `update_message`
/// - `android_store_url`, `ios_store_url`
/// - `launcher_icon_alias` — festive app icon, same key V1 used
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  static const keyForceUpdate = 'force_update';
  static const keyMinimumVersion = 'minimum_required_version';
  static const keyLatestVersion = 'latest_version';
  static const keyUpdateMessage = 'update_message';
  static const keyAndroidStoreUrl = 'android_store_url';
  static const keyIosStoreUrl = 'ios_store_url';
  static const keyLauncherIconAlias = 'launcher_icon_alias';

  static const Map<String, dynamic> _defaults = {
    keyForceUpdate: false,
    keyMinimumVersion: '0.0.0',
    keyLatestVersion: '',
    keyUpdateMessage: '',
    keyAndroidStoreUrl:
        'https://play.google.com/store/apps/details?id=com.housypoint.housy_point',
    keyIosStoreUrl: '',
    keyLauncherIconAlias: 'default',
  };

  final FirebaseRemoteConfig _config = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      await _config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );
      await _config.setDefaults(_defaults);
      await _config.fetchAndActivate();
      _config.onConfigUpdated.listen((_) => _config.activate());
    } catch (e) {
      // Defaults keep working offline / on fetch failure.
      debugPrint('[RemoteConfig] fetch failed: $e');
    }
  }

  bool get forceUpdate => _config.getBool(keyForceUpdate);
  String get minimumVersion => _config.getString(keyMinimumVersion);
  String get latestVersion => _config.getString(keyLatestVersion);
  String get updateMessage => _config.getString(keyUpdateMessage);
  String get androidStoreUrl => _config.getString(keyAndroidStoreUrl);
  String get iosStoreUrl => _config.getString(keyIosStoreUrl);
  String get launcherIconAlias => _config.getString(keyLauncherIconAlias);
}
