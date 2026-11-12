import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../core/network/api_exception.dart';
import '../models/referral/referral_models.dart';

/// Refer & Earn (docs/API_REFERENCE.md §11).
class ReferralRepository {
  ReferralRepository(this._dio);

  final Dio _dio;

  Future<ReferralStats> getStats() async {
    final data = await _get(ApiConfig.referralStats);
    return ReferralStats.fromJson(data as Map<String, dynamic>);
  }

  Future<PdiReferralStats> getPdiStats() async {
    final data = await _get(ApiConfig.referralPdiStats);
    return PdiReferralStats.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ReferralEarning>> getEarnings() async =>
      _results(await _get(ApiConfig.referralEarnings)).map(ReferralEarning.fromJson).toList();

  Future<List<Withdrawal>> getWithdrawals() async =>
      _results(await _get(ApiConfig.referralWithdrawals)).map(Withdrawal.fromJson).toList();

  Future<List<ReferredUser>> getReferredUsers() async =>
      _results(await _get(ApiConfig.referredUsers)).map(ReferredUser.fromJson).toList();

  /// R6
  Future<void> requestWithdrawal({
    required num amount,
    required String accountName,
    required String accountNumber,
    required String ifsc,
  }) async {
    try {
      await _dio.post(
        ApiConfig.referralWithdrawals,
        data: {
          'amount': amount,
          'account_name': accountName,
          'account_number': accountNumber,
          'ifsc_code': ifsc,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not submit your withdrawal.');
    }
  }

  Future<Object?> _get(String path) async {
    try {
      return (await _dio.get(path)).data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not load your referral data.');
    }
  }

  /// Lists come as `[...]`, `{results: [...]}` or `{results: {results: [...]}}`.
  List<Map<String, dynamic>> _results(Object? data) {
    Object? list = data;
    while (list is Map) {
      list = list['results'];
    }
    return [
      for (final item in list as List? ?? const [])
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }
}
