import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import 'glass_app_bar.dart';

/// Inner (pushed) screen: glass app bar with a back arrow, content
/// scrolling under it (so the glass has something to blur).
///
/// Start [body]'s scroll padding at [PageScaffold.topInset] — status bar +
/// bar height — so nothing is hidden behind the bar. Plain
/// `MediaQuery.paddingOf(context).top` read from the screen's own context
/// does NOT include the bar (that context sits above this Scaffold).
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottomBar,
    this.extendBody = false,
    this.backgroundColor,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomBar;

  /// Body scrolls under [bottomBar] — needed for the floating glass nav.
  final bool extendBody;
  final Color? backgroundColor;

  /// Top padding for content under the glass app bar.
  static double topInset(BuildContext context) =>
      MediaQuery.paddingOf(context).top + kToolbarHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      extendBodyBehindAppBar: true,
      extendBody: extendBody,
      appBar: GlassAppBar(
        centerTitle: true,
        title: Text(title),
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : null,
          icon: Icon(CupertinoIcons.back, color: AppColors.textPrimary),
        ),
        actions: actions,
      ),
      body: body,
      // Scaffold leaves bottomNavigationBar under the keyboard; lift it so
      // action buttons (Save, Next…) stay reachable while typing.
      bottomNavigationBar: bottomBar == null
          ? null
          : Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: bottomBar,
            ),
    );
  }
}
