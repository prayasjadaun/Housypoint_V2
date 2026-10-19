import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../controllers/home_controller.dart';
import '../../../controllers/post_property_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/project/project_model.dart';
import '../../../models/wizard/wizard_models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_network_image.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../widgets/common/choice_chips.dart';
import '../../../widgets/common/form_widgets.dart';
import '../../../widgets/common/segmented_toggle.dart';
import '../../../widgets/common/selection_sheet.dart';
import '../../../widgets/pickers/location_pickers.dart';

const _subtypeIcons = {
  'Apartment': Iconsax.building_copy,
  'Floor': Iconsax.layer_copy,
  'Villa': Iconsax.house_copy,
  'Penthouse': Iconsax.crown_1_copy,
  'Plot': Iconsax.map_1_copy,
  'Office Space': Iconsax.building_4_copy,
  'Shop': Iconsax.shop_copy,
  'Food Court': Iconsax.coffee_copy,
  'Studio Apartment': Iconsax.video_square_copy,
  'Hotel': Iconsax.building_3_copy,
  'Cinema Hall': Iconsax.video_play_copy,
  'Restaurant': Iconsax.reserve_copy,
  'Warehouse': Iconsax.box_copy,
};

TextInputFormatter get _digits => FilteringTextInputFormatter.digitsOnly;

// ── 1 · Type ────────────────────────────────────────────────

class TypeStep extends StatelessWidget {
  const TypeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PostPropertyController>();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        StepHeading(
          title: c.isRent ? 'What are you renting out?' : 'What are you selling?',
          subtitle: 'Zero brokerage — we connect you with verified people.',
        ),
        SegmentedToggle(
          labels: const ['Residential', 'Commercial'],
          icons: const [Iconsax.home_2_copy, Iconsax.building_4_copy],
          selectedIndex: c.isCommercial ? 1 : 0,
          onChanged: (i) => c.setCommercial(i == 1),
        ),
        const SizedBox(height: AppSpacing.lg),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
          children: [
            for (final s in c.subtypes)
              _TypeTile(
                label: s,
                icon: _subtypeIcons[s] ?? Iconsax.building_copy,
                selected: c.subtype == s,
                onTap: () => c.update(() => c.subtype = s),
              ),
          ],
        ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.6 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 2 · Project ─────────────────────────────────────────────

class ProjectStep extends StatefulWidget {
  const ProjectStep({super.key});

  @override
  State<ProjectStep> createState() => _ProjectStepState();
}

class _ProjectStepState extends State<ProjectStep> {
  late final c = context.read<PostPropertyController>();
  late final _builderOther = TextEditingController(text: c.builderOther);
  late final _projectOther = TextEditingController(text: c.projectOther);
  late final _location = TextEditingController(text: c.location);

