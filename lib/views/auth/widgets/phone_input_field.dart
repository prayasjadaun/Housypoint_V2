import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_text_styles.dart';

/// Mobile number input: country button on the left, the number on the
/// right, a green focus ring, and a tick once the number is complete.
class PhoneInputField extends StatefulWidget {
  const PhoneInputField({
    super.key,
    required this.controller,
    required this.country,
    required this.maxLength,
    required this.onCountryTap,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final Country country;

  /// Digits a full number has in [country].
  final int maxLength;
  final VoidCallback onCountryTap;
  final VoidCallback? onSubmitted;

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_rebuild);
    widget.controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(PhoneInputField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focusNode.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    final complete = widget.controller.text.length == widget.maxLength;
    final radius = BorderRadius.circular(AppRadius.lg);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 60,
      decoration: BoxDecoration(
        color: focused ? AppColors.surface : AppColors.surfaceMuted,
        borderRadius: radius,
        border: Border.all(
          color: focused ? AppColors.primary : AppColors.border,
          width: focused ? 1.6 : 1.2,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          _CountryButton(country: widget.country, onTap: widget.onCountryTap),
          Container(width: 1, height: 28, color: AppColors.border),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              onSubmitted: (_) => widget.onSubmitted?.call(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.maxLength),
              ],
              cursorColor: AppColors.primary,
              style: AppTextStyles.title.copyWith(
                fontSize: 17,
                letterSpacing: 1.2,
              ),
              // Plain field — the container above draws the box
              decoration: InputDecoration(
                hintText: widget.country.example.isNotEmpty
                    ? widget.country.example
                    : 'Mobile number',
                hintStyle: AppTextStyles.title.copyWith(
                  fontSize: 17,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textTertiary,
                ),
                filled: false,
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: complete
                ? const Padding(
                    key: ValueKey('done'),
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(
                      Iconsax.tick_circle_copy,
                      color: AppColors.success,
                      size: 22,
                    ),
                  )
                : const SizedBox(key: ValueKey('empty'), width: 16),
          ),
        ],
      ),
    );
  }
}

class _CountryButton extends StatelessWidget {
  const _CountryButton({required this.country, required this.onTap});

  final Country country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.horizontal(
        left: Radius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 10, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Text(country.flagEmoji, style: const TextStyle(fontSize: 17)),
            ),
            const SizedBox(width: 8),
            Text(
              '+${country.phoneCode}',
              style: AppTextStyles.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Iconsax.arrow_down_1_copy,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
