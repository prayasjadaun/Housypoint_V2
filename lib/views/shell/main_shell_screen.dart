import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
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
  int _index = 0;

  static const _tabs = [
    _Tab('Home', Iconsax.home_2_copy),
    _Tab('Listings', Iconsax.buildings_copy),
    _Tab('Saved', Iconsax.heart_copy),
    _Tab('Refer', Iconsax.gift_copy),
    _Tab('Profile', Iconsax.user_copy),
    _Tab('Menu', Iconsax.category_copy),
  ];

  void _select(int index) => setState(() => _index = index);

  GlassAppBar _appBar() {
    if (_index == 0) {
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
      title: Text(_tabs[_index].label, style: AppTextStyles.heading.copyWith(fontSize: 20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: GlassAppBar.overlay(
        appBar: _appBar(),
        body: IndexedStack(
          index: _index,
          children: [
            const HomeScreen(),
            const ListingsScreen(),
            const SavedScreen(),
            const ReferralScreen(),
            const ProfileScreen(),
            MenuScreen(onTabChangeRequest: _select),
          ],
        ),
      ),
      bottomNavigationBar: GlassBottomNav(
        items: [
          for (var i = 0; i < _tabs.length; i++)
            GlassNavItem(
              icon: _tabs[i].icon,
              label: _tabs[i].label,
              selected: i == _index,
              onTap: () => _select(i),
            ),
        ],
      ),
    );
  }
}
