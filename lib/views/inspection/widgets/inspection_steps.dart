import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../controllers/home_controller.dart';
import '../../../controllers/inspection_controller.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/pdi/pdi_models.dart';
import '../../../models/project/project_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_network_image.dart';
import '../../../widgets/common/app_refresh_indicator.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../widgets/common/choice_chips.dart';
import '../../../widgets/common/form_widgets.dart';
import '../../../widgets/common/selection_sheet.dart';
import '../../../widgets/pickers/location_pickers.dart';

String _rupees(int v) => '₹${Formatters.grouped(v)}';

// ── Step 1 · Location ───────────────────────────────────────

class LocationStep extends StatelessWidget {
  const LocationStep({super.key});

  static const _popular = [
    'Gurgaon', 'Noida', 'New Delhi', 'Ghaziabad', 'Faridabad', 'Mumbai', 'Bengaluru', 'Pune',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InspectionController>();
    final options = [..._popular, if (c.city != null && !_popular.contains(c.city)) c.city!];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const StepHeading(
          title: 'Where is your property?',
          subtitle: 'Our engineers inspect homes across these cities.',
        ),
        ChoiceChips<String>(
          options: options,
          selected: c.city,
          labelOf: (s) => s,
          iconOf: (_) => Iconsax.location_copy,
          onSelected: c.setCity,
        ),
        const SizedBox(height: AppSpacing.lg),
        PickerField(
          label: 'Another city',
          value: c.city != null && !_popular.contains(c.city) ? c.city : null,
          placeholder: 'Search all cities',
          icon: Iconsax.search_normal_1_copy,
          onTap: () async {
            final home = context.read<HomeController>();
            await home.ensureCities();
            if (!context.mounted) return;
            final result = await showCityPicker(context, cities: home.cities, selected: c.city);
            if (result.picked && result.value != null) c.setCity(result.value!);
          },
        ),
      ],
    );
  }
}

// ── Step 2 · Property ───────────────────────────────────────

class PropertyStep extends StatefulWidget {
  const PropertyStep({super.key});

  @override
  State<PropertyStep> createState() => _PropertyStepState();
}

class _PropertyStepState extends State<PropertyStep> {
  late final c = context.read<InspectionController>();
  late final _builderOther = TextEditingController(text: c.builderOther);
  late final _projectOther = TextEditingController(text: c.projectOther);
  late final _unit = TextEditingController(text: c.unitNumber);
  late final _floor = TextEditingController(text: c.floorNumber);

  @override
  void dispose() {
    for (final t in [_builderOther, _projectOther, _unit, _floor]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBuilder() async {
    final builders = c.builders ?? const [];
    final result = await showBuilderPicker(
      context,
      builders: builders,
      selected: c.builder,
      cityLabel: c.city ?? 'your city',
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
      subtitleOf: (p) => [p.location, p.city].where((s) => s.isNotEmpty).toSet().join(', '),
      isSelected: (p) => p.id == c.project?.id,
      leadingOf: (p, selected) => SelectionLeading(
        selected: selected,
        child: p.logo.isEmpty
            ? Icon(Iconsax.buildings_2_copy, size: 20, color: AppColors.textSecondary)
            : Padding(padding: const EdgeInsets.all(4), child: AppNetworkImage(url: p.logo, fit: BoxFit.contain)),
      ),
    );
    if (picked != null) c.setProject(picked);
  }

  Future<void> _pickFloorPlan() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (file?.path == null || !mounted) return;
    final error = await c.uploadFloorPlan(file!.path!, file.name);
    if (error != null && mounted) context.showSnackBar(error, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InspectionController>();
    final otherProject = c.useOtherProject || c.useOtherBuilder;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const StepHeading(
          title: 'Tell us about the property',
          subtitle: 'We’ll match the inspection to your project’s specs.',
        ),
        if (!c.useOtherBuilder)
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
        CheckRow(
          label: 'My builder isn’t listed',
          value: c.useOtherBuilder,
          onChanged: c.setUseOtherBuilder,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!otherProject)
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
            label: 'Project name',
            hintText: 'Type the project name',
            icon: Iconsax.building_copy,
            textCapitalization: TextCapitalization.words,
            onChanged: (v) => c.update(() => c.projectOther = v),
          ),
        if (!c.useOtherBuilder)
          CheckRow(
            label: 'My project isn’t listed',
            value: c.useOtherProject,
            onChanged: c.setUseOtherProject,
          ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: _unit,
                label: 'Unit / flat no.',
                hintText: 'A-1203',
                icon: Iconsax.home_hashtag_copy,
                textCapitalization: TextCapitalization.characters,
                onChanged: (v) => c.update(() => c.unitNumber = v),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                controller: _floor,
                label: 'Floor',
                hintText: '12',
                icon: Iconsax.layer_copy,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onChanged: (v) => c.update(() => c.floorNumber = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _FloorPlanCard(
          name: c.floorPlanName,
          uploading: c.uploadingFloorPlan,
          onPick: _pickFloorPlan,
          onRemove: c.removeFloorPlan,
        ),
      ],
    );
  }
}

class _FloorPlanCard extends StatelessWidget {
  const _FloorPlanCard({required this.name, required this.uploading, required this.onPick, required this.onRemove});

