import 'package:flutter/material.dart';

import '../../widgets/common/app_snackbar.dart';

/// Shortcuts on BuildContext so screens don't repeat
/// `MediaQuery.of(context)` / `Theme.of(context)` everywhere.
extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Size get screenSize => MediaQuery.sizeOf(this);
  EdgeInsets get safePadding => MediaQuery.paddingOf(this);

  void showSnackBar(String message, {bool isError = false}) {
    AppSnackBar.show(
      this,
      message,
      type: isError ? AppSnackBarType.error : AppSnackBarType.success,
    );
  }
}
