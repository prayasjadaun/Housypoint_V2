import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/home_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/network/api_exception.dart';
import '../../models/project/project_model.dart';
import '../../repositories/master_data_repository.dart';
import '../../repositories/project_repository.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/page_scaffold.dart';
import '../../widgets/common/selection_sheet.dart';
import '../../widgets/pickers/location_pickers.dart';

/// Pick two projects and compare them side by side (API ref M2/M4/M6).
class CompareProjectsScreen extends StatefulWidget {
  const CompareProjectsScreen({super.key});

  @override
  State<CompareProjectsScreen> createState() => _CompareProjectsScreenState();
}

class _CompareProjectsScreenState extends State<CompareProjectsScreen> {
  final List<ProjectDetail?> _picked = [null, null];
  final List<bool> _loading = [false, false];

  Future<void> _pick(int slot) async {
    final master = context.read<MasterDataRepository>();
    final projects = context.read<ProjectRepository>();
    final city = context.read<HomeController>().selectedCity;

    try {
      final builders = await master.getBuilders(city: city);
      if (!mounted) return;
      final builderResult = await showBuilderPicker(
        context,
        builders: builders,
        selected: null,
        cityLabel: city ?? 'all cities',
      );
      final builder = builderResult.value;
      if (builder == null || !mounted) return;

      final list = await projects.getBuilderProjects(builder.id);
      if (!mounted) return;
      final picked = await showSelectionSheet<ProjectSummary>(
        context,
        title: 'Select project',
        subtitle: 'Projects by ${builder.name}',
        searchHint: 'Search project',
        items: list,
        emptyTitle: 'No project found',
        labelOf: (p) => p.name,
        subtitleOf: (p) => [p.projectType, p.city].where((s) => s.isNotEmpty).join(' · '),
        isSelected: (p) => p.id == _picked[slot]?.summary.id,
        leadingOf: (p, selected) => SelectionLeading(
          selected: selected,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: AppNetworkImage(url: p.logo, fit: BoxFit.contain, fallbackIcon: Iconsax.buildings_2_copy),
          ),
        ),
      );
      if (picked == null || !mounted) return;

      setState(() => _loading[slot] = true);
      final detail = await projects.getProject(picked.id);
      if (mounted) setState(() => _picked[slot] = detail);
    } on ApiException catch (e) {
      if (mounted) context.showSnackBar(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _loading[slot] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = PageScaffold.topInset(context);
    final a = _picked[0];
    final b = _picked[1];

    return PageScaffold(
      title: 'Compare projects',
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.md, top + AppSpacing.md, AppSpacing.md, AppSpacing.xl),
        children: [
          Text(
            'Pick two projects to see price, size, amenities and location side by side.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _Slot(label: 'Project A', project: a, loading: _loading[0], onTap: () => _pick(0))),
                const SizedBox(width: 10),
                Expanded(child: _Slot(label: 'Project B', project: b, loading: _loading[1], onTap: () => _pick(1))),
              ],
            ),
          ),
          if (a != null && b != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Comparison', style: AppTextStyles.title),
            const SizedBox(height: 10),
            _Table(a: a, b: b),
          ],
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.label, required this.project, required this.loading, required this.onTap});

  final String label;
  final ProjectDetail? project;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = project?.summary;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loading ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: p == null ? AppColors.border : AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: loading
              ? const SizedBox(
                  height: 170,
                  child: Center(child: AppSpinner()),
                )
              : p == null
              ? SizedBox(
                  height: 170,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                        child: const Icon(Iconsax.add_copy, color: AppColors.primary),
                      ),
                      const SizedBox(height: 10),
                      Text(label, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
                      Text('Tap to choose', style: AppTextStyles.caption),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppNetworkImage(
                      url: project!.images.isNotEmpty ? project!.images.first : p.image,
                      height: 100,
                      width: double.infinity,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, maxLines: 2, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700)),
                          Text(p.builderName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
                          const SizedBox(height: 4),
                          Text(
                            'Change',
                            style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.a, required this.b});

  final ProjectDetail a;
  final ProjectDetail b;

  String _configs(ProjectDetail p) => p.configurations.isEmpty
      ? '—'
      : p.configurations.map((c) => c.size.isEmpty ? c.detail : '${c.detail} · ${c.size} sqft').join('\n');

  String _nearby(ProjectDetail p) =>
      p.landmarks.isEmpty ? '—' : p.landmarks.take(3).map((l) => '${l.name} (${l.distance})').join('\n');

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String, String)>[
      (Iconsax.wallet_money_copy, 'Price range',
        a.summary.priceRange.isEmpty ? '—' : '₹${a.summary.priceRange}',
        b.summary.priceRange.isEmpty ? '—' : '₹${b.summary.priceRange}'),
      (Iconsax.buildings_2_copy, 'Builder', a.summary.builderName, b.summary.builderName),
      (Iconsax.location_copy, 'Location',
        [a.location, a.summary.city].where((s) => s.isNotEmpty).join(', '),
        [b.location, b.summary.city].where((s) => s.isNotEmpty).join(', ')),
      (Iconsax.timer_1_copy, 'Status', a.summary.status, b.summary.status),
      (Iconsax.building_copy, 'Type', a.summary.projectType, b.summary.projectType),
      (Iconsax.home_2_copy, 'Configurations', _configs(a), _configs(b)),
      (Iconsax.tick_square_copy, 'Amenities', '${a.amenities.length} amenities', '${b.amenities.length} amenities'),
      (Iconsax.routing_2_copy, 'Nearby', _nearby(a), _nearby(b)),
      (Iconsax.shield_tick_copy, 'RERA', a.rera, b.rera),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(rows[i].$1, size: 15, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(rows[i].$2, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(rows[i].$3.isEmpty ? '—' : rows[i].$3, style: AppTextStyles.label)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(rows[i].$4.isEmpty ? '—' : rows[i].$4, style: AppTextStyles.label)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                for (final p in [a, b])
                  Expanded(
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.projectPath(p.summary.id)),
                      child: const Text('View project'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
