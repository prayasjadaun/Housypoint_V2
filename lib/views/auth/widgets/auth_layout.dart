import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_logo.dart';

/// Shared frame for the auth screens: green brand header with the logo and
/// a white rounded sheet holding the title and the form.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

  final String title;
  final Widget subtitle;
  final Widget child;

  /// Shows a back button in the header when set.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _Header(topInset: topInset, onBack: onBack),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                color: AppColors.surface,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.heading),
                    const SizedBox(height: 6),
                    DefaultTextStyle.merge(
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      child: subtitle,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.topInset, this.onBack});

  final double topInset;
  final VoidCallback? onBack;

  static const double _capHeight = 28;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: topInset + 236,
      // Same radial green as the splash, so the hand-off feels continuous
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.2,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            top: topInset,
            bottom: _capHeight,
            child: const Center(child: _Rings()),
          ),
          Padding(
            padding: EdgeInsets.only(top: topInset, bottom: _capHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FramedAppLogo(size: 64),
                  const SizedBox(height: 14),
                  Text(
                    'Housy Point',
                    style: AppTextStyles.title.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'BUY · SELL · RENT · INSPECT',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onBack != null)
            Positioned(
              top: topInset + 8,
              left: AppSpacing.md,
              child: _GlassBackButton(onTap: onBack!),
            ),
          // White rounded cap — the form sheet appears to overlap the header
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _capHeight,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl + 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rings extends StatelessWidget {
  const _Rings();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: OverflowBox(
        maxWidth: 420,
        maxHeight: 420,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final (size, alpha) in const [
              (150.0, 0.08),
              (250.0, 0.055),
              (370.0, 0.04),
            ])
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: alpha)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: CircleBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox.square(
          dimension: 40,
          child: Icon(CupertinoIcons.back, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
