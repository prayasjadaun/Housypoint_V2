import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/saved_controller.dart';
import '../../controllers/shell_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../models/listing/listing_model.dart';
import '../../router/app_routes.dart';
import '../../theme/app_assets.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/glass_bottom_nav.dart';
import '../../widgets/common/segmented_toggle.dart';
import '../listings/widgets/property_card.dart';

/// Saved tab — wishlist ("Saved") and properties the user asked about
/// ("Contacted"). API ref S1/S3.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedController>();
    final top = MediaQuery.paddingOf(context).top;
    final bottom = GlassBottomNav.totalHeight(context);
    final items = _tab == 0 ? saved.saved : saved.contacted;

    return RefreshIndicatorWrapper(
      edgeOffset: top,
      onRefresh: saved.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, top + AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: SegmentedToggle(
                labels: [
                  'Saved${saved.saved.isEmpty ? '' : ' · ${saved.saved.length}'}',
                  'Contacted${saved.contacted.isEmpty ? '' : ' · ${saved.contacted.length}'}',
                ],
                icons: const [Iconsax.heart_copy, Iconsax.call_calling_copy],
                selectedIndex: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
          ),
          if (saved.isLoading && items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: AppSpinner()),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottom),
                child: Center(
                  child: saved.error != null
                      ? EmptyState(
                          lottie: AppAssets.lottieServerError,
                          title: 'Couldn’t load',
                          message: saved.error!,
                          actionLabel: 'Try again',
                          onAction: saved.refresh,
                        )
                      : _tab == 0
                      ? EmptyState(
                          icon: Iconsax.heart_copy,
                          title: 'No saved properties yet',
                          message: 'Tap the heart on any property to keep it here.',
                          actionLabel: 'Browse properties',
                          onAction: () => context.read<ShellController>().go(ShellTab.listings),
                        )
                      : const EmptyState(
                          icon: Iconsax.call_calling_copy,
                          title: 'No enquiries yet',
                          message: 'Properties you show interest in will appear here.',
                        ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, bottom + AppSpacing.md),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, i) => _card(context, saved, items[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, SavedController saved, ListingModel l) {
    return PropertyCard(
      listing: l,
      imageHeight: 180,
      badge: _tab == 1 ? 'Contacted' : null,
      isSaved: saved.savedState(l),
      onSave: () async {
        final error = await saved.toggleSave(l);
        if (error != null && context.mounted) context.showSnackBar(error, isError: true);
      },
      onTap: () => context.push(AppRoutes.listingPath(l.id, rental: l.isRental), extra: l),
    );
  }
}
