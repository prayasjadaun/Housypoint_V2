import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

import '../../core/utils/app_haptics.dart';
import '../../theme/app_colors.dart';
import 'glass_bottom_nav.dart';

/// iOS 26+ only: asli UIKit Liquid Glass tab bar. Baaki platforms par host
/// apna GlassBottomNav hi dikhata hai. Tabs wahi [GlassNavItem] list hai.
///
/// Items ki list runtime par mat badlo — package purane bar ko pehle
/// setSelectedIndex bhejta hai, pill galat tab par kood jaata hai. Alag tabs
/// chahiye to alag route me apna NativeTabScaffold do.
class NativeTabScaffold extends StatefulWidget {
  const NativeTabScaffold({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.body,
  });

  final List<GlassNavItem> items;
  // Native bar me hamesha ek tab selected rehta hai
  final int selectedIndex;
  final Widget body;

  @override
  State<NativeTabScaffold> createState() => _NativeTabScaffoldState();
}

class _NativeTabScaffoldState extends State<NativeTabScaffold> {
  void _onTap(int index) {
    AppHaptics.selection();
    widget.items[index].onTap();
    // Jis tap par index nahi badalta, iOS phir bhi use select kar deta hai —
    // rebuild par package selection wapas selectedIndex par le aata hai
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final dark = AppColors.isDark;
    final bottom = mq.viewPadding.bottom + GlassBottomNav.nativeBarHeight;
    return MediaQuery(
      // Bar system brightness padhta hai; app ka apna light/dark follow karwao
      data: mq.copyWith(
        platformBrightness: dark ? Brightness.dark : Brightness.light,
      ),
      child: AdaptiveScaffold(
        minimizeBehavior: TabBarMinimizeBehavior.never,
        // Bar body ke upar baithta hai par padding nahi deta — khud jodte hain
        // (SafeArea ke liye). viewPadding jaan-boojh ke asli: tabs
        // GlassBottomNav.totalHeight() usi se nikalte hain, warna bar double judta
        body: MediaQuery(
          data: mq.copyWith(padding: mq.padding.copyWith(bottom: bottom)),
          child: widget.body,
        ),
        bottomNavigationBar: AdaptiveBottomNavigationBar(
          useNativeBottomBar: true,
          items: [
            for (final item in widget.items)
              AdaptiveNavigationDestination(
                icon: AssetImage(item.nativeIconAsset!),
                selectedIcon: item.nativeSelectedIconAsset == null
                    ? null
                    : AssetImage(item.nativeSelectedIconAsset!),
                label: item.label,
              ),
          ],
          selectedIndex: widget.selectedIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: dark ? Colors.white : Colors.black,
          onTap: _onTap,
        ),
      ),
    );
  }
}
