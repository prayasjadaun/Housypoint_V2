import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../core/network/api_exception.dart';
import '../models/loan/bank_model.dart';

/// Home loan banks (docs/API_REFERENCE.md §10).
class LoanRepository {
  LoanRepository(this._dio);

  final Dio _dio;

  Future<List<BankModel>> getBanks() async {
    try {
      final data = (await _dio.get(ApiConfig.loanBanks)).data;
      final list = data is Map ? data['results'] : data;
      return [
        for (final b in list as List? ?? const [])
          if (b is Map && b['is_active'] != false) BankModel.fromJson(Map<String, dynamic>.from(b)),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not load banks.');
    }
  }
}
