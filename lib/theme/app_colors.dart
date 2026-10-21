import 'package:flutter/material.dart';

/// Single source of truth for every color in the app.
/// Screens must reference these — never a raw `Color(0x..)`.
class AppColors {
  AppColors._();

  // Brand — green + gold from the Housy Point logo
  static const Color primary = Color(0xFF0E8A45);
  static const Color mainGreen = Color(0xFF00C566);
  static const Color primaryDark = Color(0xFF075C2E);
  static const Color primaryLight = Color(0xFF34B36A);
  static const Color gold = Color(0xFFF2CF7E);
  static const Color goldDark = Color(0xFFB98A3E);

  // Neutrals — follow the active light/dark theme. [isDark] is set by
  // ThemeController, which also rebuilds the whole tree when it flips, so
  // these can't be `const`.
  static bool isDark = false;

  static Color get primarySoft => isDark ? const Color(0xFF15301F) : const Color(0xFFE8F6EE);

  static Color get background => isDark ? const Color(0xFF0F1112) : const Color(0xFFF5F7F8);
  static Color get surface => isDark ? const Color(0xFF1A1D1F) : const Color(0xFFFFFFFF);
  static Color get surfaceMuted => isDark ? const Color(0xFF222629) : const Color(0xFFF9FAFB);

  static Color get textPrimary => isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
  static Color get textSecondary => isDark ? const Color(0xFFB8BEC6) : const Color(0xFF6B7280);
  static Color get textTertiary => isDark ? const Color(0xFF8C939C) : const Color(0xFF9CA3AF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Fixed near-black — for always-dark cards/snackbars and text on gold,
  /// which must not flip in dark mode (unlike [textPrimary]).
  static const Color ink = Color(0xFF111827);

  static Color get border => isDark ? const Color(0xFF2C3134) : const Color(0xFFE5E7EB);

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
