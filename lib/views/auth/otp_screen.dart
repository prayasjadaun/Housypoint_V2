import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import 'widgets/auth_layout.dart';
import 'widgets/otp_input.dart';

/// Step 2: the 5-digit OTP (API ref A2). On success the router redirect
/// takes the user to register (new number) or home (existing user).
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  static const int otpLength = 5;
  static const int resendSeconds = 30;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = OtpScreen.resendSeconds;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(() {
      if (_hasError) setState(() => _hasError = false);
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = OtpScreen.resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) timer.cancel();
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _verify() async {
    final otp = _otpController.text;
    if (otp.length != OtpScreen.otpLength) {
      setState(() => _hasError = true);
      return;
    }
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthController>();
    final ok = await auth.verifyOtp(otp);
    if (!mounted || ok) return;

    setState(() => _hasError = true);
    _otpController.clear();
    context.showSnackBar(auth.errorMessage!, isError: true);
  }

  Future<void> _resend() async {
    final auth = context.read<AuthController>();
    final ok = await auth.resendOtp();
    if (!mounted) return;
    if (ok) {
      _otpController.clear();
      _startTimer();
      context.showSnackBar('A new OTP has been sent');
    } else {
      context.showSnackBar(auth.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final number = auth.phoneNumber;
    final formatted = number.length == 10
        ? '+${auth.countryCode} ${number.substring(0, 5)} ${number.substring(5)}'
        : '+${auth.countryCode} $number';

    return AuthLayout(
      title: 'Verify your number',
      onBack: () => context.pop(),
      subtitle: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Enter the 5-digit code sent to '),
            TextSpan(
              text: formatted,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OtpInput(
            controller: _otpController,
            length: OtpScreen.otpLength,
            hasError: _hasError,
            onCompleted: (_) => _verify(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Iconsax.timer_1_copy, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              if (_secondsLeft > 0)
                Text(
                  'Resend code in 00:${_secondsLeft.toString().padLeft(2, '0')}',
                  style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                )
              else
                GestureDetector(
                  onTap: auth.isBusy ? null : _resend,
                  child: Text(
                    'Resend code',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(
                  children: [
                    const Icon(Iconsax.edit_2_copy, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Change number',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Verify & continue',
            icon: Iconsax.tick_circle_copy,
            isLoading: auth.isBusy,
            onPressed: _verify,
          ),
        ],
      ),
    );
  }
}
