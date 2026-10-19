import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import 'widgets/auth_layout.dart';

/// Step 3, sign up only: a new number has to add name + email
/// (API ref A4) before reaching home.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  static final _emailRegex = RegExp(r'^[\w.%+-]+@[\w.-]+\.[a-zA-Z]{2,}$');

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _required(String? value, String field) =>
      (value ?? '').trim().isEmpty ? '$field is required' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthController>();
    final ok = await auth.completeProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
    );
    if (!mounted) return;
    if (!ok) context.showSnackBar(auth.errorMessage!, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return AuthLayout(
      title: 'Create your account',
      subtitle: const Text('Just a few details to set up your profile.'),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _firstNameController,
                    label: 'First name',
                    hintText: 'Rahul',
                    icon: Iconsax.user_copy,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => _required(v, 'First name'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    controller: _lastNameController,
                    label: 'Last name',
                    hintText: 'Sharma',
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => _required(v, 'Last name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _emailController,
              label: 'Email',
              hintText: 'you@example.com',
              icon: Iconsax.sms_copy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: (v) => _emailRegex.hasMatch((v ?? '').trim())
                  ? null
                  : 'Enter a valid email address',
              onSubmitted: (_) => _submit(),
            ),
            const Spacer(),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Create account',
              icon: Iconsax.arrow_right_3_copy,
              isLoading: auth.isBusy,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: auth.isBusy ? null : auth.logout,
              child: const Text('Use a different number'),
            ),
          ],
        ),
      ),
    );
  }
}