  @override
  void dispose() {
    for (final t in [_builderOther, _projectOther, _location]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBuilder() async {
    final result = await showBuilderPicker(
      context,
      builders: c.builders ?? const [],
      selected: c.builder,
      cityLabel: 'all cities',
    );
    if (result.picked && result.value != null) c.setBuilder(result.value!);
  }

  Future<void> _pickProject() async {
    final picked = await showSelectionSheet<ProjectSummary>(
      context,
      title: 'Select project',
      subtitle: 'Projects by ${c.builder?.name}',
      searchHint: 'Search project',
      items: c.projects ?? const [],
      emptyTitle: 'No project found',
      labelOf: (p) => p.name,
      subtitleOf: (p) => [p.projectType, p.city].where((s) => s.isNotEmpty).join(' · '),
      isSelected: (p) => p.id == c.project?.id,
      leadingOf: (p, selected) => SelectionLeading(
        selected: selected,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AppNetworkImage(url: p.logo, fit: BoxFit.contain, fallbackIcon: Iconsax.buildings_2_copy),
        ),
      ),
    );
    if (picked != null) c.setProject(picked);
  }

  Future<void> _pickCity() async {
    final home = context.read<HomeController>();
    await home.ensureCities();
    if (!mounted) return;
    final result = await showCityPicker(context, cities: home.cities, selected: c.city.isEmpty ? null : c.city);
    if (result.picked && result.value != null) c.update(() => c.city = result.value!);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PostPropertyController>();
    final custom = c.otherBuilder || c.otherProject;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const StepHeading(title: 'Which project is it in?', subtitle: 'We’ll pull in the project’s photos and layouts.'),
        if (!c.otherBuilder)
          PickerField(
            label: 'Builder',
            value: c.builder?.name,
            placeholder: 'Select builder',
            icon: Iconsax.buildings_2_copy,
            loading: c.builders == null,
            onTap: _pickBuilder,
          )
        else
          AppTextField(
            controller: _builderOther,
            label: 'Builder name',
            hintText: 'Type the builder’s name',
            icon: Iconsax.buildings_2_copy,
            textCapitalization: TextCapitalization.words,
            onChanged: (v) => c.update(() => c.builderOther = v),
          ),
        CheckRow(label: 'My builder isn’t listed', value: c.otherBuilder, onChanged: c.setOtherBuilder),
        const SizedBox(height: AppSpacing.sm),
        if (!custom)
          PickerField(
            label: 'Project',
            value: c.project?.name,
            placeholder: c.builder == null ? 'Select a builder first' : 'Select project',
            icon: Iconsax.building_copy,
            loading: c.builder != null && c.projects == null,
            onTap: c.builder == null ? null : _pickProject,
          )
        else
          AppTextField(
            controller: _projectOther,
            label: 'Project / society name',
            hintText: 'Type the project name',
            icon: Iconsax.building_copy,
            textCapitalization: TextCapitalization.words,
            onChanged: (v) => c.update(() => c.projectOther = v),
          ),
        if (!c.otherBuilder)
          CheckRow(label: 'My project isn’t listed', value: c.otherProject, onChanged: c.setOtherProject),
        if (custom) ...[
          const SizedBox(height: AppSpacing.sm),
          PickerField(
            label: 'City',
            value: c.city,
            placeholder: 'Select city',
            icon: Iconsax.location_copy,
            onTap: _pickCity,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _location,
            label: 'Locality / sector (optional)',
            hintText: 'e.g. Sector 61',
            icon: Iconsax.map_copy,
            textInputAction: TextInputAction.done,
            onChanged: (v) => c.update(() => c.location = v),
          ),
        ],
      ],
    );
  }
}

// ── 3 · Details ─────────────────────────────────────────────

class DetailsStep extends StatefulWidget {
  const DetailsStep({super.key});

  @override
  State<DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends State<DetailsStep> {
  late final c = context.read<PostPropertyController>();
  late final _bhk = TextEditingController(text: c.bhkOther);
  late final _size = TextEditingController(text: c.sizeOther);
  late final _unit = TextEditingController(text: c.unitNumber);
  late final _tower = TextEditingController(text: c.tower);
  late final _floor = TextEditingController(text: c.floor);
  late final _area = TextEditingController(text: c.plotArea);
  late final _dims = TextEditingController(text: c.plotDimensions);

  @override
  void dispose() {
    for (final t in [_bhk, _size, _unit, _tower, _floor, _area, _dims]) {
      t.dispose();
    }
    super.dispose();
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 10),
    child: Text(text, style: AppTextStyles.title.copyWith(fontSize: 15)),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PostPropertyController>();
    final configs = c.configurations ?? const <UnitConfiguration>[];

    if (c.isPlot) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const StepHeading(title: 'Plot details', subtitle: 'Size, shape and which way it faces.'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _area,
                  label: 'Area (sq yd)',
                  hintText: '200',
                  icon: Iconsax.maximize_4_copy,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_digits],
                  onChanged: (v) => c.update(() => c.plotArea = v),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _dims,
                  label: 'Dimensions',
                  hintText: '30 x 60',
                  textInputAction: TextInputAction.done,
                  onChanged: (v) => c.update(() => c.plotDimensions = v),
                ),
              ),
            ],
          ),
          _label('Facing'),
          ChoiceChips<String>(
            options: WizardOptions.plotFacings,
            selected: c.facing,
            labelOf: (s) => s,
            onSelected: (v) => c.update(() => c.facing = v),
          ),
          _label('Construction'),
          ChoiceChips<String>(
            options: WizardOptions.plotConstruction,
            selected: c.plotConstruction,
            labelOf: (s) => s,
            onSelected: (v) => c.update(() => c.plotConstruction = v),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const StepHeading(title: 'Unit details', subtitle: 'Help buyers know exactly what they’re getting.'),
        if (configs.isNotEmpty) ...[
          Text('Configuration', style: AppTextStyles.title.copyWith(fontSize: 15)),
          const SizedBox(height: 10),
          ChoiceChips<UnitConfiguration>(
            options: configs,
            selected: c.configuration,
            labelOf: (u) => u.label,
            onSelected: (u) => c.update(() => c.configuration = u),
          ),
          const SizedBox(height: 6),
          Text('Not listed? Leave unselected and enter it below.', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.md),
        ],
        if (c.configuration == null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!c.isCommercial) ...[
                Expanded(
                  child: AppTextField(
                    controller: _bhk,
                    label: 'BHK',
                    hintText: '3',
                    icon: Iconsax.home_2_copy,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => c.update(() => c.bhkOther = v),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: AppTextField(
                  controller: _size,
                  label: 'Size (sqft)',
                  hintText: '1650',
                  icon: Iconsax.maximize_4_copy,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_digits],
                  onChanged: (v) => c.update(() => c.sizeOther = v),
                ),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: _unit,
                label: 'Unit no.',
                hintText: 'A-1203',
                textCapitalization: TextCapitalization.characters,
                onChanged: (v) => c.update(() => c.unitNumber = v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextField(
                controller: _tower,
                label: 'Tower',
                hintText: 'A',
                textCapitalization: TextCapitalization.characters,
                onChanged: (v) => c.update(() => c.tower = v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextField(
                controller: _floor,
                label: 'Floor',
                hintText: '12',
                keyboardType: TextInputType.number,
                inputFormatters: [_digits],
                textInputAction: TextInputAction.done,
                onChanged: (v) => c.update(() => c.floor = v),
              ),
            ),
          ],
        ),
        _label('Facing'),
        ChoiceChips<String>(
          options: WizardOptions.facings,
          selected: c.facing,
          labelOf: (s) => s,
          onSelected: (v) => c.update(() => c.facing = v),
        ),
        _label('Furnishing'),
        ChoiceChips<String>(
          options: c.furnishingOptions,
          selected: c.furnishing,
          labelOf: (s) => s,
          iconOf: (_) => Iconsax.lamp_on_copy,
          onSelected: (v) => c.update(() => c.furnishing = v),
        ),
      ],
    );
  }
}

