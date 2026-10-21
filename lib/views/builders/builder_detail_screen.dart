import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../models/master/builder_model.dart';
import '../../models/project/project_model.dart';
import '../../repositories/master_data_repository.dart';
import '../../repositories/project_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/page_scaffold.dart';
import '../../widgets/common/segmented_toggle.dart';
import '../project/widgets/project_tile.dart';

/// One builder: logo, head office and its projects (API ref M3/M4).
class BuilderDetailScreen extends StatefulWidget {
  const BuilderDetailScreen({super.key, required this.id, this.initial});

  final int id;
  final BuilderModel? initial;

  @override
  State<BuilderDetailScreen> createState() => _BuilderDetailScreenState();
}

class _BuilderDetailScreenState extends State<BuilderDetailScreen> {
  late BuilderModel? _builder = widget.initial;
  List<ProjectSummary>? _projects;
  String? _error;
  int _tab = 0; // 0 residential, 1 commercial

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final master = context.read<MasterDataRepository>();
    final projects = context.read<ProjectRepository>();
    try {
      final results = await Future.wait([
        master.getBuilder(widget.id),
        projects.getBuilderProjects(widget.id),
      ]);
      if (!mounted) return;
      setState(() {
        _builder = results[0] as BuilderModel;
        _projects = results[1] as List<ProjectSummary>;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = PageScaffold.topInset(context);
    final b = _builder;
    final all = _projects;
    final residential = all?.where((p) => p.projectType.toLowerCase() != 'commercial').toList();
    final commercial = all?.where((p) => p.projectType.toLowerCase() == 'commercial').toList();
    final shown = _tab == 0 ? residential : commercial;

    return PageScaffold(
      title: b?.name ?? 'Builder',
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.md, top + AppSpacing.md, AppSpacing.md, AppSpacing.xl),
        children: [
          if (b != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: AppNetworkImage(url: b.logoUrl, fit: BoxFit.contain, fallbackIcon: Iconsax.buildings_2_copy),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.name, style: AppTextStyles.title),
                        if (all != null)
                          Text('${all.length} ${all.length == 1 ? 'project' : 'projects'} on Housy Point', style: AppTextStyles.caption),
                        if (b.address.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Iconsax.building_copy, size: 13, color: AppColors.textTertiary),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(b.address, style: AppTextStyles.caption.copyWith(fontSize: 11.5)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          SegmentedToggle(
            labels: [
              'Residential${residential == null ? '' : ' · ${residential.length}'}',
              'Commercial${commercial == null ? '' : ' · ${commercial.length}'}',
            ],
            icons: const [Iconsax.home_2_copy, Iconsax.building_4_copy],
            selectedIndex: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: AppSpacing.md),
          if (shown == null)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                child: _error == null
                    ? const AppSpinner()
                    : EmptyState(
                        icon: Iconsax.warning_2_copy,
                        title: 'Couldn’t load projects',
                        message: _error!,
                        actionLabel: 'Try again',
                        onAction: _load,
                      ),
              ),
            )
          else if (shown.isEmpty)
            const EmptyState(
              icon: Iconsax.buildings_2_copy,
              title: 'No projects here yet',
              message: 'Check the other tab.',
            )
          else
            for (final p in shown)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: ProjectTile(project: p)),
        ],
      ),
    );
  }
}
