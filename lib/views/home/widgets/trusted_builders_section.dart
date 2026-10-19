import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/home_controller.dart';
import '../../../models/master/builder_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../widgets/common/app_network_image.dart';
import '../../../widgets/common/section_header.dart';

/// "Trusted developers" — builder logos gliding past in an endless strip.
class TrustedBuildersSection extends StatelessWidget {
  const TrustedBuildersSection({super.key, this.onViewAll, this.onTapBuilder});

  final VoidCallback? onViewAll;
  final ValueChanged<BuilderModel>? onTapBuilder;

  @override
  Widget build(BuildContext context) {
    final builders = context.select<HomeController, List<BuilderModel>?>((h) => h.topBuilders);
    if (builders == null || builders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Trusted developers',
          subtitle: 'Projects from India’s leading builders',
          onAction: onViewAll,
        ),
        const SizedBox(height: 12),
        _Marquee(builders: builders, onTap: onTapBuilder),
      ],
    );
  }
}

class _Marquee extends StatefulWidget {
  const _Marquee({required this.builders, this.onTap});

  final List<BuilderModel> builders;
  final ValueChanged<BuilderModel>? onTap;

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee> with SingleTickerProviderStateMixin {
  static const double _tile = 84;
  static const double _gap = 12;

  late final AnimationController _scroll = AnimationController(
    vsync: this,
    // ~30 px per second, whatever the number of logos
    duration: Duration(milliseconds: (widget.builders.length * (_tile + _gap) / 30 * 1000).round()),
  )..repeat();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stripWidth = widget.builders.length * (_tile + _gap);

    return SizedBox(
      height: _tile,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _scroll,
          builder: (context, child) => OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: double.infinity,
            child: Transform.translate(
              offset: Offset(-_scroll.value * stripWidth, 0),
              child: child,
            ),
          ),
          // Two copies back to back, so the loop has no visible seam.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var copy = 0; copy < 2; copy++)
                for (final b in widget.builders)
                  Padding(
                    padding: const EdgeInsets.only(right: _gap),
                    child: GestureDetector(
                      onTap: widget.onTap == null ? null : () => widget.onTap!(b),
                      child: Container(
                        width: _tile,
                        height: _tile,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
                        ),
                        child: AppNetworkImage(url: b.logoUrl, fit: BoxFit.contain),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
