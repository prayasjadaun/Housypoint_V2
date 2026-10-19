import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/listing/listing_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_network_image.dart';

/// Full-bleed listing card: the photo fills the card, details sit on a
/// dark fade at the bottom. Used in carousels and lists.
class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.onSave,
    this.isSaved = false,
    this.badge,
    this.height,
  });

  final ListingModel listing;
  final VoidCallback onTap;

  /// Null hides the save button.
  final VoidCallback? onSave;
  final bool isSaved;

  /// Label on the photo, e.g. "Hot deal" (gold); defaults to For sale / For rent.
  final String? badge;

  /// Fixed height in lists; null fills the parent (carousels).
  final double? height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl + 4);
    final facts = [
      if (listing.areaLabel.isNotEmpty) (Iconsax.maximize_4_copy, listing.areaLabel),
      if (listing.floor.isNotEmpty) (Iconsax.layer_copy, 'Floor ${listing.floor}'),
      if (listing.furnishing.isNotEmpty) (Iconsax.lamp_on_copy, Formatters.humanize(listing.furnishing)),
    ];
    final subtitle = [listing.projectName, listing.builderName].where((s) => s.isNotEmpty).join(' · ');

    final card = Material(
      color: AppColors.textPrimary,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(url: listing.coverImage),
            // Light at the top for the chips, deep at the bottom for the text
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.22, 0.45, 1],
                  colors: [Color(0x40000000), Colors.transparent, Color(0x1A000000), Color(0xE6000000)],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 60,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _GlassPill(
                    text: badge ?? (listing.isRental ? 'For rent' : 'For sale'),
                    gold: badge != null,
                    icon: badge != null ? Iconsax.flash_1_copy : null,
                  ),
                  if (listing.images.length > 1)
                    _GlassPill(text: '${listing.images.length}', icon: Iconsax.gallery_copy),
                ],
              ),
            ),
            if (onSave != null)
              Positioned(top: 10, right: 10, child: _SaveButton(saved: isSaved, onTap: onSave!)),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          listing.priceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.heading.copyWith(color: Colors.white, fontSize: 21, height: 1.2),
                        ),
                      ),
                      if (listing.negotiable) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'Negotiable',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
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
                    style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.78)),
                    ),
                  if (listing.place.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Iconsax.location_copy, size: 13, color: Colors.white.withValues(alpha: 0.78)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (facts.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    // One line only, so fixed-height cards never overflow.
                    Row(
                      children: [
                        for (final (icon, text) in facts.take(3)) ...[
                          Flexible(child: _GlassPill(text: text, icon: icon, small: true)),
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
    );

    return height == null ? card : SizedBox(height: height, child: card);
  }
}

/// Translucent pill that reads on any photo.
class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.text, this.icon, this.gold = false, this.small = false});

  final String text;
  final IconData? icon;
  final bool gold;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final color = gold ? AppColors.textPrimary : Colors.white;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 4 : 5),
      decoration: BoxDecoration(
        color: gold ? AppColors.gold : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: gold ? null : Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? 11 : 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                fontSize: small ? 10.5 : 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
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
      color: saved ? AppColors.accentRose : Colors.white.withValues(alpha: 0.18),
      shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: saved ? 0 : 0.3))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: const SizedBox.square(
          dimension: 38,
          child: Icon(Iconsax.heart_copy, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
