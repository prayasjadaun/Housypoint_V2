import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// App-wide keyboard behaviour, mounted once in `MaterialApp.builder`:
///
/// - Tapping anywhere outside a text field closes the keyboard and removes
///   focus. Buttons and other fields still win their own taps, because the
///   innermost tap recognizer wins the gesture arena.
/// - On iOS a slim toolbar (↑ ↓ Done) sits on top of the keyboard, since the
///   iOS number/phone pads have no return key. Android keyboards already
///   show Next/Done keys, so it's iOS only.
class KeyboardDismisser extends StatelessWidget {
  const KeyboardDismisser({super.key, required this.child});

  final Widget child;

  static const double _toolbarHeight = 44;

  static void dismiss() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardOpen = mq.viewInsets.bottom > 0;
    final showToolbar =
        keyboardOpen && defaultTargetPlatform == TargetPlatform.iOS;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: dismiss,
      child: Stack(
        children: [
          // Report the toolbar as part of the keyboard, so Scaffolds resize
          // above it and nothing hides behind the bar.
          MediaQuery(
            data: showToolbar
                ? mq.copyWith(
                    viewInsets: mq.viewInsets.copyWith(
                      bottom: mq.viewInsets.bottom + _toolbarHeight,
                    ),
                  )
                : mq,
            child: child,
          ),
          if (showToolbar)
            Positioned(
              left: 0,
              right: 0,
              bottom: mq.viewInsets.bottom,
              height: _toolbarHeight,
              child: const _KeyboardToolbar(),
            ),
        ],
      ),
    );
  }
}

class _KeyboardToolbar extends StatelessWidget {
  const _KeyboardToolbar();

  void _move(bool forward) {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return;
    forward ? focus.nextFocus() : focus.previousFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Previous',
              onPressed: () => _move(false),
              icon: const Icon(
                Iconsax.arrow_up_2_copy,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            IconButton(
              tooltip: 'Next',
              onPressed: () => _move(true),
              icon: const Icon(
                Iconsax.arrow_down_1_copy,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: KeyboardDismisser.dismiss,
              child: Text(
                'Done',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
