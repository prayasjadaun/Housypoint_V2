import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/listing/listing_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_network_image.dart';

/// Listing card: photo with badge + save button, then price, title,
/// project/builder, place and quick facts. Used in carousels and lists.
class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.onSave,
    this.isSaved = false,
    this.badge,
    this.imageHeight = 150,
  });

  final ListingModel listing;
  final VoidCallback onTap;

  /// Null hides the save button.
  final VoidCallback? onSave;
  final bool isSaved;

  /// Small label on the photo, e.g. "Hot deal".
  final String? badge;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl);
    final facts = [
      if (listing.areaLabel.isNotEmpty) (Iconsax.maximize_4_copy, listing.areaLabel),
      if (listing.floor.isNotEmpty) (Iconsax.layer_copy, 'Floor ${listing.floor}'),
      if (listing.furnishing.isNotEmpty)
        (Iconsax.lamp_on_copy, Formatters.humanize(listing.furnishing)),
    ];

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
                child: SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(url: listing.coverImage),
                      // Bottom fade so the project logo reads on any photo
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x66000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _Badge(
                          text: badge ?? (listing.isRental ? 'For rent' : 'For sale'),
                          highlight: badge != null,
                        ),
                      ),
                      if (onSave != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _SaveButton(saved: isSaved, onTap: onSave!),
                        ),
                      if (listing.images.length > 1)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: _PhotoCount(count: listing.images.length),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            listing.priceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.title.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (listing.negotiable) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Negotiable',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (listing.projectName.isNotEmpty)
                      Text(
                        [listing.projectName, listing.builderName]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    if (listing.place.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.location_copy,
                            size: 13,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              listing.place,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (facts.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      // One line only, so cards in fixed-height carousels never overflow.
                      Row(
                        children: [
                          for (final (icon, text) in facts.take(2)) ...[
                            Flexible(child: _Fact(icon: icon, text: text)),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ],
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

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.highlight});

  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? AppColors.gold : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: highlight ? AppColors.textPrimary : AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saved, required this.onTap});

  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: saved ? AppColors.accentRose : Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: SizedBox.square(
          dimension: 34,
          child: Icon(
            Iconsax.heart_copy,
            size: 17,
            color: saved ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _PhotoCount extends StatelessWidget {
  const _PhotoCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Iconsax.gallery_copy, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
