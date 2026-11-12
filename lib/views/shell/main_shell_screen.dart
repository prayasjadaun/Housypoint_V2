import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/shell_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/glass_app_bar.dart';
import '../home/home_screen.dart';
import '../home/widgets/shell_bottom_nav.dart';
import '../listings/listings_screen.dart';
import '../menu/menu_screen.dart';
import '../referral/referral_screen.dart';
import '../saved/saved_screen.dart';

/// Logged-in home: glass app bar on top, 5-tab glass bottom nav below,
/// tabs kept alive in an IndexedStack. Profile opens from Menu as its own page.
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  GlassAppBar _appBar(BuildContext context, ShellTab tab) {
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
                Text('Find your next home', style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
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
      title: Text(ShellBottomNav.tabs[tab]!.label, style: AppTextStyles.heading.copyWith(fontSize: 20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<ShellController>().tab;

    return Scaffold(
      extendBody: true,
      body: GlassAppBar.overlay(
        appBar: _appBar(context, tab),
        body: IndexedStack(
          index: tab.index,
          children: const [
            HomeScreen(),
            ListingsScreen(),
            SavedScreen(),
            ReferralScreen(),
            MenuScreen(),
          ],
        ),
      ),
      bottomNavigationBar: const ShellBottomNav(),
    );
  }
}