  final String? name;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final uploaded = name != null;
    return Material(
      color: uploaded ? AppColors.primarySoft : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: uploading || uploaded ? null : onPick,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: uploaded ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: uploading
                    ? const Center(child: AppSpinner(size: 20))
                    : Icon(
                        uploaded ? Iconsax.document_text_copy : Iconsax.document_upload_copy,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uploaded ? name! : 'Upload floor plan (optional)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      uploading
                          ? 'Uploading…'
                          : uploaded
                          ? 'Uploaded'
                          : 'PDF, JPG or PNG — helps our engineers prepare',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (uploaded)
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(Iconsax.close_circle_copy, size: 20, color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 3 · Plan ───────────────────────────────────────────

class PlanStep extends StatelessWidget {
  const PlanStep({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InspectionController>();
    final plans = c.plans;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const StepHeading(
          title: 'Choose your plan',
          subtitle: 'Every plan includes a detailed digital report.',
        ),
        if (plans == null)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: AppSpinner()),
          )
        else
          for (final p in plans)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PlanCard(plan: p, selected: c.plan?.id == p.id, onTap: () => c.setPlan(p)),
            ),
      ],
    );
  }
}

/// Selectable plan with price, savings and feature list. Also used by the
/// home screen's plan comparison sheet.
class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan, required this.selected, required this.onTap});

  final PdiPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft.withValues(alpha: 0.5) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.8 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(plan.title, style: AppTextStyles.title)),
                if (plan.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Text(
                      'Most popular',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 10.5),
                    ),
                  ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.primary : Colors.transparent,
                    border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 2),
                  ),
                  child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                ),
              ],
            ),
            if (plan.description.isNotEmpty) Text(plan.description, style: AppTextStyles.caption),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_rupees(plan.price), style: AppTextStyles.display.copyWith(fontSize: 24, color: AppColors.primaryText)),
                const SizedBox(width: 8),
                if (plan.oldPrice > plan.price)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _rupees(plan.oldPrice),
                      style: AppTextStyles.caption.copyWith(decoration: TextDecoration.lineThrough),
                    ),
                  ),
                const Spacer(),
                if (plan.savings > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Save ${_rupees(plan.savings)}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            Text('+ 18% GST', style: AppTextStyles.caption.copyWith(fontSize: 11)),
            const SizedBox(height: 12),
            for (final f in plan.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Iconsax.tick_circle_copy, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: AppTextStyles.label)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Step 4 · Schedule ───────────────────────────────────────

class ScheduleStep extends StatelessWidget {
  const ScheduleStep({super.key});

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InspectionController>();
    final dates = c.dates ?? const <DateTime>[];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: StepHeading(
            title: 'Pick a date & time',
            subtitle: 'An engineer will reach your property in this slot.',
          ),
        ),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: dates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = dates[i];
              final selected = c.date == d;
              return GestureDetector(
                onTap: () => c.setDate(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 62,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _weekdays[d.weekday - 1],
                        style: AppTextStyles.caption.copyWith(color: selected ? Colors.white70 : AppColors.textSecondary),
                      ),
                      Text(
                        '${d.day}',
                        style: AppTextStyles.title.copyWith(color: selected ? Colors.white : AppColors.textPrimary),
                      ),
                      Text(
                        _months[d.month - 1],
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: selected ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: c.date == null
              ? Text('Select a date to see available slots.', style: AppTextStyles.caption)
              : c.slots == null
              ? const Center(child: AppSpinner())
              : c.slots!.isEmpty
              ? Text('No slots left on this day — try another date.', style: AppTextStyles.caption)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available slots', style: AppTextStyles.title.copyWith(fontSize: 15)),
                    const SizedBox(height: 10),
                    ChoiceChips<PdiSlot>(
                      options: c.slots!,
                      selected: c.slot,
                      labelOf: (s) => s.label,
                      iconOf: (_) => Iconsax.clock_copy,
                      onSelected: c.setSlot,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ── Step 5 · Review ─────────────────────────────────────────

class ReviewStep extends StatefulWidget {
  const ReviewStep({super.key});

  @override
  State<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends State<ReviewStep> {
  late final _notes = TextEditingController(text: context.read<InspectionController>().notes);

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InspectionController>();
    final plan = c.plan!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const StepHeading(title: 'Review & confirm', subtitle: 'Check the details before booking.'),
        _SummaryCard(
          icon: Iconsax.building_copy,
          title: 'Property',
          lines: [
            c.projectLabel,
            'by ${c.builderLabel}',
            'Unit ${c.unitNumber} · Floor ${c.floorNumber} · ${c.city}',
            if (c.floorPlanName != null) 'Floor plan attached',
          ],
        ),
        _SummaryCard(icon: Iconsax.shield_tick_copy, title: 'Plan', lines: [plan.title, plan.description]),
        _SummaryCard(
          icon: Iconsax.calendar_tick_copy,
          title: 'Schedule',
          lines: [if (c.date != null) formatDate(c.date!), c.slot?.label ?? ''],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            children: [
              _PriceRow(label: 'Plan price', value: _rupees(plan.price)),
              if (plan.savings > 0)
                _PriceRow(label: 'You save', value: '-${_rupees(plan.savings)}', color: AppColors.success),
              _PriceRow(label: 'GST (18%)', value: _rupees(plan.gst)),
              Divider(height: 20, color: AppColors.border),
              _PriceRow(label: 'Total payable', value: _rupees(plan.total), bold: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: _notes,
          label: 'Notes for the engineer (optional)',
          hintText: 'Parking, gate pass, key holder…',
          icon: Iconsax.message_text_copy,
          textInputAction: TextInputAction.done,
          onChanged: (v) => c.notes = v,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.icon, required this.title, required this.lines});

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final visible = lines.where((l) => l.trim().isNotEmpty).toList();
    return Container(
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(AppRadius.sm + 2)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.caption),
                for (var i = 0; i < visible.length; i++)
                  Text(
                    visible[i],
                    style: i == 0
                        ? AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)
                        : AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value, this.bold = false, this.color});

  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? AppTextStyles.title.copyWith(fontSize: 16, color: AppColors.primaryText)
        : AppTextStyles.body.copyWith(color: color ?? AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: bold ? AppTextStyles.body.copyWith(fontWeight: FontWeight.w600) : style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
