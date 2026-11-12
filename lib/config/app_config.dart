import 'dart:io' show Platform;

import 'package:package_info_plus/package_info_plus.dart';

class AppConfig {
  AppConfig._();

  static const String appName = 'Housy Point';

  // Support contacts (same as V1)
  static const String supportEmail = 'support@housypoint.com';
  static const String supportPhone = '919871355121';
  static const String supportWhatsApp = '919220511522';
  static const String officeAddress = 'IFFCO Chowk, Sector 25, Gurugram, Haryana';
  static const String officeMapUrl = 'https://maps.app.goo.gl/rUv7pZy9tSnM6htU7';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.housypoint.housy_point';
  static const String appStoreUrl =
      'https://apps.apple.com/in/app/housypoint/id6749288203';

  /// This device's store page — App Store on iOS, Play Store elsewhere.
  static String get storeUrl => Platform.isIOS ? appStoreUrl : playStoreUrl;

  /// "Rate us" — iOS seedha review sheet kholta hai.
  static String get rateUrl =>
      Platform.isIOS ? '$appStoreUrl?action=write-review' : playStoreUrl;

  /// `1.0.0+1` style — sent as `app_version` on login.
  static String appVersion = '0.0.0';

  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    appVersion = '${info.version}+${info.buildNumber}';
  }
}
