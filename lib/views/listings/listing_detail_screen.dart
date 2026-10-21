import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/saved_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/listing/listing_model.dart';
import '../../models/project/project_model.dart';
import '../../repositories/listing_repository.dart';
import '../../repositories/project_repository.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/glass_icon_button.dart';
import '../../widgets/common/image_carousel.dart';
import '../../widgets/common/image_gallery_viewer.dart';
import '../../widgets/icons/amenity_icon.dart';

/// One resale/rental listing. Shows the card data passed in [initial]
/// at once, then refreshes from `listings/{properties|rentals}/{id}/`.
class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({
    super.key,
    required this.id,
    required this.rental,
    this.initial,
    this.isHotDeal = false,
  });

  final int id;
  final bool rental;
  final ListingModel? initial;

  /// Opened from Hot deals — sent along with the interest request.
  final bool isHotDeal;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  late ListingModel? _listing = widget.initial;
  ProjectDetail? _project;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final projects = context.read<ProjectRepository>();
    try {
      final listing = await context.read<ListingRepository>().getListing(
        widget.id,
        rental: widget.rental,
      );
      if (mounted) setState(() => _listing = listing);
    } on ApiException catch (e) {
      if (mounted && _listing == null) setState(() => _error = e.message);
    }
    // Amenities, landmarks and photos live on the project, not the listing.
    final projectId = _listing?.projectId;
    if (projectId == null) return;
    try {
      final project = await projects.getProject(projectId);
      if (mounted) setState(() => _project = project);
    } on ApiException {
      // Optional sections simply stay hidden.
    }
  }

  Future<void> _toggleSave(ListingModel listing) async {
    final error = await context.read<SavedController>().toggleSave(listing);
    if (error != null && mounted) context.showSnackBar(error, isError: true);
  }

  Future<void> _contact(ListingModel listing) async {
    setState(() => _sending = true);
    final error = await context.read<SavedController>().contact(
      listing,
      distressDeal: widget.isHotDeal,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    context.showSnackBar(
      error ?? "Request sent — we'll connect you with the owner shortly.",
      isError: error != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final listing = _listing;
    if (listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: _error == null
              ? const AppSpinner()
              : Text(_error!, style: AppTextStyles.body),
        ),
      );
    }

    final saved = context.watch<SavedController>();
    final isSaved = saved.savedState(listing);
    final contacted = saved.isContacted(listing);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: Center(
                child: GlassIconButton(
                  icon: CupertinoIcons.back,
                  onTap: () => context.pop(),
                ),
              ),
            ),
            actions: [
              GlassIconButton(
                icon: Iconsax.heart_copy,
                background: isSaved ? AppColors.accentRose : null,
                onTap: () => _toggleSave(listing),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ImageCarousel(images: listing.images),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              // Rounded sheet pulled over the photos
              transform: Matrix4.translationValues(0, -24, 0),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: _Body(listing: listing, project: _project),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ActionBar(
        isSaved: isSaved,
        contacted: contacted,
        sending: _sending,
        onSave: () => _toggleSave(listing),
        onContact: () => _contact(listing),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.listing, this.project});

  final ListingModel listing;
  final ProjectDetail? project;

  /// "₹18,450 / sqft" for sale listings with a numeric size.
  String? get _perSqft {
    final size = double.tryParse(listing.size);
    if (listing.isRental || size == null || size <= 0 || listing.price <= 0) {
      return null;
    }
    return '₹${Formatters.grouped((listing.price / size).round())} / sqft';
  }

  @override
  Widget build(BuildContext context) {
    final specs = <(IconData, String, String)>[
      if (!listing.isCommercial && listing.bhk.isNotEmpty)
        (Iconsax.home_2_copy, '${listing.bhk} BHK', 'Configuration'),
      if (listing.isCommercial)
        (Iconsax.building_4_copy, Formatters.humanize(listing.subtype), 'Type'),
      if (listing.size.isNotEmpty)
        (Iconsax.maximize_4_copy, listing.size, listing.sizeUnit),
      if (listing.floor.isNotEmpty)
        (Iconsax.layer_copy, listing.floor, 'Floor'),
      if (listing.facing.isNotEmpty)
        (Iconsax.routing_2_copy, Formatters.humanize(listing.facing), 'Facing'),
    ].take(4).toList();

    final details = <(String, String)>[
      ('Property type', Formatters.humanize(listing.subtype)),
      if (listing.isRental) ('Monthly rent', Formatters.price(listing.price)),
      if (listing.isRental && (listing.securityDeposit ?? 0) > 0)
        ('Security deposit', Formatters.price(listing.securityDeposit)),
      if (listing.isRental && (listing.maintenance ?? 0) > 0)
        ('Maintenance', '${Formatters.price(listing.maintenance)} / mo'),
      if (listing.furnishing.isNotEmpty)
        ('Furnishing', Formatters.humanize(listing.furnishing)),
      if (listing.tower.isNotEmpty) ('Tower', listing.tower),
      if (listing.unitNumber.isNotEmpty) ('Unit', listing.unitNumber),
      if (listing.areaLabel.isNotEmpty)
        ('Carpet / super area', listing.areaLabel),
      if (listing.projectStatus.isNotEmpty)
        ('Possession', listing.projectStatus),
      if (listing.isRental)
        ('Corporate leasing', listing.corporateLeasing ? 'Open' : 'No'),
      if (listing.createdAt != null)
        ('Listed on', formatDate(listing.createdAt!)),
    ].where((d) => d.$2.isNotEmpty).toList();

    final place = {
      listing.location,
      listing.place,
    }.where((s) => s.isNotEmpty).join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.md),
        // ── Price & title ───────────────────────────────
        Row(
          children: [
            _Tag(
              text: listing.isRental ? 'For rent' : 'For sale',
              color: AppColors.primary,
            ),
            if (listing.negotiable) ...[
              const SizedBox(width: 6),
              const _Tag(text: 'Negotiable', color: AppColors.goldDark),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              listing.priceLabel,
              style: AppTextStyles.display.copyWith(
                fontSize: 28,
                color: AppColors.textPrimary,
              ),
            ),
            if (_perSqft != null) ...[
              const SizedBox(width: 10),
              Flexible(child: Text(_perSqft!, style: AppTextStyles.caption)),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(listing.title, style: AppTextStyles.title.copyWith(fontSize: 18)),
        if (place.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Iconsax.location_copy,
                  size: 15,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  place,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],

        // ── Spec bar ─────────────────────────────────────
        if (specs.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _SpecBar(specs: specs),
        ],

        // ── Market comparison ────────────────────────────
        if (listing.marketPrice.isNotEmpty && !listing.isRental) ...[
          const SizedBox(height: 12),
          _MarketCard(listing: listing),
        ],

        // ── Project ──────────────────────────────────────
        if (listing.projectName.isNotEmpty) ...[
          const _SectionTitle('Project'),
          _ProjectCard(listing: listing, project: project),
        ],

        // ── Details ──────────────────────────────────────
        const _SectionTitle('Property details'),
        _DetailsList(rows: details),

        // ── Amenities ────────────────────────────────────
        if (project != null && project!.amenities.isNotEmpty) ...[
          _SectionTitle('Amenities', trailing: '${project!.amenities.length}'),
          _AmenitiesGrid(amenities: project!.amenities),
        ],

        // ── Nearby ───────────────────────────────────────
        if (project != null && project!.landmarks.isNotEmpty) ...[
          const _SectionTitle('Nearby'),
          for (final l in project!.landmarks.take(5)) _LandmarkRow(landmark: l),
        ],

        // ── Floor plan ───────────────────────────────────
        if (listing.layoutImage.isNotEmpty) ...[
          const _SectionTitle('Floor plan'),
          GestureDetector(
            onTap: () =>
                showImageGallery(context, images: [listing.layoutImage]),
            child: Container(
              height: 210,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.7),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: AppNetworkImage(
                      url: listing.layoutImage,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.maximize_4_copy,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to zoom',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // ── About ────────────────────────────────────────
        if (listing.description.isNotEmpty) ...[
          const _SectionTitle('About this property'),
          Text(
            listing.description,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        const _TrustNote(),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.title.copyWith(fontSize: 16)),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                trailing!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Four headline specs in one card, split by hairlines.
class _SpecBar extends StatelessWidget {
  const _SpecBar({required this.specs});

  final List<(IconData, String, String)> specs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < specs.length; i++) ...[
              if (i > 0)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.border,
                ),
              Expanded(
                child: Column(
                  children: [
                    Icon(specs[i].$1, size: 20, color: AppColors.primary),
                    const SizedBox(height: 6),
                    Text(
                      specs[i].$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      specs[i].$3,
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Asking price vs the project's market price for this configuration.
class _MarketCard extends StatelessWidget {
  const _MarketCard({required this.listing});

  final ListingModel listing;

  /// "3.25 Cr" / "85 L" → rupees.
  static double? _parse(String text) {
    final m = RegExp(
      r'([\d.]+)\s*(cr|l|lac|lakh)?',
      caseSensitive: false,
    ).firstMatch(text);
    final value = double.tryParse(m?.group(1) ?? '');
    if (value == null) return null;
    final unit = (m?.group(2) ?? '').toLowerCase();
    return unit == 'cr'
        ? value * 1e7
        : unit.startsWith('l')
        ? value * 1e5
        : value;
  }

  @override
  Widget build(BuildContext context) {
    final market = _parse(listing.marketPrice);
    final diff = market == null || market <= 0
        ? null
        : (market - listing.price) / market * 100;
    final below = diff != null && diff > 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          colors: below
              ? [AppColors.primarySoft, AppColors.surface]
              : [AppColors.background, AppColors.surface],
        ),
        border: Border.all(
          color: below
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            below ? Iconsax.trend_down_copy : Iconsax.chart_2_copy,
            color: below ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market price ₹${listing.marketPrice}',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  below
                      ? 'This listing is priced below the market'
                      : 'Based on similar units in the project',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (below)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '${diff.round()}% less',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.listing, this.project});

  final ListingModel listing;
  final ProjectDetail? project;

  @override
  Widget build(BuildContext context) {
    final canOpen = listing.projectId != null;
    final cover = project?.images.isNotEmpty == true
        ? project!.images.first
        : '';
    final radius = BorderRadius.circular(AppRadius.xl);

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: canOpen
            ? () => context.push(AppRoutes.projectPath(listing.projectId!))
            : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            children: [
              if (cover.isNotEmpty)
                AppNetworkImage(
                  url: cover,
                  height: 110,
                  width: double.infinity,
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: AppNetworkImage(
                        url: listing.projectLogo.isNotEmpty
                            ? listing.projectLogo
                            : listing.builderLogo,
                        fit: BoxFit.contain,
                        fallbackIcon: Iconsax.buildings_2_copy,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.projectName,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            [
                              if (listing.builderName.isNotEmpty)
                                'by ${listing.builderName}',
                              if (project?.summary.priceRange.isNotEmpty ==
                                  true)
                                '₹${project!.summary.priceRange}',
                            ].join(' · '),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    if (canOpen)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'View',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

/// Label ↔ value rows with hairline dividers.
class _DetailsList extends StatelessWidget {
  const _DetailsList({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].$1,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom line icons in soft tiles; first eight, then "Show all".
class _AmenitiesGrid extends StatefulWidget {
  const _AmenitiesGrid({required this.amenities});

  final List<Amenity> amenities;

  @override
  State<_AmenitiesGrid> createState() => _AmenitiesGridState();
}

class _AmenitiesGridState extends State<_AmenitiesGrid> {
  static const _preview = 8;
  bool _expanded = false;

  String _title(String name) => name
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final all = widget.amenities;
    final shown = _expanded ? all : all.take(_preview).toList();

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 8,
              // 56 tile + 6 gap + two lines of 11pt text, with room to spare
              mainAxisExtent: 98,
            ),
            itemCount: shown.length,
            itemBuilder: (_, i) => Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg + 2),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primarySoft, AppColors.surface],
                    ),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: AmenityIcon(
                    name: shown[i].name,
                    size: 26,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _title(shown[i].name),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    height: 1.25,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (all.length > _preview)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Show less' : 'Show all ${all.length} amenities',
            ),
          ),
      ],
    );
  }
}

class _LandmarkRow extends StatelessWidget {
  const _LandmarkRow({required this.landmark});

  final Landmark landmark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Iconsax.location_tick_copy,
              size: 17,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(landmark.name, style: AppTextStyles.body)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              landmark.distance,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.verify_copy, color: AppColors.goldDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verified by Housy Point',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Our team checks every listing before it goes live. Zero brokerage.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isSaved,
    required this.contacted,
    required this.sending,
    required this.onSave,
    required this.onContact,
  });

  final bool isSaved;
  final bool contacted;
  final bool sending;
  final VoidCallback onSave;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        12,
        AppSpacing.md,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: isSaved
                ? AppColors.accentRose.withValues(alpha: 0.1)
                : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: onSave,
              child: SizedBox.square(
                dimension: 54,
                child: Icon(
                  Iconsax.heart_copy,
                  color: isSaved ? AppColors.accentRose : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: contacted ? 'Request sent' : "I'm interested",
              icon: contacted ? Iconsax.tick_circle_copy : Iconsax.call_copy,
              isLoading: sending,
              onPressed: contacted ? null : onContact,
            ),
          ),
        ],
      ),
    );
  }
}
