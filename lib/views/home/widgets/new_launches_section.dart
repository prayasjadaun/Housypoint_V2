import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../controllers/home_controller.dart';
import '../../../models/project/project_model.dart';
import '../../../router/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_network_image.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/skeleton_box.dart';

/// "New launches" — fresh projects in the selected city (API ref C5).
class NewLaunchesSection extends StatelessWidget {
  const NewLaunchesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = context.select<HomeController, List<ProjectSummary>?>(
      (h) => h.newLaunches,
    );
    if (projects != null && projects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'New launches',
          subtitle: 'Be the first to book in upcoming projects',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: projects?.length ?? 2,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => projects == null
                ? const SkeletonBox(width: 230, height: 250, radius: AppRadius.xl)
                : _LaunchCard(project: projects[i]),
          ),
        ),
      ],
    );
  }
}

class _LaunchCard extends StatelessWidget {
  const _LaunchCard({required this.project});

  final ProjectSummary project;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl);

    return SizedBox(
      width: 230,
      child: Material(
        color: AppColors.surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.projectPath(project.id)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(url: project.image),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.flash_1_copy, size: 11, color: AppColors.textPrimary),
                              const SizedBox(width: 3),
                              Text(
                                'New launch',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (project.builderLogo.isNotEmpty)
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                            ),
                            child: AppNetworkImage(url: project.builderLogo, fit: BoxFit.contain),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        [project.builderName, project.city].where((s) => s.isNotEmpty).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        project.priceRange.isEmpty ? 'Price on request' : '₹${project.priceRange}',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
