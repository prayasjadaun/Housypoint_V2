import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/saved_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/listing/listing_model.dart';
import '../../repositories/listing_repository.dart';
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
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final listing = await context
          .read<ListingRepository>()
          .getListing(widget.id, rental: widget.rental);
      if (mounted) setState(() => _listing = listing);
    } on ApiException catch (e) {
      if (mounted && _listing == null) setState(() => _error = e.message);
    }
  }

  Future<void> _toggleSave(ListingModel listing) async {
    final error = await context.read<SavedController>().toggleSave(listing);
    if (error != null && mounted) context.showSnackBar(error, isError: true);
  }

  Future<void> _contact(ListingModel listing) async {
    setState(() => _sending = true);
    final error = await context
        .read<SavedController>()
        .contact(listing, distressDeal: widget.isHotDeal);
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
                  icon: Iconsax.arrow_left_copy,
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
              child: _Body(listing: listing),
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
  const _Body({required this.listing});

  final ListingModel listing;

  @override
  Widget build(BuildContext context) {
    final details = <(IconData, String, String)>[
      if (listing.areaLabel.isNotEmpty)
        (Iconsax.maximize_4_copy, 'Area', listing.areaLabel),
      if (!listing.isCommercial && listing.bhk.isNotEmpty)
        (Iconsax.home_2_copy, 'Configuration', '${listing.bhk} BHK'),
      (Iconsax.building_copy, 'Property type', Formatters.humanize(listing.subtype)),
      if (listing.floor.isNotEmpty) (Iconsax.layer_copy, 'Floor', listing.floor),
      if (listing.tower.isNotEmpty) (Iconsax.buildings_copy, 'Tower', listing.tower),
      if (listing.furnishing.isNotEmpty)
        (Iconsax.lamp_on_copy, 'Furnishing', Formatters.humanize(listing.furnishing)),
      if (listing.facing.isNotEmpty)
        (Iconsax.routing_2_copy, 'Facing', Formatters.humanize(listing.facing)),
      if (listing.isRental && (listing.securityDeposit ?? 0) > 0)
        (Iconsax.wallet_money_copy, 'Security deposit', Formatters.price(listing.securityDeposit)),
      if (listing.isRental && (listing.maintenance ?? 0) > 0)
        (Iconsax.receipt_2_copy, 'Maintenance', '${Formatters.price(listing.maintenance)}/mo'),
      if (listing.createdAt != null)
        (Iconsax.calendar_copy, 'Posted on', formatDate(listing.createdAt!)),
    ].where((d) => d.$3.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                listing.priceLabel,
                style: AppTextStyles.display.copyWith(
                  fontSize: 26,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            if (listing.negotiable) ...[
              const SizedBox(width: 10),
              const _Pill(text: 'Negotiable', color: AppColors.success),
            ],
          ],
        ),
        if (listing.marketPrice.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Market price ₹${listing.marketPrice}',
              style: AppTextStyles.caption,
            ),
          ),
        const SizedBox(height: 10),
        Text(listing.title, style: AppTextStyles.heading.copyWith(fontSize: 20)),
        if (listing.place.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Iconsax.location_copy, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  [listing.location, listing.place]
                      .where((s) => s.isNotEmpty)
                      .toSet()
                      .join(' · '),
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
        if (listing.isRental && listing.corporateLeasing) ...[
          const SizedBox(height: 12),
          const _Pill(text: 'Open to corporate leasing', color: AppColors.accentBlue),
        ],
        if (listing.projectName.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _ProjectTile(listing: listing),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text('Key details', style: AppTextStyles.title),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 64,
          ),
          itemCount: details.length,
          itemBuilder: (_, i) {
            final (icon, label, value) = details[i];
            return _DetailItem(icon: icon, label: label, value: value);
          },
        ),
        if (listing.layoutImage.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Floor plan', style: AppTextStyles.title),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => showImageGallery(context, images: [listing.layoutImage]),
            child: Container(
              height: 200,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: AppNetworkImage(url: listing.layoutImage, fit: BoxFit.contain),
            ),
          ),
        ],
        if (listing.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('About this property', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text(
            listing.description,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.listing});

  final ListingModel listing;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    final canOpen = listing.projectId != null;

    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: canOpen ? () => context.push(AppRoutes.projectPath(listing.projectId!)) : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(4),
                child: AppNetworkImage(
                  url: listing.projectLogo.isNotEmpty ? listing.projectLogo : listing.builderLogo,
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
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      [
                        if (listing.builderName.isNotEmpty) 'by ${listing.builderName}',
                        if (listing.projectStatus.isNotEmpty) listing.projectStatus,
                      ].join(' · '),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (canOpen)
                const Icon(Iconsax.arrow_right_3_copy, size: 18, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

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
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600),
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
            color: isSaved ? AppColors.accentRose.withValues(alpha: 0.1) : AppColors.surfaceMuted,
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
