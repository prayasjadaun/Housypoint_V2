import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/utils/app_haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_logo.dart';
import 'widgets/onboarding_illustration.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.message,
    required this.chips,
  });

  final IconData icon;
  final String title;
  final String message;
  final List<OnboardingChip> chips;
}

/// First-launch intro (shown once, before login). Finishing or skipping
/// marks it seen; the router then moves on to login.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Iconsax.buildings_2_copy,
      title: 'Find your perfect home',
      message:
          'Explore verified resale, rental and new-launch properties across top cities.',
      chips: [
        OnboardingChip(Iconsax.verify_copy, 'Verified listings'),
        OnboardingChip(Iconsax.location_copy, 'Top cities'),
        OnboardingChip(Iconsax.key_copy, 'Ready to move'),
      ],
    ),
    _OnboardingPage(
      icon: Iconsax.shield_tick_copy,
      title: 'Inspect before you move in',
      message:
          'Book a professional home inspection and catch every defect before possession.',
      chips: [
        OnboardingChip(Iconsax.tick_square_copy, 'Detailed checks'),
        OnboardingChip(Iconsax.calendar_tick_copy, 'Pick your slot'),
        OnboardingChip(Iconsax.star_1_copy, 'Expert engineers'),
      ],
    ),
    _OnboardingPage(
      icon: Iconsax.wallet_money_copy,
      title: 'Sell, rent & earn',
      message:
          'List your property in minutes and earn rewards every time a friend joins.',
      chips: [
        OnboardingChip(Iconsax.flash_1_copy, 'Quick listing'),
        OnboardingChip(Iconsax.ranking_1_copy, 'Best price insights'),
        OnboardingChip(Iconsax.gift_copy, 'Refer & earn'),
      ],
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    AppHaptics.success();
    context.read<AuthController>().completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _TopBar(showSkip: !_isLast, onSkip: _finish),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (page) {
                    AppHaptics.selection();
                    setState(() => _page = page);
                  },
                  itemBuilder: (context, index) => _PageContent(page: _pages[index]),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  bottomInset + AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    _PageDots(count: _pages.length, current: _page),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: _isLast ? 'Get started' : 'Next',
                      icon: Iconsax.arrow_right_3_copy,
                      onPressed: _next,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.showSkip, required this.onSkip});

  final bool showSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, 0),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: 10),
            Text('Housy Point', style: AppTextStyles.title),
            const Spacer(),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: showSkip ? 1 : 0,
              child: TextButton(
                onPressed: showSkip ? onSkip : null,
                style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                child: const Text('Skip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: OnboardingIllustration(icon: page.icon, chips: page.chips),
            ),
          ),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.display.copyWith(fontSize: 26),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Text(
            page.message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == current ? 26 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
