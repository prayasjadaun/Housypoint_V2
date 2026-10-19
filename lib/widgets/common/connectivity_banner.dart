import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/network/connectivity_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

enum _BannerState { hidden, offline, backOnline }

/// App-wide glass pill under the app bar: stays while offline, shows
/// "Back online" for a moment once the link returns.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  static const _backOnlineFor = Duration(seconds: 2);

  late final ConnectivityService _connectivity;
  _BannerState _state = _BannerState.hidden;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _connectivity = context.read<ConnectivityService>()
      ..addListener(_onChanged);
    if (!_connectivity.isOnline) _state = _BannerState.offline;
  }

  void _onChanged() {
    _hideTimer?.cancel();
    if (!_connectivity.isOnline) {
      setState(() => _state = _BannerState.offline);
      return;
    }
    if (_state != _BannerState.offline) return;
    setState(() => _state = _BannerState.backOnline);
    _hideTimer = Timer(_backOnlineFor, () {
      if (mounted) setState(() => _state = _BannerState.hidden);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _connectivity.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + kToolbarHeight + 8;
    final visible = _state != _BannerState.hidden;

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, -0.6),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _Pill(
                  key: ValueKey(_state == _BannerState.backOnline),
                  online: _state == _BannerState.backOnline,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? AppColors.success : AppColors.textPrimary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                online ? Iconsax.wifi_copy : Iconsax.wifi_square_copy,
                size: 16,
                color: AppColors.onPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                online ? 'Back online' : 'No internet connection',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
