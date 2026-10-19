import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../repositories/my_listings_repository.dart';
import '../../router/app_routes.dart';
import '../../theme/app_assets.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/page_scaffold.dart';
import '../../widgets/common/segmented_toggle.dart';
import '../listings/widgets/property_card.dart';

/// Properties the user posted for sale / rent (API ref W10).
class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  MyListings? _data;
  String? _error;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await context.read<MyListingsRepository>().get();
      if (mounted) setState(() => _data = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = PageScaffold.topInset(context);
    final data = _data;
    final items = data == null ? null : (_tab == 0 ? data.forSale : data.forRent);

    return PageScaffold(
      title: 'My listings',
      body: RefreshIndicatorWrapper(
        edgeOffset: top,
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.md, top + AppSpacing.md, AppSpacing.md, AppSpacing.xl),
          children: [
            SegmentedToggle(
              labels: [
                'For sale${data == null ? '' : ' · ${data.forSale.length}'}',
                'For rent${data == null ? '' : ' · ${data.forRent.length}'}',
              ],
              icons: const [Iconsax.key_copy, Iconsax.home_hashtag_copy],
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: AppSpacing.md),
            if (items == null && _error == null)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: AppSpinner()),
              )
            else if (_error != null)
              EmptyState(
                lottie: AppAssets.lottieServerError,
                title: 'Couldn’t load your listings',
                message: _error!,
                actionLabel: 'Try again',
                onAction: _load,
              )
            else if (items!.isEmpty)
              EmptyState(
                icon: Iconsax.document_text_copy,
                title: _tab == 0 ? 'Nothing listed for sale' : 'Nothing listed for rent',
                message: 'Post your property for free and reach verified buyers and tenants.',
              )
            else
              for (final l in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: PropertyCard(
                    listing: l,
                    imageHeight: 170,
                    onTap: () => context.push(AppRoutes.listingPath(l.id, rental: l.isRental), extra: l),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
