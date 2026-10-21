import 'dart:math' as math;

import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Like a pinned `SliverPersistentHeader`, but sticks [pinTop] px below the
/// viewport top — i.e. just under a glass app bar the list scrolls behind
/// (a plain pinned header would stick *behind* that bar).
///
/// Content scrolls underneath it, so give [child] an opaque background.
class SliverPinnedBox extends SingleChildRenderObjectWidget {
  const SliverPinnedBox({super.key, required this.pinTop, required Widget super.child});

  final double pinTop;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderSliverPinnedBox(pinTop);

  @override
  void updateRenderObject(BuildContext context, covariant RenderSliverPinnedBox renderObject) {
    renderObject.pinTop = pinTop;
  }
}

class RenderSliverPinnedBox extends RenderSliverSingleBoxAdapter {
  RenderSliverPinnedBox(this._pinTop);

  double _pinTop;
  set pinTop(double value) {
    if (value == _pinTop) return;
    _pinTop = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final c = constraints;
    child!.layout(c.asBoxConstraints(), parentUsesSize: true);
    final extent = child!.size.height;

    // Where the box would naturally sit, measured from the viewport top
    // (negative once it has scrolled past).
    final natural = c.scrollOffset > 0 ? -c.scrollOffset : c.viewportMainAxisExtent - c.remainingPaintExtent;
    // The viewport places the sliver at max(natural, 0); shift the paint
    // down from there so it never goes above [pinTop].
    final paintOrigin = math.max(natural, _pinTop) - math.max(natural, 0.0);
    final paintExtent = math.min(extent, c.remainingPaintExtent);
    final layoutExtent = clampDouble(extent - c.scrollOffset, 0, paintExtent);

    (child!.parentData! as SliverPhysicalParentData).paintOffset = Offset.zero;
    geometry = SliverGeometry(
      scrollExtent: extent,
      paintOrigin: paintOrigin,
      paintExtent: paintExtent,
      layoutExtent: layoutExtent,
      maxPaintExtent: extent,
      maxScrollObstructionExtent: extent,
      cacheExtent: layoutExtent > 0 ? -c.cacheOrigin + layoutExtent : layoutExtent,
      hasVisualOverflow: true,
    );
  }

  @override
  double childMainAxisPosition(RenderBox child) => 0;
}
