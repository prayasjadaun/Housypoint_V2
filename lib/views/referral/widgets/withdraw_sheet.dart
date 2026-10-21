import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../controllers/referral_controller.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_text_field.dart';

/// Bank details form for a withdrawal (API ref R6).
Future<void> showWithdrawSheet(BuildContext context, {required num available}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WithdrawSheet(available: available),
  );
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({required this.available});

  final num available;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _name = TextEditingController();
  final _account = TextEditingController();
  final _ifsc = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_amount, _name, _account, _ifsc]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final error = await context.read<ReferralController>().withdraw(
      amount: num.parse(_amount.text),
      accountName: _name.text.trim(),
      accountNumber: _account.text.trim(),
      ifsc: _ifsc.text.trim().toUpperCase(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      context.showSnackBar(error, isError: true);
      return;
    }
    Navigator.pop(context);
    context.showSnackBar('Withdrawal requested — it usually reaches your bank in 3–5 days.');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          MediaQuery.paddingOf(context).bottom + AppSpacing.md,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Withdraw earnings', style: AppTextStyles.title),
                Text(
                  'Available: ${Formatters.price(widget.available).replaceAll('Price on request', '₹0')}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _amount,
                  label: 'Amount (₹)',
                  hintText: '1000',
                  icon: Iconsax.money_send_copy,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  validator: (v) {
                    final value = num.tryParse(v ?? '');
                    if (value == null || value <= 0) return 'Enter an amount';
                    if (value > widget.available) return 'More than your available balance';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _name,
                  label: 'Account holder name',
                  hintText: 'As per bank records',
                  icon: Iconsax.user_copy,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _account,
                  label: 'Account number',
                  hintText: '0000 0000 0000',
                  icon: Iconsax.card_copy,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => (v ?? '').length < 6 ? 'Enter a valid account number' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _ifsc,
                  label: 'IFSC code',
                  hintText: 'HDFC0001234',
                  icon: Iconsax.bank_copy,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  validator: (v) => RegExp(r'^[A-Za-z]{4}0[A-Za-z0-9]{6}$').hasMatch((v ?? '').trim())
                      ? null
                      : 'Enter a valid IFSC (e.g. HDFC0001234)',
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(label: 'Request withdrawal', isLoading: _busy, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
