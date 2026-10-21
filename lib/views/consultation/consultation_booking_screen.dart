import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:housypoint_v2/theme/app_radius.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/network/api_exception.dart';
import '../../models/consultation/consultation_models.dart';
import '../../repositories/consultation_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/choice_chips.dart';
import '../../widgets/common/page_scaffold.dart';
import '../../widgets/common/success_sheet.dart';

/// Book an expert call — legal, CA/CS, property advice or loans (API ref K1/K2).
class ConsultationBookingScreen extends StatefulWidget {
  const ConsultationBookingScreen({super.key, this.initialService});

  /// Pre-selected service value, e.g. `legal`.
  final String? initialService;

  @override
  State<ConsultationBookingScreen> createState() =>
      _ConsultationBookingScreenState();
}

class _ConsultationBookingScreenState extends State<ConsultationBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _user = context.read<AuthController>().user;
  late final _name = TextEditingController(text: _user?.fullName);
  late final _phone = TextEditingController(text: _user?.phone);
  late final _email = TextEditingController(text: _user?.email);
  final _other = TextEditingController();
  final _notes = TextEditingController();

  ConsultationOptions? _options;
  OptionItem? _service;
  OptionItem? _type;
  OptionItem? _slot;
  bool _busy = false;

  static const _serviceIcons = {
    'legal': Iconsax.judge_copy,
    'taxation': Iconsax.receipt_2_copy,
    'property_advice': Iconsax.house_2_copy,
    'loan_assistance': Iconsax.money_recive_copy,
    'other': Iconsax.more_circle_copy,
  };

  @override
  void initState() {
    super.initState();
    context.read<ConsultationRepository>().getOptions().then((options) {
      if (!mounted) return;
      setState(() {
        _options = options;
        _service = options.serviceTypes.firstWhere(
          (s) => s.value == widget.initialService,
          orElse: () => options.serviceTypes.first,
        );
        _type = options.consultationTypes.first;
      });
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _other, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_slot == null) {
      context.showSnackBar('Pick a time slot that suits you', isError: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await context.read<ConsultationRepository>().book(
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        serviceType: _service!.value,
        consultationType: _type!.value,
        timeSlot: _slot!.value,
        otherDescription: _type!.value == 'other' ? _other.text.trim() : null,
        notes: _notes.text.trim(),
      );
      if (!mounted) return;
      await showSuccessSheet(
        context,
        title: 'Consultation booked',
        message:
            'Our ${_service!.label.toLowerCase()} expert will call you between ${_slot!.label}.',
      );
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) context.showSnackBar(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: AppSpacing.lg),
    child: Text(text, style: AppTextStyles.title.copyWith(fontSize: 15)),
  );

  @override
  Widget build(BuildContext context) {
    final options = _options;
    final top = PageScaffold.topInset(context);

    return PageScaffold(
      title: 'Expert consultation',
      backgroundColor: AppColors.surface,
      bottomBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          8,
          AppSpacing.md,
          MediaQuery.paddingOf(context).bottom + 12,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: AppButton(
          label: 'Book consultation',
          icon: Iconsax.calendar_tick_copy,
          isLoading: _busy,
          onPressed: options == null ? null : _submit,
        ),
      ),
      body: options == null
          ? const Center(child: AppSpinner())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  top + AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  Text(
                    'Talk to a verified expert. Free first call — pick a slot and we’ll ring you.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  _label('What do you need help with?'),
                  ChoiceChips<OptionItem>(
                    options: options.serviceTypes,
                    selected: _service,
                    labelOf: (o) => o.label,
                    iconOf: (o) =>
                        _serviceIcons[o.value] ?? Iconsax.more_circle_copy,
                    onSelected: (o) => setState(() => _service = o),
                  ),
                  _label('Which property is it about?'),
                  ChoiceChips<OptionItem>(
                    options: options.consultationTypes,
                    selected: _type,
                    labelOf: (o) => o.label,
                    onSelected: (o) => setState(() => _type = o),
                  ),
                  if (_type?.value == 'other') ...[
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _other,
                      label: 'Please specify',
                      hintText: 'Tell us briefly',
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Required' : null,
                    ),
                  ],
                  _label('Preferred time slot'),
                  ChoiceChips<OptionItem>(
                    options: options.timeSlots,
                    selected: _slot,
                    labelOf: (o) => o.label,
                    iconOf: (_) => Iconsax.clock_copy,
                    onSelected: (o) => setState(() => _slot = o),
                  ),
                  _label('Your details'),
                  AppTextField(
                    controller: _name,
                    label: 'Full name',
                    hintText: 'Your name',
                    icon: Iconsax.user_copy,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _phone,
                    label: 'Phone number',
                    hintText: '919876543210',
                    icon: Iconsax.call_copy,
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v ?? '').trim().length < 10
                        ? 'Enter a valid number'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _email,
                    label: 'Email',
                    hintText: 'you@example.com',
                    icon: Iconsax.sms_copy,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v ?? '').contains('@') ? null : 'Enter a valid email',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _notes,
                    label: 'Anything we should know? (optional)',
                    hintText: 'Your question or property details',
                    icon: Iconsax.message_text_copy,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
    );
  }
}
