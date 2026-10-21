import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/utils/app_haptics.dart';
import '../../theme/app_colors.dart';

class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Iconsax linear icon.
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
}

/// Floating frosted-glass pill nav (same as Inlobo's GlassBottomNav).
/// The selected tab grows to show its label; a tinted pill slides under it.
/// Host Scaffold must set `extendBody: true` so content blurs behind it.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({super.key, required this.items});

  final List<GlassNavItem> items;

  static const double _pillHeight = 60;
  static const _slide = Duration(milliseconds: 380);
  static const double _iconSize = 22;
  static const double _gap = 6;
  static const double _pillHPad = 12;
  static const _labelStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static double _measureLabel(BuildContext context, String text) =>
      (TextPainter(
        text: TextSpan(
          text: text,
          style: DefaultTextStyle.of(context).style.merge(_labelStyle),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout()).width;

  static double _bottomMargin(BuildContext context) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    return isAndroid ? MediaQuery.paddingOf(context).bottom + 6 : 16;
  }

  /// Space the nav takes from the screen bottom — lists add this as bottom padding.
  static double totalHeight(BuildContext context) =>
      _pillHeight + _bottomMargin(context);

  @override
  Widget build(BuildContext context) {
    final selectedIndex = items.indexWhere((i) => i.selected);
    final dark = AppColors.isDark;
    final radius = BorderRadius.circular(_pillHeight / 2);

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, _bottomMargin(context)),
      // Shadow stays outside ClipRRect, otherwise it gets clipped
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.4 : 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: _pillHeight,
              padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
              decoration: BoxDecoration(
                borderRadius: radius,
                // Low-alpha tint — the heavy blur does the frosting
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: dark
                      ? [
                          const Color(0xFF23272A).withValues(alpha: 0.72),
                          const Color(0xFF16191B).withValues(alpha: 0.66),
                        ]
                      : [
                          const Color(0xFFF4F6F8).withValues(alpha: 0.55),
                          const Color(0xFFE9EDF1).withValues(alpha: 0.45),
                        ],
                ),
                border: Border.all(
                  width: 0.8,
                  color: Colors.white.withValues(alpha: dark ? 0.1 : 0.6),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, c) =>
                    _buildTabs(context, c.maxWidth, selectedIndex),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Selected tab is wider (icon + label), the rest show only the icon.
  /// Pill and tabs share duration/curve, so they slide and resize together.
  Widget _buildTabs(BuildContext context, double width, int selectedIndex) {
    final n = items.length;
    final hasSelection = selectedIndex >= 0;
    final selectedW = hasSelection && n > 1
        ? _iconSize +
              _gap +
              _measureLabel(context, items[selectedIndex].label).ceilToDouble() +
              1 +
              _pillHPad * 2
        : width / n;
    final otherW = hasSelection && n > 1 ? (width - selectedW) / (n - 1) : width / n;
    double widthOf(int i) => i == selectedIndex ? selectedW : otherW;

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedPositioned(
          duration: _slide,
          curve: Curves.easeOutCubic,
          top: 4,
          bottom: 4,
          left: hasSelection ? selectedIndex * otherW : 0,
          width: selectedW,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: hasSelection ? 1 : 0,
            child: _buildPill(),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < n; i++)
              AnimatedContainer(
                duration: _slide,
                curve: Curves.easeOutCubic,
                width: widthOf(i),
                child: _buildItem(items[i]),
              ),
          ],
        ),
      ],
    );
  }

  // Translucent brand-tinted pill — reads as glass on the blurred bar
  Widget _buildPill() {
    final dark = AppColors.isDark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_pillHeight / 2),
        color: dark
            ? AppColors.mainGreen.withValues(alpha: 0.16)
            : Color.alphaBlend(
                AppColors.primary.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.45),
              ),
        border: Border.all(
          width: 0.8,
          color: dark ? AppColors.mainGreen.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildItem(GlassNavItem item) {
    // Brighter green on dark — primary is too low-contrast on the dark bar.
    final selectedColor = AppColors.isDark ? AppColors.mainGreen : AppColors.primary;
    // Unselected icons near-white on dark so they don't wash out to grey.
    final idleColor = AppColors.isDark ? AppColors.textPrimary.withValues(alpha: 0.85) : AppColors.textSecondary;
    final color = item.selected ? selectedColor : idleColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppHaptics.selection();
        item.onTap();
      },
      child: TweenAnimationBuilder<Color?>(
        duration: _slide,
        curve: Curves.easeOutCubic,
        tween: ColorTween(end: color),
        builder: (context, c, _) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: _iconSize, color: c ?? color),
            if (item.selected) ...[
              const SizedBox(width: _gap),
              // Clip the label while width animates, so it doesn't overflow
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  textScaler: TextScaler.noScaling,
                  style: _labelStyle.copyWith(color: c ?? color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
