import 'package:flutter/foundation.dart';

/// Platform-wise feature toggles. Change here, every screen follows.
abstract final class FeatureFlags {
  /// Home Loan is hidden on iOS (App Store review), shown on Android.
  static bool get homeLoanEnabled =>
      defaultTargetPlatform != TargetPlatform.iOS;
}