// ── 4 · Photos ──────────────────────────────────────────────

class PhotosStep extends StatelessWidget {
  const PhotosStep({super.key});

  Future<void> _addPhotos(PostPropertyController c) async {
    final files = await FilePicker.pickFiles(type: FileType.image, compressionQuality: 70);
    c.addCustomImages(files.map((f) => f.path).whereType<String>());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PostPropertyController>();
    final projectImages = c.projectImages ?? const <ProjectImage>[];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const StepHeading(title: 'Add photos', subtitle: 'Listings with photos get up to 5× more enquiries.'),
        Material(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: () => _addPhotos(c),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.gallery_add_copy, color: AppColors.primary, size: 28),
                  const SizedBox(height: 6),
                  Text('Upload your photos', style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  Text('JPG or PNG', style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
        ),
        if (c.customImages.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _Grid(
            children: [
              for (final path in c.customImages)
                _Thumb(
                  image: Image.file(File(path), fit: BoxFit.cover),
                  selected: true,
                  removable: true,
                  onTap: () => c.removeCustomImage(path),
                ),
            ],
          ),
        ],
        if (projectImages.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Project photos', style: AppTextStyles.title.copyWith(fontSize: 15)),
          Text('Tap to include the builder’s photos.', style: AppTextStyles.caption),
          const SizedBox(height: 10),
          _Grid(
            children: [
              for (final img in projectImages)
                _Thumb(
                  image: AppNetworkImage(url: img.url),
                  selected: c.selectedProjectImages.contains(img.id),
                  onTap: () => c.toggleProjectImage(img.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: children,
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.image, required this.selected, required this.onTap, this.removable = false});

  final Widget image;
  final bool selected;
  final bool removable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: image),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 2.5),
              color: selected ? Colors.transparent : Colors.white.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: removable ? Colors.black54 : (selected ? AppColors.primary : Colors.white),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(
                removable ? Icons.close_rounded : Icons.check_rounded,
                size: 14,
                color: removable || selected ? Colors.white : Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 5 · Price ───────────────────────────────────────────────

class PriceStep extends StatefulWidget {
  const PriceStep({super.key});

  @override
  State<PriceStep> createState() => _PriceStepState();
}

class _PriceStepState extends State<PriceStep> {
  late final c = context.read<PostPropertyController>();
  late final _price = TextEditingController(text: c.price);
  late final _deposit = TextEditingController(text: c.deposit);
  late final _maintenance = TextEditingController(text: c.maintenance);
  late final _lockIn = TextEditingController(text: c.lockIn);
  late final _lease = TextEditingController(text: c.leaseDuration);

  @override
  void dispose() {
    for (final t in [_price, _deposit, _maintenance, _lockIn, _lease]) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PostPropertyController>();
    final amount = num.tryParse(c.price) ?? 0;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        StepHeading(
          title: c.isRent ? 'Set the rent' : 'Set your price',
          subtitle: c.isRent ? 'Monthly rent and one-time deposit.' : 'You can change it any time later.',
        ),
        AppTextField(
          controller: _price,
          label: c.isRent ? 'Monthly rent (₹)' : 'Asking price (₹)',
          hintText: c.isRent ? '45000' : '12500000',
          icon: Iconsax.wallet_money_copy,
          keyboardType: TextInputType.number,
          inputFormatters: [_digits],
          onChanged: (v) => c.update(() => c.price = v),
        ),
        if (amount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              c.isRent ? '${Formatters.price(amount)} per month' : Formatters.price(amount),
              style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        if (c.isRent) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _deposit,
                  label: 'Security deposit',
                  hintText: '90000',
                  keyboardType: TextInputType.number,
                  inputFormatters: [_digits],
                  onChanged: (v) => c.update(() => c.deposit = v),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _maintenance,
                  label: 'Maintenance /mo',
                  hintText: '3000',
                  keyboardType: TextInputType.number,
                  inputFormatters: [_digits],
                  textInputAction: TextInputAction.done,
                  onChanged: (v) => c.update(() => c.maintenance = v),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _SwitchRow(
          title: 'Price is negotiable',
          value: c.negotiable,
          onChanged: (v) => c.update(() => c.negotiable = v),
        ),
        if (c.isRent) ...[
          _SwitchRow(
            title: 'Open to corporate leasing',
            value: c.corporateLeasing,
            onChanged: (v) => c.update(() => c.corporateLeasing = v),
          ),
          _SwitchRow(
            title: 'Currently rented out',
            value: c.currentlyRented,
            onChanged: (v) => c.update(() => c.currentlyRented = v),
          ),
          if (c.currentlyRented)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _lockIn,
                      label: 'Lock-in (months)',
                      hintText: '11',
                      keyboardType: TextInputType.number,
                      inputFormatters: [_digits],
                      onChanged: (v) => c.update(() => c.lockIn = v),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      controller: _lease,
                      label: 'Lease (months)',
                      hintText: '24',
                      keyboardType: TextInputType.number,
                      inputFormatters: [_digits],
                      textInputAction: TextInputAction.done,
                      onChanged: (v) => c.update(() => c.leaseDuration = v),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.value, required this.onChanged});

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.body)),
          Switch.adaptive(value: value, activeTrackColor: AppColors.primary, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── 6 · Review ──────────────────────────────────────────────

class PostReviewStep extends StatelessWidget {
  const PostReviewStep({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PostPropertyController>();
    final amount = num.tryParse(c.price) ?? 0;
    final unit = c.isPlot
        ? '${c.plotArea} sq yd${c.plotDimensions.isEmpty ? '' : ' · ${c.plotDimensions}'}'
        : [
            c.configuration?.label ??
                [if (c.bhkOther.isNotEmpty) '${c.bhkOther} BHK', if (c.sizeOther.isNotEmpty) '${c.sizeOther} sqft'].join(' · '),
            'Unit ${c.unitNumber}${c.tower.isEmpty ? '' : ', Tower ${c.tower}'} · Floor ${c.floor}',
          ].join('\n');

    final rows = <(IconData, String, String)>[
      (Iconsax.home_2_copy, 'Property', '${c.subtype} · ${c.isCommercial ? 'Commercial' : 'Residential'}'),
      (Iconsax.building_copy, 'Project', '${c.projectLabel}\nby ${c.builderLabel}${c.city.isEmpty ? '' : ' · ${c.city}'}'),
      (Iconsax.maximize_4_copy, 'Unit', unit),
      if (c.facing != null || c.furnishing != null)
        (Iconsax.routing_2_copy, 'More', [c.facing, c.furnishing].whereType<String>().join(' · ')),
      (Iconsax.gallery_copy, 'Photos', '${c.customImages.length + c.selectedProjectImages.length} selected'),
      (
        Iconsax.wallet_money_copy,
        c.isRent ? 'Rent' : 'Price',
        [
          c.isRent ? '${Formatters.price(amount)}/mo' : Formatters.price(amount),
          if (c.isRent && c.deposit.isNotEmpty) 'Deposit ${Formatters.price(num.tryParse(c.deposit))}',
          if (c.negotiable) 'Negotiable',
        ].join(' · '),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const StepHeading(title: 'Review your listing', subtitle: 'Our team verifies every listing before it goes live.'),
        for (final (icon, title, text) in rows)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(AppRadius.sm + 2)),
                  child: Icon(icon, size: 17, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.caption),
                      Text(text, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
