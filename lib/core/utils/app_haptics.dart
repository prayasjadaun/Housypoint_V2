import 'package:flutter/services.dart';

/// Thin wrapper around HapticFeedback so call sites read as intent.
class AppHaptics {
  AppHaptics._();

  static void tap() => HapticFeedback.lightImpact();
  static void selection() => HapticFeedback.selectionClick();
  static void success() => HapticFeedback.mediumImpact();
}
