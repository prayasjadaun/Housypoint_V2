import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../core/network/api_exception.dart';
import '../models/master/builder_model.dart';
import '../models/master/city_model.dart';

/// Cities and builders (docs/API_REFERENCE.md §4).
class MasterDataRepository {
  MasterDataRepository(this._dio);

  final Dio _dio;

  List<CityModel>? _cities;

  /// M1 — cached for the session; the list rarely changes.
  Future<List<CityModel>> getCities() async {
    if (_cities != null) return _cities!;
    try {
      final response = await _dio.get(ApiConfig.cities);
      final list = (response.data as List)
          .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
          // The backend has a placeholder row we never show.
          .where((c) => c.name.isNotEmpty && c.name != 'Default City')
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return _cities = list;
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not load cities.');
    }
  }

  /// M3
  Future<BuilderModel> getBuilder(int id) async {
    try {
      final response = await _dio.get(ApiConfig.builder(id));
      return BuilderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not load this builder.');
    }
  }

  /// M2 — every builder active in [city] (all cities when null).
  Future<List<BuilderModel>> getBuilders({String? city}) async {
    try {
      final response = await _dio.get(
        ApiConfig.builders,
        queryParameters: {
          'city': ?city,
          'page': 1,
          'page_size': 1000,
        },
      );
      final results = (response.data as Map<String, dynamic>)['results'] as List;
      return results
          .map((e) => BuilderModel.fromJson(e as Map<String, dynamic>))
          .where((b) => b.name.isNotEmpty)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not load builders.');
    }
  }
}
