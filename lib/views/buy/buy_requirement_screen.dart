import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/saved_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/listing/listing_model.dart';
import '../../models/project/project_model.dart';
import '../../models/wizard/wizard_models.dart';
import '../../repositories/listing_repository.dart';
import '../../repositories/project_repository.dart';
import '../../repositories/wizard_repository.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/choice_chips.dart';
import '../../widgets/common/form_widgets.dart';
import '../../widgets/common/skeleton_box.dart';
import '../../widgets/common/success_sheet.dart';
import '../../widgets/common/wizard_scaffold.dart';
import '../home/widgets/new_launches_section.dart';
import '../listings/widgets/property_card.dart';

/// "Looking to buy?" — post a requirement; the team finds matches (API ref W9).
///
/// Steps: property type → purpose → resale / new launch (with matching
/// listings or projects to browse right away) → details → budget.
class BuyRequirementScreen extends StatefulWidget {
  const BuyRequirementScreen({super.key});

  @override
  State<BuyRequirementScreen> createState() => _BuyRequirementScreenState();
}

class _BuyRequirementScreenState extends State<BuyRequirementScreen> {
  static const _stepTitles = [
    'Property type',
    'Purpose',
    'Sale type',
    'Requirement',
    'Budget',
  ];
  static const _usageOptions = ['Investment', 'Self Use'];

  final _budget = TextEditingController();
  final _size = TextEditingController();
  final _notes = TextEditingController();

  int _step = 0;
  bool? _commercial;
  String? _usage;
  String? _source;
  String? _subtype;
  String? _bhk;
  String? _status;
  String? _timeline;
  bool _busy = false;

  /// Matches shown under the sale-type step; null while loading.
  List<ListingModel>? _resale;
  List<ProjectSummary>? _launches;

  /// Property type the resale list was loaded for.
  bool? _resaleFor;

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

  String _snake(String s) =>
      s.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');

  String? get _city => context.read<HomeController>().selectedCity;

  void _selectSource(String source) {
    setState(() => _source = source);
    if (source == 'Resale') {
      _loadResale();
    } else {
      _loadLaunches();
    }
  }

  Future<void> _loadResale() async {
    final commercial = _commercial ?? false;
    if (_resaleFor == commercial && _resale != null) return;
    setState(() {
      _resale = null;
      _resaleFor = commercial;
    });
    try {
      final page = await context.read<ListingRepository>().getListings(
        rental: false,
        city: _city,
        propertyType: commercial ? 'commercial' : 'residential',
        pageSize: 10,
      );
      if (mounted && _resaleFor == commercial) {
        setState(() => _resale = page.items);
      }
    } on ApiException {
      if (mounted) setState(() => _resale = const []);
    }
  }

  Future<void> _loadLaunches() async {
    if (_launches != null) return;
    try {
      final projects = await context.read<ProjectRepository>().getNewLaunches(
        city: _city,
      );
      if (mounted) setState(() => _launches = projects);
    } on ApiException {
      if (mounted) setState(() => _launches = const []);
    }
  }

