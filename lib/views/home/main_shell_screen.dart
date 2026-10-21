import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/listings_controller.dart';
import '../../controllers/referral_controller.dart';
import '../../controllers/saved_controller.dart';
import '../../controllers/shell_controller.dart';
import '../../core/network/connectivity_service.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/glass_app_bar.dart';
import 'home_screen.dart';
import 'widgets/shell_bottom_nav.dart';
import '../listings/listings_screen.dart';
import '../menu/menu_screen.dart';
import '../referral/referral_screen.dart';
import '../saved/saved_screen.dart';

/// Logged-in home: glass app bar on top, 5-tab glass bottom nav below,
/// tabs kept alive in an IndexedStack.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late final ConnectivityService _connectivity;
  late bool _wasOnline;

  @override
  void initState() {
    super.initState();
    _connectivity = context.read<ConnectivityService>()
      ..addListener(_onConnectivityChanged);
    _wasOnline = _connectivity.isOnline;
    // Saved hearts on every card need the wishlist from the start.
    final userId = context.read<AuthController>().user?.id;
    if (userId != null && userId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<SavedController>().load(userId),
      );
    }
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  /// Back online → reload the visible tab so the user doesn't have to
  /// pull-to-refresh after a dropped connection.
  void _onConnectivityChanged() {
    final online = _connectivity.isOnline;
    final reconnected = online && !_wasOnline;
    _wasOnline = online;
    if (!reconnected) return;

    switch (context.read<ShellController>().tab) {
      case ShellTab.home:
        context.read<HomeController>().refresh();
      case ShellTab.listings:
        final listings = context.read<ListingsController>();
        if (listings.error != null) listings.load();
      case ShellTab.saved:
        context.read<SavedController>().refresh();
      case ShellTab.refer:
        final referral = context.read<ReferralController>();
        if (referral.error != null) referral.load();
      case ShellTab.menu:
        break;
    }
  }

  GlassAppBar _appBar(ShellTab tab) {
    if (tab == ShellTab.home) {
      final name = context.watch<AuthController>().user?.firstName ?? '';
      return GlassAppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const AppLogo(size: 36),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Hello 👋' : 'Hi, $name 👋',
                  style: AppTextStyles.title.copyWith(fontSize: 16),
                ),
                Text('Welcome to Housy Point', style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.notifications),
            icon: const Icon(Iconsax.notification_copy, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 6),
        ],
      );
    }
    return GlassAppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 20,
      title: Text(
        ShellBottomNav.tabs[tab]!.label,
        style: AppTextStyles.heading.copyWith(fontSize: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    final current = shell.tab;

    final pages = {
      ShellTab.home: const HomeScreen(),
      ShellTab.listings: const ListingsScreen(),
      ShellTab.saved: const SavedScreen(),
      ShellTab.refer: const ReferralScreen(),
      ShellTab.menu: const MenuScreen(),
    };

    return Scaffold(
      extendBody: true,
      body: GlassAppBar.overlay(
        appBar: _appBar(current),
        body: IndexedStack(
          index: current.index,
          children: [
            for (final tab in ShellTab.values)
              // Hidden tabs keep their state but pause their animations.
              TickerMode(enabled: tab == current, child: pages[tab]!),
          ],
        ),
      ),
      bottomNavigationBar: const ShellBottomNav(),
    );
  }
}
