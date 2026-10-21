import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/listings_controller.dart';
import '../../controllers/saved_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/app_haptics.dart';
import '../../models/listing/listing_counts.dart';
import '../../router/app_routes.dart';
import '../../theme/app_assets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/glass_bottom_nav.dart';
import '../../widgets/common/segmented_toggle.dart';
import '../../widgets/common/skeleton_box.dart';
import '../../widgets/pickers/location_pickers.dart';
import '../home/widgets/size_options.dart';
import 'widgets/property_card.dart';

/// Listings tab: resale/rent × residential/commercial × size filters,
/// infinite-scrolling cards.
class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListingsController>().ensureStarted(
        context.read<HomeController>().selectedCity,
      );
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.extentAfter < 600) context.read<ListingsController>().loadMore();
    return false;
  }

  Future<void> _pickCity(ListingsController c) async {
    AppHaptics.selection();
    final home = context.read<HomeController>();
    await home.ensureCities();
    if (!mounted) return;
    final result = await showCityPicker(context, cities: home.cities, selected: c.city);
    if (result.picked) c.setCity(result.value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ListingsController>();
    final saved = context.watch<SavedController>();
    final top = MediaQuery.paddingOf(context).top;
    final bottom = GlassBottomNav.totalHeight(context);

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: RefreshIndicatorWrapper(
        edgeOffset: top,
        onRefresh: c.load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, top + AppSpacing.sm, AppSpacing.md, 0),
              sliver: SliverToBoxAdapter(
                child: _Filters(controller: c, onPickCity: () => _pickCity(c)),
              ),
            ),
            if (c.isLoading)
              SliverList.separated(
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (_, _) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _CardSkeleton(),
                ),
              )
            else if (c.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottom),
                  child: Center(
                    child: c.error != null
                        ? EmptyState(
                            lottie: AppAssets.lottieServerError,
                            title: 'Something went wrong',
                            message: c.error!,
                            actionLabel: 'Try again',
                            onAction: c.load,
                          )
                        : c.query.isNotEmpty
                        ? EmptyState(
                            lottie: AppAssets.lottieNoResults,
                            title: 'No results for “${c.query}”',
                            message: 'Try another name, or change the filters above.',
                            actionLabel: 'Clear search',
                            onAction: c.closeSearch,
                          )
                        : EmptyState(
                            lottie: AppAssets.lottieNoResults,
                            title: 'No properties found',
                            message: 'Try another size, city or switch between resale and rent.',
                            actionLabel: c.sizeKey != null ? 'Show all sizes' : null,
                            onAction: c.sizeKey != null ? () => c.setSize(null) : null,
                          ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList.separated(
                  itemCount: c.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final l = c.items[i];
                    return PropertyCard(
                      listing: l,
                      height: 320,
                      isSaved: saved.savedState(l),
                      onSave: () async {
                        final error = await saved.toggleSave(l);
                        if (error != null && context.mounted) {
                          context.showSnackBar(error, isError: true);
                        }
                      },
                      onTap: () => context.push(
                        AppRoutes.listingPath(l.id, rental: l.isRental),
                        extra: l,
                      ),
                    );
                  },
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.md, bottom: bottom + AppSpacing.md),
                child: c.isLoadingMore
                    ? const Center(child: AppSpinner(size: 24))
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.controller, required this.onPickCity});

  final ListingsController controller;
  final VoidCallback onPickCity;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final sizes = c.category == PropertyCategory.residential ? residentialTiles : commercialTiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onPickCity,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    const Icon(Iconsax.location_copy, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        c.city ?? 'All cities',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Iconsax.arrow_down_1_copy, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            if (!c.isLoading)
              Text(
                '${c.total} ${c.total == 1 ? 'property' : 'properties'}',
                style: AppTextStyles.caption,
              ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedToggle(
          labels: const ['Resale', 'Rent'],
          icons: const [Iconsax.key_copy, Iconsax.home_hashtag_copy],
          selectedIndex: c.deal.index,
          onChanged: (i) => c.setDeal(DealType.values[i]),
        ),
        const SizedBox(height: 10),
        SegmentedToggle(
          labels: const ['Residential', 'Commercial'],
          icons: const [Iconsax.home_2_copy, Iconsax.building_4_copy],
          selectedIndex: c.category.index,
          onChanged: (i) => c.setCategory(PropertyCategory.values[i]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _SizeChip(label: 'All', selected: c.sizeKey == null, onTap: () => c.setSize(null)),
              for (final s in sizes)
                _SizeChip(
                  label: s.label,
                  icon: s.icon,
                  selected: c.sizeKey == s.key,
                  onTap: () => c.setSize(s.key),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: selected ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonBox(width: double.infinity, height: 320, radius: AppRadius.xl + 4);
  }
}
