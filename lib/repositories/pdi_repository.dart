import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../core/network/api_exception.dart';
import '../models/pdi/pdi_models.dart';

/// Home inspection booking (docs/API_REFERENCE.md §8).
class PdiRepository {
  PdiRepository(this._dio);

  final Dio _dio;

  /// P4
  Future<List<PdiPlan>> getPlans() async {
    final data = await _get(ApiConfig.pdiPlans) as Map<String, dynamic>;
    return [
      for (final p in data['plans'] as List? ?? const [])
        if (p is Map) PdiPlan.fromJson(Map<String, dynamic>.from(p)),
    ];
  }

  /// P5 — `["2026-10-19", …]` or `{dates: [...]}`.
  Future<List<DateTime>> getDates() async {
    final data = await _get(ApiConfig.pdiDates);
    final list = data is Map ? data['dates'] : data;
    return [
      for (final d in list as List? ?? const [])
        ?DateTime.tryParse(d.toString()),
    ];
  }

  /// P6 — only slots that still have room.
  Future<List<PdiSlot>> getSlots(DateTime date) async {
    final data = await _get(ApiConfig.pdiSlots, query: {'date': _ymd(date)}) as Map<String, dynamic>;
    return [
      for (final s in data['slots'] as List? ?? const [])
        if (s is Map) PdiSlot.fromJson(Map<String, dynamic>.from(s)),
    ].where((s) => s.available > 0).toList();
  }

  /// P7 — returns the uploaded file URL.
  Future<String> uploadFloorPlan(String path, String fileName) async {
    try {
      final response = await _dio.post(
        ApiConfig.pdiUploadFloorPlan,
        data: FormData.fromMap({
          'floor_plan': await MultipartFile.fromFile(path, filename: fileName),
        }),
      );
      final url = (response.data as Map?)?['file_url']?.toString();
      if (url == null || url.isEmpty) throw const ApiException('Upload failed. Please try again.');
      return url;
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not upload the floor plan.');
    }
  }

  /// P8
  Future<PdiBooking> book({
    required String city,
    required PdiPlan plan,
    required PdiSlot slot,
    required String unitNumber,
    required String floorNumber,
    int? builderId,
    String? builderOther,
    int? projectId,
    String? projectOther,
    String? notes,
    String? floorPlanUrl,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.pdiBook,
        data: {
          'city': city,
          'plan_type': plan.name.toLowerCase(),
          'unit_number': unitNumber,
          'floor_number': floorNumber,
          'timeslot_id': slot.id,
          'price': plan.price,
          'final_price': plan.total,
          if (plan.oldPrice > 0) 'old_price': plan.oldPrice,
          if (builderId != null) 'builder_id': builderId else 'builder_other': builderOther,
          if (projectId != null) 'project_id': projectId else 'project_other': projectOther,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'floor_plan_url': ?floorPlanUrl,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final booking = data['booking'] ?? data['data'] ?? data;
      return PdiBooking.fromJson(Map<String, dynamic>.from(booking as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not book the inspection.');
    }
  }

  /// P9 — `[...]` or `{success, bookings: [...]}`.
  Future<List<PdiBooking>> getBookings() async {
    final data = await _get(ApiConfig.pdiBookings);
    final list = data is Map ? data['bookings'] ?? data['results'] : data;
    return [
      for (final b in list as List? ?? const [])
        if (b is Map) PdiBooking.fromJson(Map<String, dynamic>.from(b)),
    ];
  }

  Future<Object?> _get(String path, {Map<String, dynamic>? query}) async {
    try {
      return (await _dio.get(path, queryParameters: query)).data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not load inspection details.');
    }
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
