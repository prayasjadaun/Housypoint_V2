import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/referral_controller.dart';
import '../../theme/app_assets.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/glass_bottom_nav.dart';
import '../../widgets/common/segmented_toggle.dart';
import 'widgets/earnings_view.dart';
import 'widgets/referral_overview.dart';
import 'widgets/referred_users_view.dart';

/// Refer & Earn tab — Overview / Referrals / Earnings (API ref R2–R7).
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ReferralController>().ensureLoaded(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReferralController>();
    final top = MediaQuery.paddingOf(context).top;
    final bottom = GlassBottomNav.totalHeight(context);
    final stats = c.stats;

    Widget body;
    if (stats == null) {
      body = c.isLoading || c.error == null
          ? const Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(child: AppSpinner()),
            )
          : EmptyState(
              lottie: AppAssets.lottieServerError,
              title: 'Couldn’t load your rewards',
              message: c.error!,
              actionLabel: 'Try again',
              onAction: c.load,
            );
    } else {
      body = switch (_tab) {
        0 => ReferralOverview(stats: stats, pdiStats: stats.pdi ?? c.pdiStats),
        1 => ReferredUsersView(users: c.referredUsers),
        _ => EarningsView(stats: stats, earnings: c.earnings, withdrawals: c.withdrawals),
      };
    }

    return RefreshIndicatorWrapper(
      edgeOffset: top,
      onRefresh: c.load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.md, top + AppSpacing.sm, AppSpacing.md, bottom + AppSpacing.lg),
        children: [
          SegmentedToggle(
            labels: const ['Overview', 'Referrals', 'Earnings'],
            icons: const [Iconsax.gift_copy, Iconsax.profile_2user_copy, Iconsax.wallet_money_copy],
            selectedIndex: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: KeyedSubtree(key: ValueKey(_tab), child: body)),
        ],
      ),
    );
  }
}
