import 'dart:async';

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
/// - When the keyboard opens, or focus moves to another field while it is
///   open, the focused field is scrolled into view together with some room
///   below it, so the next field or the submit button isn't hidden.
class KeyboardDismisser extends StatefulWidget {
  const KeyboardDismisser({super.key, required this.child});

  final Widget child;

  static void dismiss() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  State<KeyboardDismisser> createState() => _KeyboardDismisserState();
}

class _KeyboardDismisserState extends State<KeyboardDismisser> {
  static const double _toolbarHeight = 44;

  /// Space revealed under the focused field — about a field or a button
  /// plus its gap.
  static const double _revealBelow = 200;

  double _lastInset = 0;
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChanged);
    _settle?.cancel();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_lastInset > 0) _scheduleReveal();
  }

  /// The inset changes every frame while the keyboard animates; reveal
  /// once it has settled.
  void _scheduleReveal() {
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 120), _reveal);
  }

  void _reveal() {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null || !focused.mounted) return;
    final isTextField =
        focused.widget is EditableText ||
        focused.findAncestorStateOfType<EditableTextState>() != null;
    if (!isTextField) return;

    final box = focused.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;

    // Never ask for more than the viewport fits, or the field itself
    // would be pushed off the top.
    final viewport = Scrollable.maybeOf(focused)?.position.viewportDimension;
    var below = _revealBelow;
    if (viewport != null) {
      below = (viewport - box.size.height - 24).clamp(0.0, _revealBelow);
    }
    box.showOnScreen(
      rect: Rect.fromLTRB(0, -12, box.size.width, box.size.height + below),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final inset = mq.viewInsets.bottom;
    if (inset != _lastInset) {
      if (inset > _lastInset) _scheduleReveal();
      _lastInset = inset;
    }
    final keyboardOpen = inset > 0;
    final showToolbar =
        keyboardOpen && defaultTargetPlatform == TargetPlatform.iOS;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: KeyboardDismisser.dismiss,
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
            child: widget.child,
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
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Previous',
              onPressed: () => _move(false),
              icon: Icon(
                Iconsax.arrow_up_2_copy,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            IconButton(
              tooltip: 'Next',
              onPressed: () => _move(true),
              icon: Icon(
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
