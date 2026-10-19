import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/saved_controller.dart';
import '../../controllers/shell_controller.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/glass_app_bar.dart';
import '../../widgets/common/glass_bottom_nav.dart';
import '../home/home_screen.dart';
import '../listings/listings_screen.dart';
import '../menu/menu_screen.dart';
import '../profile/profile_screen.dart';
import '../referral/referral_screen.dart';
import '../saved/saved_screen.dart';

class _Tab {
  const _Tab(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Logged-in home: glass app bar on top, 6-tab glass bottom nav below,
/// tabs kept alive in an IndexedStack.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  static const _tabs = {
    ShellTab.home: _Tab('Home', Iconsax.home_2_copy),
    ShellTab.listings: _Tab('Listings', Iconsax.buildings_copy),
    ShellTab.saved: _Tab('Saved', Iconsax.heart_copy),
    ShellTab.refer: _Tab('Refer', Iconsax.gift_copy),
    ShellTab.profile: _Tab('Profile', Iconsax.user_copy),
    ShellTab.menu: _Tab('Menu', Iconsax.category_copy),
  };

  @override
  void initState() {
    super.initState();
    // Saved hearts on every card need the wishlist from the start.
    final userId = context.read<AuthController>().user?.id;
    if (userId != null && userId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<SavedController>().load(userId),
      );
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
        _tabs[tab]!.label,
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
      ShellTab.profile: const ProfileScreen(),
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
      bottomNavigationBar: GlassBottomNav(
        items: [
          for (final tab in ShellTab.values)
            GlassNavItem(
              icon: _tabs[tab]!.icon,
              label: _tabs[tab]!.label,
              selected: tab == current,
              onTap: () => shell.go(tab),
            ),
        ],
      ),
    );
  }
}
