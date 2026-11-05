import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show PlatformInfo;
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../controllers/shell_controller.dart';
import '../../../widgets/common/glass_bottom_nav.dart';
import '../../../widgets/common/native_tab_scaffold.dart';

class ShellTabInfo {
  const ShellTabInfo(this.label, this.icon, this.asset);
  final String label;
  final IconData icon;

  /// assets/nav/ PNG name for the iOS 26 native bar (`<asset>_filled` = selected).
  final String asset;
}

/// The main shell's glass nav. Also shown on pages pushed from a tab
/// (e.g. Profile) — pass [onTap] there to pop back before switching tabs.
class ShellBottomNav extends StatelessWidget {
  const ShellBottomNav({super.key, this.selected, this.onTap});

  /// Highlighted tab; defaults to the shell's current tab.
  final ShellTab? selected;
  final ValueChanged<ShellTab>? onTap;

  static const tabs = {
    ShellTab.home: ShellTabInfo('Home', Iconsax.home_2_copy, 'home'),
    ShellTab.listings: ShellTabInfo(
      'Listings',
      Iconsax.buildings_copy,
      'listings',
    ),
    ShellTab.saved: ShellTabInfo('Saved', Iconsax.heart_copy, 'saved'),
    ShellTab.refer: ShellTabInfo('Refer', Iconsax.gift_copy, 'refer'),
    ShellTab.menu: ShellTabInfo('Menu', Iconsax.category_copy, 'menu'),
  };

  /// iOS 26+: asli native tab bar — [scaffold] ka bottomNavigationBar null
  /// hona chahiye. Baaki platforms par [scaffold] waisa hi (GlassBottomNav ke saath).
  static bool get useNative => PlatformInfo.isIOS26OrHigher();

  static Widget wrap(
    BuildContext context,
    Widget scaffold, {
    ShellTab? selected,
    ValueChanged<ShellTab>? onTap,
  }) {
    if (!useNative) return scaffold;
    final current = selected ?? context.watch<ShellController>().tab;
    return NativeTabScaffold(
      items: _items(context, current, onTap),
      selectedIndex: current.index,
      body: scaffold,
    );
  }

  // Har jagah same 5 items — native bar ki list kabhi badalni nahi chahiye
  static List<GlassNavItem> _items(
    BuildContext context,
    ShellTab current,
    ValueChanged<ShellTab>? onTap,
  ) {
    final shell = context.read<ShellController>();
    return [
      for (final tab in ShellTab.values)
        GlassNavItem(
          icon: tabs[tab]!.icon,
          label: tabs[tab]!.label,
          selected: tab == current,
          onTap: () => onTap != null ? onTap(tab) : shell.go(tab),
          nativeIconAsset: 'assets/nav/${tabs[tab]!.asset}.png',
          nativeSelectedIconAsset: 'assets/nav/${tabs[tab]!.asset}_filled.png',
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    final current = selected ?? shell.tab;

    return GlassBottomNav(
      goldStyle: current == ShellTab.refer,
      items: _items(context, current, onTap),
    );
  }
}
