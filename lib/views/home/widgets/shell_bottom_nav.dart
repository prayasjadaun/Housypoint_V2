import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../controllers/shell_controller.dart';
import '../../../widgets/common/glass_bottom_nav.dart';

class ShellTabInfo {
  const ShellTabInfo(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// The main shell's glass nav. Also shown on pages pushed from a tab
/// (e.g. Profile) — pass [onTap] there to pop back before switching tabs.
class ShellBottomNav extends StatelessWidget {
  const ShellBottomNav({super.key, this.selected, this.onTap});

  /// Highlighted tab; defaults to the shell's current tab.
  final ShellTab? selected;
  final ValueChanged<ShellTab>? onTap;

  static const tabs = {
    ShellTab.home: ShellTabInfo('Home', Iconsax.home_2_copy),
    ShellTab.listings: ShellTabInfo('Listings', Iconsax.buildings_copy),
    ShellTab.saved: ShellTabInfo('Saved', Iconsax.heart_copy),
    ShellTab.refer: ShellTabInfo('Refer', Iconsax.gift_copy),
    ShellTab.menu: ShellTabInfo('Menu', Iconsax.category_copy),
  };

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    final current = selected ?? shell.tab;

    return GlassBottomNav(
      items: [
        for (final tab in ShellTab.values)
          GlassNavItem(
            icon: tabs[tab]!.icon,
            label: tabs[tab]!.label,
            selected: tab == current,
            onTap: () => onTap != null ? onTap!(tab) : shell.go(tab),
          ),
      ],
    );
  }
}
