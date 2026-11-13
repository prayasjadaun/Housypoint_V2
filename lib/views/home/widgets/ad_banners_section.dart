import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/launcher.dart';
import '../../../models/common/ad_banner.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/common/app_network_image.dart';

/// Swipeable promo banners — the next card peeks in from the right,
/// auto-advances, and pauses while the user drags.
class AdBannersSection extends StatefulWidget {
  const AdBannersSection({super.key, this.ads = AdBanner.local});

  final List<AdBanner> ads;

  @override
  State<AdBannersSection> createState() => _AdBannersSectionState();
}

class _AdBannersSectionState extends State<AdBannersSection> {
  /// Share of the width one page takes; the rest is the neighbours' peek.
  static const double _viewport = 0.92;

  /// Half the gap between two cards.
  static const double _halfGap = 6;
  static const _autoEvery = Duration(seconds: 4);

  final _controller = PageController(viewportFraction: _viewport);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startAuto();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAuto() {
    _timer?.cancel();
    if (widget.ads.length < 2) return;
    _timer = Timer.periodic(_autoEvery, (_) {
      // Home IndexedStack me hai — doosre tab par ho to slide mat karo
      if (!mounted ||
          !_controller.hasClients ||
          !TickerMode.valuesOf(context).enabled) {
        return;
      }
      _controller.animateToPage(
        (_index + 1) % widget.ads.length,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _timer?.cancel();
    } else if (n is ScrollEndNotification) {
      _startAuto();
    }
    return false;
  }

  void _open(AdBanner ad) {
    final link = ad.link;
    if (link == null) return;
    AppHaptics.tap();
    Launcher.url(link);
  }

  @override
  Widget build(BuildContext context) {
    final ads = widget.ads;
    if (ads.isEmpty) return const SizedBox.shrink();

    if (ads.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: _AdCard(ad: ads.first, onTap: () => _open(ads.first)),
      );
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth * _viewport - 2 * _halfGap;

            // Banners alag shape ke hain. Section ki height sabse lambe banner
            // jitni fix hai — har slide par neeche ka content upar-neeche
            // nahi kudta; chhote banners beech me (vertically) rehte hain
            final tallest = ads
                .map((a) => cardWidth / a.aspectRatio)
                .reduce(math.max);
            return SizedBox(
              height: tallest,
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: PageView.builder(
                  controller: _controller,
                  // Har card center me — padEnds: false par aakhri card
                  // right edge se chipak ke left me khaali jagah chhodta tha
                  itemCount: ads.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _halfGap),
                    child: Center(
                      child: _AdCard(ad: ads[i], onTap: () => _open(ads[i])),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _Dots(count: ads.length, index: _index),
      ],
    );
  }
}

class _AdCard extends StatelessWidget {
  const _AdCard({required this.ad, required this.onTap});

  final AdBanner ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl);
    return AspectRatio(
      aspectRatio: ad.aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppColors.isDark ? 0.3 : 0.05,
              ),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ad.isNetwork
                  ? AppNetworkImage(url: ad.image)
                  : Image.asset(ad.image, fit: BoxFit.cover),
              // Hairline border + ripple on top of the artwork
              Material(
                type: MaterialType.transparency,
                shape: RoundedRectangleBorder(
                  borderRadius: radius,
                  side: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.7),
                  ),
                ),
                child: InkWell(
                  borderRadius: radius,
                  onTap: ad.link == null ? null : onTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index ? AppColors.textPrimary : AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
