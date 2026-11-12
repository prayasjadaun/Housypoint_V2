import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../core/network/api_exception.dart';
import '../models/consultation/consultation_models.dart';

/// Expert consultations (docs/API_REFERENCE.md §9).
class ConsultationRepository {
  ConsultationRepository(this._dio);

  final Dio _dio;

  ConsultationOptions? _options;

  /// K1 — never throws; falls back to the known options.
  Future<ConsultationOptions> getOptions() async {
    if (_options != null) return _options!;
    try {
      final data = (await _dio.get(ApiConfig.consultationOptions)).data as Map<String, dynamic>;
      return _options = ConsultationOptions.fromJson(data['data'] as Map<String, dynamic>? ?? {});
    } catch (_) {
      return ConsultationOptions.fallback;
    }
  }

  /// K2
  Future<void> book({
    required String fullName,
    required String phone,
    required String email,
    required String serviceType,
    required String consultationType,
    required String timeSlot,
    String? otherDescription,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.consultationBook,
        data: {
          'full_name': fullName,
          'phone_number': phone,
          'email': email,
          'service_type': serviceType,
          'consultation_type': consultationType,
          'time_slot': timeSlot,
          if (otherDescription != null && otherDescription.isNotEmpty)
            'other_description': otherDescription,
          if (notes != null && notes.isNotEmpty) 'additional_notes': notes,
        },
      );
      final data = response.data;
      if (data is Map && data['success'] == false) {
        throw ApiException(data['message']?.toString() ?? 'Could not book the consultation.');
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not book the consultation.');
    }
  }

  /// K3 — the user's own bookings.
  Future<List<Consultation>> getMine() async {
    try {
      final response = await _dio.get(
        ApiConfig.consultations,
        queryParameters: {'user_only': true, 'page': 1, 'limit': 50},
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      final list = data is Map ? data['consultations'] : data;
      return [
        for (final item in list as List? ?? const [])
          if (item is Map) Consultation.fromJson(Map<String, dynamic>.from(item)),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not load your consultations.');
    }
  }

  /// K5
  Future<void> cancel(int id) async {
    try {
      await _dio.post(ApiConfig.consultationCancel(id));
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not cancel this consultation.');
    }
  }
}
