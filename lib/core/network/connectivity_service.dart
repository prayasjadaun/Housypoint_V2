import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

/// Watches the device's network link (WiFi / mobile / ethernet …).
///
/// This only knows whether a link exists, not whether the internet actually
/// works — it drives the offline banner and auto-refresh. Real failures are
/// still reported by [ApiException] on each request.
///
/// iOS par connectivity_plus kabhi-kabhi jhoota `none` deta hai (app resume,
/// WiFi handover, simulator) aur baad me "online" wala event bhejta hi nahi —
/// banner restart tak atka rehta tha. Isliye:
/// - `none` par turant offline nahi, thodi der baad dobara check karke hi
/// - offline rehte hue har kuch second re-check (missed event se recover)
/// - app resume par re-check
class ConnectivityService extends ChangeNotifier {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity() {
    _subscription = _connectivity.onConnectivityChanged.listen(_onEvent);
    _lifecycle = AppLifecycleListener(onResume: _recheck);
    _recheck();
  }

  static const _confirmAfter = Duration(milliseconds: 1500);
  static const _pollWhileOffline = Duration(seconds: 3);

  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  late final AppLifecycleListener _lifecycle;
  Timer? _confirmTimer;
  Timer? _pollTimer;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  static bool _hasLink(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  void _onEvent(List<ConnectivityResult> results) {
    if (_hasLink(results)) {
      _set(true);
      return;
    }
    // Ek `none` par bharosa nahi — thodi der baad asli state poochho
    _confirmTimer?.cancel();
    _confirmTimer = Timer(_confirmAfter, _recheck);
  }

  Future<void> _recheck() async {
    try {
      _set(_hasLink(await _connectivity.checkConnectivity()));
    } catch (_) {
      // Plugin fail ho to banner na dikhao — API errors khud batayenge
      _set(true);
    }
  }

  void _set(bool online) {
    _confirmTimer?.cancel();
    if (online) {
      _pollTimer?.cancel();
      _pollTimer = null;
    } else {
      _pollTimer ??= Timer.periodic(_pollWhileOffline, (_) => _recheck());
    }
    if (online == _isOnline) return;
    _isOnline = online;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _lifecycle.dispose();
    _confirmTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}
