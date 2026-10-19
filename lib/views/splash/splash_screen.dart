import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_logo.dart';

/// Brand splash while the saved session is restored; the router redirect
/// moves on as soon as [AuthController.status] is known.
///
/// Its background matches the native launch screen (#075C2E), so the
/// hand-off from the OS splash is seamless.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  // Staggered entrance: logo → wordmark → tagline → loader.
  late final _logo = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
  );
  late final _logoFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
  );
  late final _wordmark = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
  );
  late final _tagline = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.5, 0.85, curve: Curves.easeOutCubic),
  );
  late final _footer = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    // Let the intro finish before the router moves on.
    Future<void>.delayed(const Duration(milliseconds: 1800))
        .then((_) => auth.restoreSession());
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.15),
              radius: 1.1,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Quiet concentric rings behind the logo
              const Align(
                alignment: Alignment(0, -0.12),
                child: _Rings(),
              ),
              Align(
                alignment: const Alignment(0, -0.12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.7, end: 1.0).animate(_logo),
                        child: const FramedAppLogo(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SlideFade(
                      animation: _wordmark,
                      child: Text(
                        'Housy Point',
                        style: AppTextStyles.display.copyWith(
                          color: Colors.white,
                          fontSize: 30,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SlideFade(
                      animation: _tagline,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _line(),
                          const SizedBox(width: 10),
                          Text(
                            'BUY · SELL · RENT · INSPECT',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _line(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset + 32,
                child: FadeTransition(
                  opacity: _footer,
                  child: Column(
                    children: [
                      const _LoadingBar(),
                      const SizedBox(height: 14),
                      Text(
                        'Version ${AppConfig.appVersion.split('+').first}',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line() => Container(
    width: 18,
    height: 1,
    color: AppColors.gold.withValues(alpha: 0.5),
  );
}

class _Rings extends StatelessWidget {
  const _Rings();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final (size, alpha) in const [(240.0, 0.07), (360.0, 0.05), (500.0, 0.035)])
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
    );
  }
}

/// Fades in while sliding up a few pixels.
class _SlideFade extends StatelessWidget {
  const _SlideFade({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.4), end: Offset.zero)
            .animate(animation),
        child: child,
      ),
    );
  }
}

/// Slim indeterminate bar — a gold segment sweeping across a faint track.
class _LoadingBar extends StatefulWidget {
  const _LoadingBar();

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  static const double _width = 56;
  static const double _segment = 20;

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Container(
        width: _width,
        height: 3,
        color: Colors.white.withValues(alpha: 0.15),
        child: AnimatedBuilder(
          animation: _sweep,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_sweep.value);
            return Stack(
              children: [
                Positioned(
                  left: -_segment + t * (_width + _segment),
                  top: 0,
                  bottom: 0,
                  width: _segment,
                  child: const ColoredBox(color: AppColors.gold),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
