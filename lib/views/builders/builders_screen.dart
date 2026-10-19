import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/home_controller.dart';
import '../../core/network/api_exception.dart';
import '../../models/master/builder_model.dart';
import '../../repositories/master_data_repository.dart';
import '../../router/app_routes.dart';
import '../../theme/app_assets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/page_scaffold.dart';

/// All builders (in the home city), searchable grid (API ref M2).
class BuildersScreen extends StatefulWidget {
  const BuildersScreen({super.key});

  @override
  State<BuildersScreen> createState() => _BuildersScreenState();
}

class _BuildersScreenState extends State<BuildersScreen> {
  List<BuilderModel>? _builders;
  String? _error;
  String _query = '';
  late final String? _city = context.read<HomeController>().selectedCity;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await context.read<MasterDataRepository>().getBuilders(city: _city);
      if (mounted) setState(() => _builders = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = PageScaffold.topInset(context);
    final q = _query.trim().toLowerCase();
    final list = _builders?.where((b) => b.name.toLowerCase().contains(q)).toList();

    return PageScaffold(
      title: 'Builders',
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, top + AppSpacing.md, AppSpacing.md, AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Search builders',
                      prefixIcon: Icon(Iconsax.search_normal_1_copy, size: 20, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (list != null)
                    Text(
                      '${list.length} builders${_city == null ? '' : ' in $_city'}',
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
          ),
          if (list == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: _error == null
                    ? const AppSpinner()
                    : EmptyState(
                        lottie: AppAssets.lottieServerError,
                        title: 'Couldn’t load builders',
                        message: _error!,
                        actionLabel: 'Try again',
                        onAction: _load,
                      ),
              ),
            )
          else if (list.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: EmptyState(
                  icon: Iconsax.buildings_2_copy,
                  title: 'No builders found',
                  message: 'Try a different name.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
              ),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 128,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) => _BuilderTile(builder: list[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _BuilderTile extends StatelessWidget {
  const _BuilderTile({required this.builder});

  final BuilderModel builder;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => context.push(AppRoutes.builderPath(builder.id), extra: builder),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            children: [
              Expanded(
                child: AppNetworkImage(
                  url: builder.logoUrl,
                  fit: BoxFit.contain,
                  fallbackIcon: Iconsax.buildings_2_copy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                builder.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
