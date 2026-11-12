import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/referral/referral_models.dart';
import '../repositories/referral_repository.dart';

/// Refer & Earn tab state.
class ReferralController extends ChangeNotifier {
  ReferralController(this._repository);

  final ReferralRepository _repository;

  ReferralStats? stats;
  PdiReferralStats? pdiStats;
  List<ReferralEarning> earnings = [];
  List<Withdrawal> withdrawals = [];
  List<ReferredUser> referredUsers = [];

  bool isLoading = false;
  String? error;
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await load();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      stats = await _repository.getStats();
      _loaded = true;
      // The rest are secondary — one failing must not hide the dashboard.
      await Future.wait([
        _quietly(() async => pdiStats = await _repository.getPdiStats()),
        _quietly(() async => earnings = await _repository.getEarnings()),
        _quietly(() async => withdrawals = await _repository.getWithdrawals()),
        _quietly(() async => referredUsers = await _repository.getReferredUsers()),
      ]);
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _quietly(Future<void> Function() load) async {
    try {
      await load();
    } on ApiException {
      // keep the previous value
    }
  }

  /// Returns the error message on failure.
  Future<String?> withdraw({
    required num amount,
    required String accountName,
    required String accountNumber,
    required String ifsc,
  }) async {
    try {
      await _repository.requestWithdrawal(
        amount: amount,
        accountName: accountName,
        accountNumber: accountNumber,
        ifsc: ifsc,
      );
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  void clear() {
    stats = null;
    pdiStats = null;
    earnings = [];
    withdrawals = [];
    referredUsers = [];
    _loaded = false;
    notifyListeners();
  }
}
