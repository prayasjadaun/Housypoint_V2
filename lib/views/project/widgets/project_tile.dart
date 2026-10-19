import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../models/project/project_model.dart';
import '../../../router/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_network_image.dart';

/// Compact project row: photo, name, builder/place, status and price.
class ProjectTile extends StatelessWidget {
  const ProjectTile({super.key, required this.project, this.onTap});

  final ProjectSummary project;

  /// Defaults to opening the project detail.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl);
    final place = {
      if (project.location.isNotEmpty) project.location,
      if (project.city.isNotEmpty) project.city,
    }.join(', ');

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap ?? () => context.push(AppRoutes.projectPath(project.id)),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: AppNetworkImage(url: project.image, width: 92, height: 92),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (project.builderName.isNotEmpty)
                      Text('by ${project.builderName}', style: AppTextStyles.caption),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Iconsax.location_copy, size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (project.status.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              project.status,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (project.priceRange.isNotEmpty)
                          Text(
                            '₹${project.priceRange}',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
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
