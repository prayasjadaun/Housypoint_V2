import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/wizard/wizard_models.dart';
import '../../repositories/wizard_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/choice_chips.dart';
import '../../widgets/common/page_scaffold.dart';
import '../../widgets/common/segmented_toggle.dart';
import '../../widgets/common/success_sheet.dart';

/// "Looking to buy?" — post a requirement; the team finds matches (API ref W9).
class BuyRequirementScreen extends StatefulWidget {
  const BuyRequirementScreen({super.key});

  @override
  State<BuyRequirementScreen> createState() => _BuyRequirementScreenState();
}

class _BuyRequirementScreenState extends State<BuyRequirementScreen> {
  final _budget = TextEditingController();
  final _size = TextEditingController();
  final _notes = TextEditingController();

  String _source = WizardOptions.buySources.first;
  bool _commercial = false;
  String? _subtype;
  String? _bhk;
  String? _status;
  String? _usage = WizardOptions.usage.first;
  String? _timeline;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _budget.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_budget, _size, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String _snake(String s) => s.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');

  Future<void> _submit() async {
    final budget = int.tryParse(_budget.text) ?? 0;
    if (_subtype == null || budget <= 0 || _timeline == null) {
      context.showSnackBar('Add property type, budget and when you plan to buy', isError: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final size = int.tryParse(_size.text);
    try {
      await context.read<WizardRepository>().submitBuyInterest({
        'property_type': _commercial ? 'commercial' : 'residential',
        'property_source': _source == 'New Launch' ? 'new_launch' : 'resale',
        'budget': budget,
        'usage_type': _snake(_usage ?? 'Self Use'),
        'buying_timeline': switch (_timeline) {
          'Immediately' => 'immediately',
          '1-3 Months' => '1-3_months',
          '3-6 Months' => '3-6_months',
          _ => '6+_months',
        },
        'description': _notes.text.trim(),
        if (_commercial) ...{
          'commercial_subtype': _snake(WizardOptions.apiSubtype(_subtype!)),
          'commercial_status': ?(_status == null ? null : _snake(_status!)),
        } else ...{
          'residential_subtype': _snake(_subtype!),
          'bhk': ?_bhk,
        },
        if (size != null) ...{'size': size, 'size_unit': 'sqft'},
      });
      if (!mounted) return;
      await showSuccessSheet(
        context,
        title: 'Requirement shared',
        message: 'Our property experts will reach out with homes that match what you need.',
      );
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) context.showSnackBar(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 10),
    child: Text(text, style: AppTextStyles.title.copyWith(fontSize: 15)),
  );

  @override
  Widget build(BuildContext context) {
    final top = PageScaffold.topInset(context);
    final budget = int.tryParse(_budget.text) ?? 0;
    final subtypes = _commercial ? WizardOptions.commercialSubtypes : WizardOptions.residentialSubtypes;

    return PageScaffold(
      title: 'Buy a property',
      backgroundColor: AppColors.surface,
      bottomBar: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.md, MediaQuery.paddingOf(context).bottom + 12),
        child: AppButton(label: 'Share requirement', icon: Iconsax.send_2_copy, isLoading: _busy, onPressed: _submit),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, top + AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
        children: [
          Text(
            'Tell us what you’re looking for — we’ll shortlist verified homes for you.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          _label('Looking for'),
          SegmentedToggle(
            labels: WizardOptions.buySources,
            icons: const [Iconsax.key_copy, Iconsax.flash_1_copy],
            selectedIndex: WizardOptions.buySources.indexOf(_source),
            onChanged: (i) => setState(() => _source = WizardOptions.buySources[i]),
          ),
          const SizedBox(height: 10),
          SegmentedToggle(
            labels: const ['Residential', 'Commercial'],
            icons: const [Iconsax.home_2_copy, Iconsax.building_4_copy],
            selectedIndex: _commercial ? 1 : 0,
            onChanged: (i) => setState(() {
              _commercial = i == 1;
              _subtype = null;
            }),
          ),
          _label('Property type'),
          ChoiceChips<String>(
            options: subtypes,
            selected: _subtype,
            labelOf: (s) => s,
            onSelected: (s) => setState(() => _subtype = s),
          ),
          if (!_commercial) ...[
            _label('BHK'),
            ChoiceChips<String>(
              options: WizardOptions.bhkOptions,
              selected: _bhk,
              labelOf: (s) => '$s BHK',
              onSelected: (s) => setState(() => _bhk = s),
            ),
          ] else ...[
            _label('Status'),
            ChoiceChips<String>(
              options: WizardOptions.commercialStatus,
              selected: _status,
              labelOf: (s) => s,
              onSelected: (s) => setState(() => _status = s),
            ),
          ],
          _label('Budget & size'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _budget,
                  label: 'Budget (₹)',
                  hintText: '15000000',
                  icon: Iconsax.wallet_money_copy,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _size,
                  label: 'Size (sqft)',
                  hintText: '1500',
                  icon: Iconsax.maximize_4_copy,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          if (budget > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Up to ${Formatters.price(budget)}',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          _label('When do you plan to buy?'),
          ChoiceChips<String>(
            options: WizardOptions.timelines,
            selected: _timeline,
            labelOf: (s) => s,
            iconOf: (_) => Iconsax.calendar_copy,
            onSelected: (s) => setState(() => _timeline = s),
          ),
          _label('Purpose'),
          ChoiceChips<String>(
            options: WizardOptions.usage,
            selected: _usage,
            labelOf: (s) => s,
            onSelected: (s) => setState(() => _usage = s),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _notes,
            label: 'Anything else? (optional)',
            hintText: 'Preferred sectors, floor, amenities…',
            icon: Iconsax.message_text_copy,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}
