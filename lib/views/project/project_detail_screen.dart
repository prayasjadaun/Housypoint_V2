import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/saved_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/launcher.dart';
import '../../models/listing/listing_model.dart';
import '../../models/project/project_model.dart';
import '../../repositories/listing_repository.dart';
import '../../repositories/project_repository.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/glass_icon_button.dart';
import '../../widgets/common/image_carousel.dart';
import '../../widgets/common/image_gallery_viewer.dart';
import '../../widgets/common/section_header.dart';
import '../listings/widgets/property_card.dart';

/// A builder project — `GET /api/projects/{id}/` plus the listings
/// available in it.
class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  ProjectDetail? _project;
  List<ListingModel> _listings = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final project = await context.read<ProjectRepository>().getProject(widget.id);
      if (!mounted) return;
      setState(() => _project = project);
      final listings = await context
          .read<ListingRepository>()
          .getListings(rental: false, projectId: widget.id, pageSize: 10);
      if (mounted) setState(() => _listings = listings.items);
    } on ApiException catch (e) {
      if (mounted && _project == null) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;
    if (project == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: _error == null
              ? const AppSpinner()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: AppTextStyles.body),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
        ),
      );
    }
    final p = project.summary;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: Center(
                child: GlassIconButton(
                  icon: Iconsax.arrow_left_copy,
                  onTap: () => context.pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: ImageCarousel(
                images: project.images.isNotEmpty ? project.images : [p.image],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -24, 0),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _Header(project: project),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _QuickActions(project: project),
                  ),
                  if (project.configurations.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader(
                      title: 'Configurations',
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 132,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        itemCount: project.configurations.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => _ConfigCard(config: project.configurations[i]),
                      ),
                    ),
                  ],
                  if (_listings.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(
                      title: 'Available in this project',
                      subtitle: '${_listings.length} resale ${_listings.length == 1 ? 'listing' : 'listings'}',
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    ),
                    const SizedBox(height: 12),
                    _ListingsCarousel(listings: _listings),
                  ],
                  if (project.amenities.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader(
                      title: 'Amenities',
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: _AmenitiesGrid(amenities: project.amenities),
                    ),
                  ],
                  if (project.landmarks.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader(
                      title: 'Nearby',
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        children: [
                          for (final l in project.landmarks) _LandmarkRow(landmark: l),
                        ],
                      ),
                    ),
                  ],
                  if (project.masterLayout.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader(
                      title: 'Master layout',
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: GestureDetector(
                        onTap: () => showImageGallery(context, images: [project.masterLayout]),
                        child: Container(
                          height: 200,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: AppNetworkImage(url: project.masterLayout, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ],
                  if (project.about.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader(
                      title: 'About the project',
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Text(
                        project.about,
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.project});

  final ProjectDetail project;

  @override
  Widget build(BuildContext context) {
    final p = project.summary;
    final place = [
      if (project.sector.isNotEmpty) 'Sector ${project.sector}',
      if (p.city.isNotEmpty) p.city,
    ].join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(6),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: AppNetworkImage(
                url: p.logo.isNotEmpty ? p.logo : p.builderLogo,
                fit: BoxFit.contain,
                fallbackIcon: Iconsax.buildings_2_copy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: AppTextStyles.heading.copyWith(fontSize: 20)),
                  if (p.builderName.isNotEmpty)
                    Text('by ${p.builderName}', style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (p.status.isNotEmpty) _Chip(icon: Iconsax.timer_1_copy, text: p.status),
            if (p.projectType.isNotEmpty) _Chip(icon: Iconsax.building_copy, text: p.projectType),
            if (p.isNewLaunch) const _Chip(icon: Iconsax.flash_1_copy, text: 'New launch', gold: true),
          ],
        ),
        if (place.isNotEmpty || project.location.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Iconsax.location_copy, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  [project.location, place].where((s) => s.isNotEmpty).join(' · '),
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Price range',
                  value: p.priceRange.isEmpty ? 'On request' : '₹${p.priceRange}',
                ),
              ),
              if (project.rera.isNotEmpty) ...[
                Container(width: 1, height: 34, color: AppColors.primary.withValues(alpha: 0.15)),
                const SizedBox(width: 14),
                Expanded(child: _Stat(label: 'RERA', value: project.rera)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, this.gold = false});

  final IconData icon;
  final String text;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final color = gold ? AppColors.goldDark : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: gold ? AppColors.gold.withValues(alpha: 0.18) : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: gold ? Colors.transparent : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(text, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.project});

  final ProjectDetail project;

  @override
  Widget build(BuildContext context) {
    final actions = [
      if (project.brochureUrl.isNotEmpty)
        (Iconsax.document_download_copy, 'Brochure', () => Launcher.url(project.brochureUrl)),
      (Iconsax.map_copy, 'Location', () => Launcher.url(project.mapsSearchUrl)),
      if (project.masterLayout.isNotEmpty)
        (Iconsax.maximize_4_copy, 'Layout', () => showImageGallery(context, images: [project.masterLayout])),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Material(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: actions[i].$3,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
                  ),
                  child: Column(
                    children: [
                      Icon(actions[i].$1, size: 20, color: AppColors.primary),
                      const SizedBox(height: 4),
                      Text(actions[i].$2, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({required this.config});

  final ProjectConfiguration config;

  @override
  Widget build(BuildContext context) {
    final hasPlan = config.layoutImage.isNotEmpty;
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: hasPlan ? () => showImageGallery(context, images: [config.layoutImage]) : null,
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(config.detail, style: AppTextStyles.title.copyWith(fontSize: 16)),
              if (config.size.isNotEmpty)
                Text('${config.size} sqft', style: AppTextStyles.caption),
              const Spacer(),
              if (config.marketPrice.isNotEmpty)
                Text(
                  '₹${config.marketPrice}',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (hasPlan)
                Row(
                  children: [
                    const Icon(Iconsax.maximize_4_copy, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Floor plan',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingsCarousel extends StatelessWidget {
  const _ListingsCarousel({required this.listings});

  final List<ListingModel> listings;

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedController>();
    return SizedBox(
      height: 330,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: listings.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final l = listings[i];
          return SizedBox(
            width: 260,
            child: PropertyCard(
              listing: l,
              isSaved: saved.savedState(l),
              onSave: () async {
                final error = await saved.toggleSave(l);
                if (error != null && context.mounted) context.showSnackBar(error, isError: true);
              },
              onTap: () => context.push(AppRoutes.listingPath(l.id, rental: l.isRental), extra: l),
            ),
          );
        },
      ),
    );
  }
}

class _AmenitiesGrid extends StatelessWidget {
  const _AmenitiesGrid({required this.amenities});

  final List<Amenity> amenities;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        mainAxisExtent: 84,
      ),
      itemCount: amenities.length,
      itemBuilder: (_, i) {
        final a = amenities[i];
        return Column(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: AppNetworkImage(
                url: a.icon,
                fit: BoxFit.contain,
                fallbackIcon: Iconsax.tick_square_copy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              a.name.isEmpty ? '' : a.name[0].toUpperCase() + a.name.substring(1),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.2),
            ),
          ],
        );
      },
    );
  }
}

class _LandmarkRow extends StatelessWidget {
  const _LandmarkRow({required this.landmark});

  final Landmark landmark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.sm + 2),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: const Icon(Iconsax.location_tick_copy, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(landmark.name, style: AppTextStyles.body)),
          Text(
            landmark.distance,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
