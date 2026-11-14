import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// App-wide scrollbar, set once in `MaterialApp.scrollBehavior` (app.dart).
/// Har vertical scrollable (ListView, CustomScrollView, SingleChildScrollView,
/// sheets…) ko khud [AppScrollbar] wala thumb mil jaata hai — screens ko kuch
/// wrap nahi karna. Horizontal lists aur PageView par scrollbar nahi aata.
///
/// Kisi subtree ka thumb color badalna ho (jaise Refer tab ka gold) to use
/// `ScrollConfiguration(behavior: AppScrollBehavior(color: …))` me wrap karo.
/// Kisi list par scrollbar nahi chahiye to:
/// `ScrollConfiguration(behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false))`.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior({this.color});

  /// Thumb color; defaults to the brand green.
  final Color? color;

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final controller = details.controller;
    if (axisDirectionToAxis(details.direction) != Axis.vertical ||
        controller == null) {
      return child;
    }
    return AppScrollbar.styled(
      controller: controller,
      color: color,
      child: child,
    );
  }

  @override
  bool shouldNotify(covariant AppScrollBehavior oldDelegate) =>
      oldDelegate.color != color;
}

/// Reusable scrollbar wrapper, for a scrollable that needs its own
/// [controller] handed to the scrollbar explicitly. Most screens don't need
/// this — [AppScrollBehavior] already adds the same scrollbar everywhere.
class AppScrollbar extends StatefulWidget {
  const AppScrollbar({
    super.key,
    required this.builder,
    this.controller,
    this.color,
    this.thickness = 2,
    this.radius = 12,
    this.alwaysVisible = true,
  });

  final Widget Function(ScrollController controller) builder;
  final ScrollController? controller;

  /// Thumb color; defaults to the brand green.
  final Color? color;
  final double thickness;
  final double radius;

  /// When false, the thumb/track only appear while actively scrolling
  /// (the Flutter default) instead of being permanently docked on the
  /// edge — better for sheets whose content barely overflows, where an
  /// always-visible thumb reads as a stray bar rather than a scrollbar.
  final bool alwaysVisible;

  /// The styled scrollbar itself, around an already-built [child].
  static Widget styled({
    required ScrollController controller,
    required Widget child,
    Color? color,
    double thickness = 2,
    double radius = 12,
    bool alwaysVisible = true,
  }) {
    // App ka apna light/dark (system brightness nahi)
    final isDark = AppColors.isDark;
    final thumb = color ?? AppColors.mainGreen;
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          thumb.withValues(alpha: isDark ? 0.6 : 0.5),
        ),
        trackColor: WidgetStateProperty.all(
          isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        trackVisibility: WidgetStateProperty.all(alwaysVisible),
        radius: Radius.circular(radius),
        thickness: WidgetStateProperty.all(thickness),
      ),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: alwaysVisible,
        thickness: thickness,
        radius: Radius.circular(radius),
        interactive: true,
        child: child,
      ),
    );
  }

  @override
  State<AppScrollbar> createState() => _AppScrollbarState();
}

class _AppScrollbarState extends State<AppScrollbar> {
  late final ScrollController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? ScrollController();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Iske andar wali list ko global scrollbar dobara na mile
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: AppScrollbar.styled(
        controller: _controller,
        color: widget.color,
        thickness: widget.thickness,
        radius: widget.radius,
        alwaysVisible: widget.alwaysVisible,
        child: widget.builder(_controller),
      ),
    );
  }
}
