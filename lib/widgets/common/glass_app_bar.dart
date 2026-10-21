import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Frosted-glass AppBar (same as Inlobo) — use it in place of `AppBar`:
///
/// ```dart
/// Scaffold(
///   extendBodyBehindAppBar: true, // content scrolls behind the blur
///   appBar: GlassAppBar(title: Text('Saved')),
///   body: ListView(...),
/// )
/// ```
///
/// Inside the tab shell use [GlassAppBar.overlay] instead — it stacks the bar
/// on top of the body and adds the bar height to `MediaQuery.padding.top`,
/// so a ListView with null padding starts below the bar automatically.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle,
    this.automaticallyImplyLeading = true,
    this.showBorder = true,
    this.titleSpacing,
    this.toolbarHeight,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool? centerTitle;
  final bool automaticallyImplyLeading;
  final bool showBorder;
  final double? titleSpacing;
  final double? toolbarHeight;

  static Widget overlay({required GlassAppBar? appBar, required Widget body}) {
    // Same tree whether appBar is null or not, so toggling it never remounts
    // the body (which would reset every tab of an IndexedStack).
    return Builder(
      builder: (context) {
        final mq = MediaQuery.of(context);
        final barHeight = appBar?.preferredSize.height ?? 0;
        return Stack(
          children: [
            MediaQuery(
              data: mq.copyWith(
                padding: mq.padding.copyWith(top: mq.padding.top + barHeight),
              ),
              child: body,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: appBar == null ? 0 : mq.padding.top + barHeight,
              child: appBar ?? const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    (toolbarHeight ?? kToolbarHeight) + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    // Blur wraps the AppBar — a BackdropFilter inside flexibleSpace blurs nothing.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.72),
            border: showBorder
                ? Border(
                    bottom: BorderSide(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  )
                : null,
          ),
          child: AppBar(
            title: title,
            leading: leading,
            actions: actions,
            bottom: bottom,
            centerTitle: centerTitle,
            automaticallyImplyLeading: automaticallyImplyLeading,
            titleSpacing: titleSpacing,
            toolbarHeight: toolbarHeight,
            titleTextStyle: AppTextStyles.title,
            foregroundColor: AppColors.textPrimary,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: AppColors.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          ),
        ),
      ),
    );
  }
}
