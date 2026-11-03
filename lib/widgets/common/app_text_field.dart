import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

/// Labelled text field with an Iconsax prefix icon.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.icon,
    this.prefix,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.goldStyle = false,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData? icon;

  /// Replaces [icon] — e.g. the `+91` country code.
  final Widget? prefix;
  final TextInputType? keyboardType;
  /// Defaults to Next (moves to the following field); use Done on the last one.
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Ink label/text on a dark fill with a gold focus ring (Refer tab).
  final bool goldStyle;

  static OutlineInputBorder _goldBorder(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.lg),
    borderSide: BorderSide(color: color, width: width),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(color: goldStyle ? AppColors.referInk : null),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          cursorColor: goldStyle ? AppColors.referGold : null,
          style: AppTextStyles.body.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: goldStyle ? AppColors.referInk : null,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefix ??
                (icon == null
                    ? null
                    : Icon(
                        icon,
                        size: 20,
                        color: goldStyle ? AppColors.referMuted : AppColors.textSecondary,
                      )),
            fillColor: goldStyle ? AppColors.referDarkRaised : null,
            hintStyle: goldStyle
                ? AppTextStyles.body.copyWith(color: AppColors.referMuted.withValues(alpha: 0.6))
                : null,
            enabledBorder: goldStyle ? _goldBorder(AppColors.referLine, 1) : null,
            focusedBorder: goldStyle ? _goldBorder(AppColors.referGold, 1.6) : null,
          ),
        ),
      ],
    );
  }
}
