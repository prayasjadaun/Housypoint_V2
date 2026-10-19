import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../core/network/api_exception.dart';
import '../models/wizard/wizard_models.dart';

/// Sell / rent / buy wizards (docs/API_REFERENCE.md §6).
class WizardRepository {
  WizardRepository(this._dio);

  final Dio _dio;

  /// W4
  Future<List<UnitConfiguration>> getConfigurations(int projectId) async {
    final data = await _get(ApiConfig.wizardConfigurations(projectId));
    final list = data is Map ? data['configurations'] ?? data['results'] : data;
    return [
      for (final c in list as List? ?? const [])
        if (c is Map) UnitConfiguration.fromJson(Map<String, dynamic>.from(c)),
    ];
  }

  /// W5
  Future<List<ProjectImage>> getProjectImages(int projectId) async {
    final data = await _get(ApiConfig.wizardProjectImages(projectId));
    final list = data is Map ? data['images'] ?? data['results'] : data;
    return [
      for (final i in list as List? ?? const [])
        if (i is Map) ProjectImage.fromJson(Map<String, dynamic>.from(i)),
    ].where((i) => i.url.isNotEmpty).toList();
  }

  /// W6 — uploads the user's own photos, returns their ids.
  Future<List<int>> uploadImages(List<String> paths) async {
    if (paths.isEmpty) return const [];
    try {
      final form = FormData();
      for (final path in paths) {
        final name = path.split('/').last;
        final ext = name.split('.').last.toLowerCase();
        form.files.add(MapEntry(
          'custom_images',
          await MultipartFile.fromFile(
            path,
            filename: name,
            contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
          ),
        ));
      }
      final data = (await _dio.post(ApiConfig.uploadImages, data: form)).data;
      if (data is Map && data['image_ids'] is List) {
        return [for (final id in data['image_ids'] as List) int.parse(id.toString())];
      }
      if (data is List) {
        return [for (final img in data) if (img is Map) int.parse(img['id'].toString())];
      }
      return const [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not upload your photos.');
    }
  }

  /// W7 / W8
  Future<void> submitListing(Map<String, dynamic> body, {required bool rental}) =>
      _post(rental ? ApiConfig.rentListing : ApiConfig.sellListing, body, 'Could not post your property.');

  /// W9
  Future<void> submitBuyInterest(Map<String, dynamic> body) =>
      _post(ApiConfig.buyInterest, body, 'Could not send your requirement.');

  Future<void> _post(String path, Map<String, dynamic> body, String fallback) async {
    try {
      await _dio.post(path, data: body);
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback);
    }
  }

  Future<Object?> _get(String path) async {
    try {
      return (await _dio.get(path)).data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not load project details.');
    }
  }
}
