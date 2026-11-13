import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../controllers/home_controller.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../models/project/project_model.dart';
import '../../../router/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_network_image.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/skeleton_box.dart';
import '../../listings/widgets/property_video.dart';

/// "New launches" — fresh projects in the selected city (API ref C5).
class NewLaunchesSection extends StatelessWidget {
  const NewLaunchesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = context.select<HomeController, List<ProjectSummary>?>(
      (h) => h.newLaunches,
    );
    if (projects != null && projects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'New launches',
          subtitle: 'Be the first to book in upcoming projects',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 270,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: projects?.length ?? 2,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => projects == null
                ? const SkeletonBox(
                    width: 230,
                    height: 270,
                    radius: AppRadius.xl,
                  )
                : LaunchCard(project: projects[i]),
          ),
        ),
      ],
    );
  }
}

/// Full-bleed project card: photo fills the card, details on a dark fade.
/// The top-right play button flips it over to the project video.
class LaunchCard extends StatelessWidget {
  const LaunchCard({super.key, required this.project});

  final ProjectSummary project;

  @override
  Widget build(BuildContext context) {
    final place = [
      project.builderName,
      project.city,
    ].where((s) => s.isNotEmpty).join(' · ');

    final radius = BorderRadius.circular(AppRadius.xl + 4);
    void open() {
      AppHaptics.tap();
      context.push(AppRoutes.projectPath(project.id));
    }

    return SizedBox(
      width: 230,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Bottom-right corner me curved notch — usme arrow button baithta hai
          ClipPath(
            clipper: const _NotchedCardClipper(
              radius: AppRadius.xl + 4,
              notch: _notchSize,
            ),
            child: VideoFlipCard(
              videoUrl: project.videoUrl,
              posterUrl: project.image,
              title: project.name,
              borderRadius: radius,
              frontBuilder: (context, flip) =>
                  _buildFront(context, radius, place, flip, open),
            ),
          ),
          Positioned(
            right: (_notchSize - _buttonSize) / 2,
            bottom: (_notchSize - _buttonSize) / 2,
            child: _NotchArrowButton(size: _buttonSize, onTap: open),
          ),
        ],
      ),
    );
  }

  static const double _notchSize = 60;
  static const double _buttonSize = 48;

  Widget _buildFront(
    BuildContext context,
    BorderRadius radius,
    String place,
    VoidCallback? flip,
    VoidCallback open,
  ) {
    return Material(
      color: AppColors.ink,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(url: project.image),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.25, 0.5, 1],
                  colors: [
                    Color(0x40000000),
                    Colors.transparent,
                    Color(0x1A000000),
                    Color(0xE6000000),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.flash_1_copy, size: 12, color: AppColors.ink),
                    const SizedBox(width: 4),
                    Text(
                      'New launch',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (flip != null || project.builderLogo.isNotEmpty)
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (flip != null) FlipToVideoButton(onTap: flip, size: 36),
                    if (flip != null && project.builderLogo.isNotEmpty)
                      const SizedBox(width: 8),
                    if (project.builderLogo.isNotEmpty)
                      Container(
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          // Always white — builder logos are made for a light background.
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: AppNetworkImage(
                          url: project.builderLogo,
                          fit: BoxFit.contain,
                        ),
                      ),
                  ],
                ),
              ),
            Positioned(
              left: 14,
              // Notch ke liye jagah chhodo
              right: _notchSize + 4,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    project.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title.copyWith(
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  if (place.isNotEmpty)
                    Text(
                      place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    project.priceRange.isEmpty
                        ? 'Price on request'
                        : '₹${project.priceRange}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded card jiske bottom-right corner se ek gol notch kata hai (andar se
/// circular, edges par smooth fillet) — button us notch me baithta hai.
class _NotchedCardClipper extends CustomClipper<Path> {
  const _NotchedCardClipper({required this.radius, required this.notch});

  final double radius;
  final double notch;

  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    final r = radius;
    final s = notch;
    final inner =
        s / 2; // notch ka andar wala curve — button ke saath concentric
    const fillet = 16.0; // notch jahan card edge se milta hai
    const k = 0.7071; // conic weight = circular arc

    return Path()
      ..moveTo(r, 0)
      ..lineTo(w - r, 0)
      ..conicTo(w, 0, w, r, k)
      ..lineTo(w, h - s - fillet)
      ..conicTo(w, h - s, w - fillet, h - s, k)
      ..lineTo(w - s + inner, h - s)
      ..conicTo(w - s, h - s, w - s, h - s + inner, k)
      ..lineTo(w - s, h - fillet)
      ..conicTo(w - s, h, w - s - fillet, h, k)
      ..lineTo(r, h)
      ..conicTo(0, h, 0, h - r, k)
      ..lineTo(0, r)
      ..conicTo(0, 0, r, 0, k)
      ..close();
  }

  @override
  bool shouldReclip(_NotchedCardClipper old) =>
      old.radius != radius || old.notch != notch;
}

/// Notch me baitha gol arrow button — soft green tint + green arrow (pehle
/// jaisa), bas halka border, soft shadow aur press par chhota sa scale.
class _NotchArrowButton extends StatefulWidget {
  const _NotchArrowButton({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  State<_NotchArrowButton> createState() => _NotchArrowButtonState();
}

class _NotchArrowButtonState extends State<_NotchArrowButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primarySoft,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.8)),
            // boxShadow: [
            //   BoxShadow(
            //     color: AppColors.primary.withValues(alpha: 0.12),
            //     blurRadius: 10,
            //     offset: const Offset(0, 3),
            //   ),
            // ],
          ),
          child: Icon(
            Iconsax.arrow_right_3_copy,
            size: 20,
            color: AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}