  String? get _missingHint => switch (_step) {
    0 when _commercial == null => 'Choose residential or commercial',
    1 when _usage == null => 'Choose why you are buying',
    2 when _source == null => 'Choose resale or new launch',
    3 when _subtype == null => 'Choose a property type',
    4 when (int.tryParse(_budget.text) ?? 0) <= 0 => 'Add your budget',
    4 when _timeline == null => 'Choose when you plan to buy',
    _ => null,
  };

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _primary() async {
    final hint = _missingHint;
    if (hint != null) {
      context.showSnackBar(hint, isError: true);
      return;
    }
    FocusScope.of(context).unfocus();
    if (_step < _stepTitles.length - 1) {
      setState(() => _step++);
      // Property type may have changed since the resale list was loaded.
      if (_step == 2 && _source == 'Resale') _loadResale();
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    final commercial = _commercial ?? false;
    setState(() => _busy = true);
    final size = int.tryParse(_size.text);
    try {
      await context.read<WizardRepository>().submitBuyInterest({
        'property_type': commercial ? 'commercial' : 'residential',
        'property_source': _source == 'New Launch' ? 'new_launch' : 'resale',
        'budget': int.parse(_budget.text),
        'usage_type': _snake(_usage!),
        'buying_timeline': switch (_timeline) {
          'Immediately' => 'immediately',
          '1-3 Months' => '1-3_months',
          '3-6 Months' => '3-6_months',
          _ => '6+_months',
        },
        'description': _notes.text.trim(),
        if (commercial) ...{
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
        message:
            'Our property experts will reach out with homes that match what you need.',
      );
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) context.showSnackBar(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _step == _stepTitles.length - 1;
    return WizardScaffold(
      title: 'Buy a property',
      stepTitles: _stepTitles,
      step: _step,
      onBack: _back,
      onPrimary: _primary,
      loading: _busy,
      primaryLabel: isLast ? 'Share requirement' : 'Continue',
      primaryIcon: isLast ? Iconsax.send_2_copy : Iconsax.arrow_right_3_copy,
      child: switch (_step) {
        0 => _typeStep(),
        1 => _usageStep(),
        2 => _sourceStep(),
        3 => _detailsStep(),
        _ => _budgetStep(),
      },
    );
  }

  // ── 1 · Property type ──────────────────────────────────────

  Widget _typeStep() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const StepHeading(
          title: 'What are you looking to buy?',
          subtitle:
              'Tell us what you need — we’ll shortlist verified homes for you.',
        ),
        _OptionCard(
          icon: Iconsax.home_2_copy,
          title: 'Residential',
          subtitle: 'Apartments, floors, villas, plots',
          selected: _commercial == false,
          onTap: () => setState(() {
            if (_commercial != false) _subtype = null;
            _commercial = false;
          }),
        ),
        const SizedBox(height: 12),
        _OptionCard(
          icon: Iconsax.building_4_copy,
          title: 'Commercial',
          subtitle: 'Offices, shops, food courts, warehouses',
          selected: _commercial == true,
          onTap: () => setState(() {
            if (_commercial != true) _subtype = null;
            _commercial = true;
          }),
        ),
      ],
    );
  }

  // ── 2 · Purpose ────────────────────────────────────────────

  Widget _usageStep() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const StepHeading(
          title: 'Why are you buying?',
          subtitle: 'This helps us suggest the right projects and locations.',
        ),
        for (final u in _usageOptions) ...[
          _OptionCard(
            icon: u == 'Investment'
                ? Iconsax.chart_success_copy
                : Iconsax.user_tick_copy,
            title: u,
            subtitle: u == 'Investment'
                ? 'Appreciation and rental returns'
                : 'A home or space for yourself',
            selected: _usage == u,
            onTap: () => setState(() => _usage = u),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // ── 3 · Resale / new launch ────────────────────────────────

  Widget _sourceStep() {
    final resale = _source == 'Resale';
    final launch = _source == 'New Launch';
    const inset = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: [
        const Padding(
          padding: inset,
          child: StepHeading(
            title: 'Resale or new launch?',
            subtitle: 'Pick one to browse what’s available right now.',
          ),
        ),
        Padding(
          padding: inset,
          // Both cards take the taller one's height.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _OptionCard(
                    compact: true,
                    icon: Iconsax.key_copy,
                    title: 'Resale',
                    subtitle: 'Ready homes from owners',
                    selected: resale,
                    onTap: () => _selectSource('Resale'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OptionCard(
                    compact: true,
                    icon: Iconsax.flash_1_copy,
                    title: 'New Launch',
                    subtitle: 'Fresh builder projects',
                    selected: launch,
                    onTap: () => _selectSource('New Launch'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (resale || launch) ...[
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: inset,
            child: _BrowseHeader(
              title: resale ? 'Resale properties' : 'New launch projects',
              count: resale ? _resale?.length : _launches?.length,
            ),
          ),
          const SizedBox(height: 12),
          if (resale)
            _ResaleCarousel(listings: _resale)
          else
            _LaunchesCarousel(projects: _launches),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Text(
              'Didn’t find the one? Continue and share your requirement — we’ll find matches for you.',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ],
    );
  }

  // ── 4 · Requirement ────────────────────────────────────────

  Widget _detailsStep() {
    final commercial = _commercial ?? false;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        StepHeading(
          title: commercial ? 'What kind of space?' : 'What kind of home?',
          subtitle: 'Choose the type and size you have in mind.',
        ),
        _label('Property type', top: 0),
        ChoiceChips<String>(
          options: commercial
              ? WizardOptions.commercialSubtypes
              : WizardOptions.residentialSubtypes,
          selected: _subtype,
          labelOf: (s) => s,
          onSelected: (s) => setState(() => _subtype = s),
        ),
        if (!commercial) ...[
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
      ],
    );
  }

  // ── 5 · Budget ─────────────────────────────────────────────

  Widget _budgetStep() {
    final budget = int.tryParse(_budget.text) ?? 0;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const StepHeading(
          title: 'Budget & timeline',
          subtitle: 'Last step — we’ll match you with the best options.',
        ),
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
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
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
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: _notes,
          label: 'Anything else? (optional)',
          hintText: 'Preferred sectors, floor, amenities…',
          icon: Iconsax.message_text_copy,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _label(String text, {double top = AppSpacing.lg}) => Padding(
    padding: EdgeInsets.only(top: top, bottom: 10),
    child: Text(text, style: AppTextStyles.title.copyWith(fontSize: 15)),
  );
}

/// Full-width selectable option: icon tile, title + hint, radio mark.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// Stacked layout for two cards side by side.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconTile = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Icon(
        icon,
        size: 22,
        color: selected ? AppColors.onPrimary : AppColors.textSecondary,
      ),
    );
    final texts = [
      Text(title, style: AppTextStyles.title.copyWith(fontSize: 15)),
      const SizedBox(height: 2),
      Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption,
      ),
    ];
    final radio = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : AppColors.surface,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: 1.6,
        ),
      ),
      child: selected
          ? const Icon(
              Icons.check_rounded,
              size: 13,
              color: AppColors.onPrimary,
            )
          : null,
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [iconTile, const Spacer(), radio],
                  ),
                  const SizedBox(height: 12),
                  ...texts,
                ],
              )
            : Row(
                children: [
                  iconTile,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: texts,
                    ),
                  ),
                  const SizedBox(width: 10),
                  radio,
                ],
              ),
      ),
    );
  }
}

