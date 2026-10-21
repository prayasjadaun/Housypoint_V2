import 'package:country_picker/country_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../controllers/auth_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/app_haptics.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import 'widgets/auth_layout.dart';
import 'widgets/country_picker_sheet.dart';
import 'widgets/phone_input_field.dart';

/// Login and sign up share this screen — the API decides after the OTP
/// whether the number is new (→ register) or existing (→ home).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final _phoneController = TextEditingController(
    text: context.read<AuthController>().phoneNumber,
  )..addListener(_onPhoneChanged);
  int _lastPhoneLength = 0;
  final _referralController = TextEditingController();
  bool _showReferral = false;
  late Country _country =
      Country.tryParse(context.read<AuthController>().countryIso) ??
      Country.parse('IN');

  /// Digits a mobile number has in [_country], from its sample number.
  int get _phoneLength =>
      _country.example.isNotEmpty ? _country.example.length : 10;

  bool get _isValid => _phoneController.text.length == _phoneLength;

  @override
  void initState() {
    super.initState();
    // Read before any typing, so a restored number isn't seen as "just typed".
    _lastPhoneLength = _phoneController.text.length;
  }

  /// Typing the last digit sends the OTP right away — unless the referral
  /// field is open, where the user may still be entering a code.
  void _onPhoneChanged() {
    final length = _phoneController.text.length;
    final completed = length == _phoneLength && _lastPhoneLength < length;
    _lastPhoneLength = length;
    setState(() {});
    if (completed &&
        !_showReferral &&
        !context.read<AuthController>().isBusy) {
      _continue();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_isValid) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthController>();
    final sent = await auth.sendOtp(
      phone: _phoneController.text,
      dialCode: _country.phoneCode,
      iso: _country.countryCode,
      referral: _showReferral ? _referralController.text : '',
    );
    if (!mounted) return;

    if (sent) {
      context.push(AppRoutes.otp);
    } else {
      context.showSnackBar(auth.errorMessage!, isError: true);
    }
  }

  Future<void> _pickCountry() async {
    AppHaptics.selection();
    FocusScope.of(context).unfocus();
    final country = await showCountryPickerSheet(context, selected: _country);
    if (country == null || !mounted) return;

    setState(() => _country = country);
    // Trim to the new country's number length.
    final text = _phoneController.text;
    if (text.length > _phoneLength) {
      _phoneController.text = text.substring(0, _phoneLength);
    }
  }

  void _toggleReferral(bool show) {
    AppHaptics.selection();
    setState(() => _showReferral = show);
    if (!show) _referralController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.watch<AuthController>().isBusy;

    return AuthLayout(
      title: 'Welcome to Housy Point',
      subtitle: const Text('Log in or sign up with your mobile number.'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mobile number', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          PhoneInputField(
            controller: _phoneController,
            country: _country,
            maxLength: _phoneLength,
            onCountryTap: _pickCountry,
            onSubmitted: _continue,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Iconsax.shield_tick_copy,
                size: 15,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "We'll send a 5-digit OTP to verify your number.",
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(sizeFactor: animation, child: child),
            ),
            child: _showReferral
                ? _ReferralField(
                    key: const ValueKey('field'),
                    controller: _referralController,
                    onRemove: () => _toggleReferral(false),
                    onSubmitted: _continue,
                  )
                : _ReferralTile(
                    key: const ValueKey('tile'),
                    onTap: () => _toggleReferral(true),
                  ),
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Get OTP',
            icon: Iconsax.arrow_right_3_copy,
            isLoading: isBusy,
            onPressed: _isValid ? _continue : null,
          ),
          const SizedBox(height: AppSpacing.md),
          const _TermsText(),
        ],
      ),
    );
  }
}

/// Collapsed state: an inviting row instead of an empty optional field.
class _ReferralTile extends StatelessWidget {
  const _ReferralTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);

    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                ),
                child: const Icon(
                  Iconsax.gift_copy,
                  size: 18,
                  color: AppColors.goldDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Have a referral code?',
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Add it now to unlock rewards',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const Icon(
                Iconsax.add_copy,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferralField extends StatelessWidget {
  const _ReferralField({
    super.key,
    required this.controller,
    required this.onRemove,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final VoidCallback onRemove;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppTextField(
          controller: controller,
          label: 'Referral code',
          hintText: 'e.g. HP1234',
          icon: Iconsax.gift_copy,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmitted(),
        ),
        Positioned(
          top: -12,
          right: -8,
          child: TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Remove'),
          ),
        ),
      ],
    );
  }
}

class _TermsText extends StatelessWidget {
  const _TermsText();

  TextSpan _link(String text, String url) => TextSpan(
    text: text,
    style: const TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.border,
    ),
    recognizer: TapGestureRecognizer()
      ..onTap = () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text.rich(
        TextSpan(
          style: AppTextStyles.caption,
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            _link('Terms', ApiConfig.termsUrl),
            const TextSpan(text: ' & '),
            _link('Privacy Policy', ApiConfig.privacyPolicyUrl),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
