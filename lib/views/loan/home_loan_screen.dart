import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/loan/bank_model.dart';
import '../../repositories/loan_repository.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/page_scaffold.dart';
import '../../widgets/common/section_header.dart';

/// Home loan: EMI calculator, partner banks and a "talk to an expert" CTA.
class HomeLoanScreen extends StatefulWidget {
  const HomeLoanScreen({super.key});

  @override
  State<HomeLoanScreen> createState() => _HomeLoanScreenState();
}

class _HomeLoanScreenState extends State<HomeLoanScreen> {
  double _amount = 5000000; // ₹50 L
  double _rate = 8.5;
  double _years = 20;
  List<BankModel>? _banks;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    List<BankModel> banks;
    try {
      banks = await context.read<LoanRepository>().getBanks();
    } on ApiException {
      banks = const []; // the section hides itself
    }
    if (mounted) setState(() => _banks = banks);
  }

  double get _emi {
    final r = _rate / 12 / 100;
    final n = _years * 12;
    final f = math.pow(1 + r, n);
    return _amount * r * f / (f - 1);
  }

  @override
  Widget build(BuildContext context) {
    final top = PageScaffold.topInset(context);
    final emi = _emi;
    final total = emi * _years * 12;
    final interest = total - _amount;

    return PageScaffold(
      title: 'Home loan',
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.md, top + AppSpacing.md, AppSpacing.md, AppSpacing.xl),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl + 4),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EMI calculator', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly EMI', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                      Text(
                        '₹${Formatters.grouped(emi.round())}',
                        style: AppTextStyles.display.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Row(
                          children: [
                            Expanded(
                              flex: (_amount / total * 1000).round(),
                              child: Container(height: 6, color: Colors.white),
                            ),
                            Expanded(
                              flex: (interest / total * 1000).round(),
                              child: Container(height: 6, color: AppColors.gold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Legend(color: Colors.white, label: 'Principal', value: Formatters.price(_amount)),
                          const SizedBox(width: 20),
                          _Legend(color: AppColors.gold, label: 'Interest', value: Formatters.price(interest)),
                          const Spacer(),
                          _Legend(color: Colors.transparent, label: 'Total', value: Formatters.price(total)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SliderRow(
                  label: 'Loan amount',
                  value: Formatters.price(_amount),
                  slider: Slider(
                    value: _amount,
                    min: 500000,
                    max: 50000000,
                    divisions: 99,
                    onChanged: (v) => setState(() => _amount = v),
                  ),
                ),
                _SliderRow(
                  label: 'Interest rate',
                  value: '${_rate.toStringAsFixed(2)}%',
                  slider: Slider(
                    value: _rate,
                    min: 6,
                    max: 15,
                    divisions: 36,
                    onChanged: (v) => setState(() => _rate = v),
                  ),
                ),
                _SliderRow(
                  label: 'Tenure',
                  value: '${_years.round()} years',
                  slider: Slider(
                    value: _years,
                    min: 1,
                    max: 30,
                    divisions: 29,
                    onChanged: (v) => setState(() => _years = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ExpertCard(onTap: () => context.push(AppRoutes.consultationFor('loan_assistance'))),
          if (_banks == null || _banks!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Partner banks', padding: EdgeInsets.zero),
            const SizedBox(height: 12),
            if (_banks == null)
              const Center(child: AppSpinner())
            else
              for (final b in _banks!) _BankTile(bank: b),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (color != Colors.transparent) ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
            ],
            Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 11)),
          ],
        ),
        Text(value, style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({required this.label, required this.value, required this.slider});

  final String label;
  final String value;
  final Widget slider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.label)),
              Text(value, style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              showValueIndicator: ShowValueIndicator.never,
              tickMarkShape: SliderTickMarkShape.noTickMark,
            ),
            child: slider,
          ),
        ],
      ),
    );
  }
}

class _ExpertCard extends StatelessWidget {
  const _ExpertCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gold.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                child: const Icon(Iconsax.money_recive_copy, color: AppColors.goldDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Get the best loan offer', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    Text('A loan expert compares banks for you — free.', style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(Iconsax.arrow_right_3_copy, size: 18, color: AppColors.goldDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankTile extends StatelessWidget {
  const _BankTile({required this.bank});

  final BankModel bank;

  void _open(BuildContext context) {
    final sections = [
      ('About', bank.description),
      ('Eligibility', bank.eligibility),
      ('Documents required', bank.documents),
      ('Features & benefits', bank.features),
      ('How to apply', bank.process),
    ].where((s) => s.$2.isNotEmpty);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scroll) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(bank.name, style: AppTextStyles.heading.copyWith(fontSize: 20)),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, value) in [
                    ('Interest', bank.interestRate),
                    ('Processing fee', bank.processingFee),
                    ('Prepayment', bank.prepaymentCharges),
                    ('Amount', bank.amountRange),
                    ('Tenure', bank.tenure),
                  ])
                    if (value.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                            Text(value, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                ],
              ),
              for (final (title, text) in sections) ...[
                const SizedBox(height: AppSpacing.md),
                Text(title, style: AppTextStyles.title.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Text(text, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => _open(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: AppNetworkImage(url: bank.logo, fit: BoxFit.contain, fallbackIcon: Iconsax.bank_copy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bank.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        [Formatters.humanize(bank.bankType), if (bank.tenure.isNotEmpty) bank.tenure]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                if (bank.interestRate.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(bank.interestRate, style: AppTextStyles.title.copyWith(fontSize: 16, color: AppColors.primaryDark)),
                      Text('interest', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