class _BrowseHeader extends StatelessWidget {
  const _BrowseHeader({required this.title, required this.count});

  final String title;

  /// Null while loading.
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.title)),
        if (count != null && count! > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$count available',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
      ],
    );
  }
}

class _ResaleCarousel extends StatelessWidget {
  const _ResaleCarousel({required this.listings});

  /// Null while loading.
  final List<ListingModel>? listings;

  static const double _height = 330;

  @override
  Widget build(BuildContext context) {
    final items = listings;
    if (items != null && items.isEmpty) {
      return const _EmptyNote(text: 'No resale listings in your city yet.');
    }
    final saved = context.watch<SavedController>();
    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: items?.length ?? 2,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (items == null) {
            return const SkeletonBox(
              width: 260,
              height: _height,
              radius: AppRadius.xl,
            );
          }
          final l = items[i];
          return SizedBox(
            width: 260,
            child: PropertyCard(
              listing: l,
              isSaved: saved.savedState(l),
              onSave: () async {
                final error = await saved.toggleSave(l);
                if (error != null && context.mounted) {
                  context.showSnackBar(error, isError: true);
                }
              },
              onTap: () => context.push(
                AppRoutes.listingPath(l.id, rental: l.isRental),
                extra: l,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LaunchesCarousel extends StatelessWidget {
  const _LaunchesCarousel({required this.projects});

  /// Null while loading.
  final List<ProjectSummary>? projects;

  static const double _height = 270;

  @override
  Widget build(BuildContext context) {
    final items = projects;
    if (items != null && items.isEmpty) {
      return const _EmptyNote(text: 'No new launches in your city yet.');
    }
    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: items?.length ?? 2,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => items == null
            ? const SkeletonBox(
                width: 230,
                height: _height,
                radius: AppRadius.xl,
              )
            : LaunchCard(project: items[i]),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.search_status_copy,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
