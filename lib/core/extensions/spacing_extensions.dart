import 'package:flutter/material.dart';

/// Turns raw numbers into gap widgets, e.g. `AppSpacing.md.verticalGap`.
extension SpacingExtensions on double {
  SizedBox get verticalGap => SizedBox(height: this);
  SizedBox get horizontalGap => SizedBox(width: this);
}
