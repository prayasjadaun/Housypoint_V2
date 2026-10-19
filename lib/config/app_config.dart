import 'package:package_info_plus/package_info_plus.dart';

class AppConfig {
  AppConfig._();

  static const String appName = 'Housy Point';

  /// `1.0.0+1` style — sent as `app_version` on login.
  static String appVersion = '0.0.0';

  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    appVersion = '${info.version}+${info.buildNumber}';
  }
}
