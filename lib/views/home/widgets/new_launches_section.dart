import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../controllers/home_controller.dart';
import '../../../core/utils/app_haptics.dart';
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
          height: 270,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: projects?.length ?? 2,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => projects == null
                ? const SkeletonBox(width: 230, height: 270, radius: AppRadius.xl)
                : LaunchCard(project: projects[i]),
          ),
        ),
      ],
    );
  }
}

/// Full-bleed project card: photo fills the card, details on a dark fade.
class LaunchCard extends StatelessWidget {
  const LaunchCard({super.key, required this.project});

  final ProjectSummary project;

  @override
  Widget build(BuildContext context) {
    final place = [project.builderName, project.city].where((s) => s.isNotEmpty).join(' · ');

    return SizedBox(
      width: 230,
      child: Material(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.xl + 4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            AppHaptics.tap();
            context.push(AppRoutes.projectPath(project.id));
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppNetworkImage(url: project.image),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.25, 0.5, 1],
                    colors: [Color(0x40000000), Colors.transparent, Color(0x1A000000), Color(0xE6000000)],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.flash_1_copy, size: 12, color: AppColors.ink),
                      const SizedBox(width: 4),
                      Text(
                        'New launch',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (project.builderLogo.isNotEmpty)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 42,
                    height: 42,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: AppNetworkImage(url: project.builderLogo, fit: BoxFit.contain),
                  ),
                ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      project.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(color: Colors.white, height: 1.25),
                    ),
                    if (place.isNotEmpty)
                      Text(
                        place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.78)),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          project.priceRange.isEmpty ? 'Price on request' : '₹${project.priceRange}',
                          style: AppTextStyles.body.copyWith(color: AppColors.gold, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Iconsax.arrow_right_3_copy, size: 15, color: Colors.white),
                        ),
                      ],
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
