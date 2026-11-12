import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../core/network/api_exception.dart';
import '../models/project/project_model.dart';
import '../models/search/search_results.dart';

/// Projects and new launches (docs/API_REFERENCE.md §3–4).
class ProjectRepository {
  ProjectRepository(this._dio);

  final Dio _dio;

  /// C5 — `{success, data: [...]}`.
  Future<List<ProjectSummary>> getNewLaunches({String? city}) async {
    try {
      final response = await _dio.get(
        ApiConfig.newLaunches,
        queryParameters: {'city': ?city},
      );
      final data = (response.data as Map<String, dynamic>)['data'] as List? ?? const [];
      return data
          .map((e) => ProjectSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not load new launches.');
    }
  }

  /// M6
  Future<ProjectDetail> getProject(int id) async {
    try {
      final response = await _dio.get(ApiConfig.project(id));
      return ProjectDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not load this project.');
    }
  }

  /// M4 — plain list (not paginated).
  Future<List<ProjectSummary>> getBuilderProjects(int builderId, {String? type}) async {
    try {
      final response = await _dio.get(
        ApiConfig.builderProjects(builderId),
        queryParameters: {'project_type': ?type},
      );
      return (response.data as List)
          .map((e) => ProjectSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not load projects.');
    }
  }

  /// M7 — properties, projects and builders matching [query].
  Future<SearchResults> search(String query) async {
    try {
      final response = await _dio.get(
        ApiConfig.search,
        queryParameters: {
          'q': query,
          'search_type': 'all',
          'include_location': true,
          'include_area': true,
          'include_bhk': true,
        },
      );
      return SearchResults.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Search failed. Please try again.');
    }
  }
}
