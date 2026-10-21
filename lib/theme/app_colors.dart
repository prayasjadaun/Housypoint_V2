import 'package:flutter/material.dart';

/// Single source of truth for every color in the app.
/// Screens must reference these constants — never a raw `Color(0x..)`.
class AppColors {
  AppColors._();

  // Brand — green + gold from the Housy Point logo
  static const Color primary = Color(0xFF0E8A45);
  static const Color mainGreen = Color(0xFF00C566);
  static const Color primaryDark = Color(0xFF075C2E);
  static const Color primarySoft = Color(0xFFE8F6EE);
  static const Color gold = Color(0xFFF2CF7E);
  static const Color goldDark = Color(0xFFB98A3E);

  static const Color background = Color(0xFFF5F7F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF9FAFB);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE5E7EB);

  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);

  // Menu card accents
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color accentSky = Color(0xFF0EA5E9);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentRose = Color(0xFFF43F5E);
}
