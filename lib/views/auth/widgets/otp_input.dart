import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_text_styles.dart';

/// OTP boxes backed by one hidden TextField, so paste and SMS autofill
/// (`AutofillHints.oneTimeCode`) work without juggling focus nodes.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.controller,
    this.length = 5,
    this.onCompleted,
    this.hasError = false,
  });

  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onCompleted;
  final bool hasError;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    final text = widget.controller.text;
    if (text.length == widget.length) widget.onCompleted?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        children: [
          // Invisible field that actually receives input
          Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              showCursor: false,
              enableInteractiveSelection: false,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < widget.length; i++)
                _box(
                  digit: i < text.length ? text[i] : '',
                  isActive: _focusNode.hasFocus &&
                      (i == text.length ||
                          (i == widget.length - 1 && text.length == widget.length)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _box({required String digit, required bool isActive}) {
    final borderColor = widget.hasError
        ? AppColors.error
        : isActive
        ? AppColors.primary
        : digit.isNotEmpty
        ? AppColors.primary.withValues(alpha: 0.35)
        : AppColors.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 56,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: digit.isNotEmpty ? AppColors.primarySoft : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: isActive ? 1.8 : 1.2),
      ),
      child: Text(
        digit,
        style: AppTextStyles.heading.copyWith(color: AppColors.primaryText),
      ),
    );
  }
}
