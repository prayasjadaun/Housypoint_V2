import 'package:flutter/material.dart';

import '../../core/utils/app_haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

/// iOS-style segmented control: a white pill slides under the selected label.
class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.icons,
    this.height = 44,
  });

  final List<String> labels;

  /// Optional Iconsax line icon per label.
  final List<IconData>? icons;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// 44 by default; ~36 for a compact inline toggle.
  final double height;

  static const double _inset = 4;

  @override
  Widget build(BuildContext context) {
    final n = labels.length;

    return Container(
      height: height,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * selectedIndex / (n - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md - 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (i == selectedIndex) return;
                      AppHaptics.selection();
                      onChanged(i);
                    },
                    child: _label(i),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(int i) {
    final selected = i == selectedIndex;
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icons != null) ...[
            Icon(icons![i], size: 16, color: color),
            const SizedBox(width: 6),
          ],
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTextStyles.label.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
            child: Text(labels[i]),
          ),
        ],
      ),
    );
  }
}
