import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/page_scaffold.dart';

/// Edit name, email and address (API ref A4).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _user = context.read<AuthController>().user;
  late final _first = TextEditingController(text: _user?.firstName);
  late final _last = TextEditingController(text: _user?.lastName);
  late final _email = TextEditingController(text: _user?.email);
  late final _address = TextEditingController(text: _user?.address);

  static final _emailRegex = RegExp(r'^[\w.%+-]+@[\w.-]+\.[a-zA-Z]{2,}$');

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthController>();
    final ok = await auth.updateProfile(
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      context.showSnackBar('Profile updated');
      Navigator.pop(context);
    } else {
      context.showSnackBar(auth.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthController>().isBusy;
    final top = PageScaffold.topInset(context);

    return PageScaffold(
      title: 'Edit profile',
      backgroundColor: AppColors.surface,
      bottomBar: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.md, MediaQuery.paddingOf(context).bottom + 12),
        child: AppButton(label: 'Save changes', isLoading: busy, onPressed: _save),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, top + AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _first,
                    label: 'First name',
                    hintText: 'First name',
                    icon: Iconsax.user_copy,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    controller: _last,
                    label: 'Last name',
                    hintText: 'Last name',
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _email,
              label: 'Email',
              hintText: 'you@example.com',
              icon: Iconsax.sms_copy,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => _emailRegex.hasMatch((v ?? '').trim()) ? null : 'Enter a valid email',
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _address,
              label: 'Address (optional)',
              hintText: 'City, state',
              icon: Iconsax.location_copy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Mobile number', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.call_copy, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('+${_user?.phone ?? ''}', style: AppTextStyles.body.copyWith(fontSize: 15)),
                  ),
                  Icon(Iconsax.lock_copy, size: 16, color: AppColors.textTertiary),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('Your mobile number is your login and can’t be changed.', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
