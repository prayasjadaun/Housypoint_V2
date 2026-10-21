import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../core/network/api_exception.dart';
import '../models/common/paged.dart';
import '../models/listing/listing_counts.dart';
import '../models/listing/listing_model.dart';

/// Hot deals grouped the way `distress-deals/` returns them (API ref L4).
class DistressDeals {
  const DistressDeals(this.byTab);

  /// Keys: resale, rent, resale_commercial, rent_commercial.
  final Map<String, List<ListingModel>> byTab;

  List<ListingModel> tab(String key) => byTab[key] ?? const [];

  bool get isEmpty => byTab.values.every((l) => l.isEmpty);
}

/// Property listings (docs/API_REFERENCE.md §5).
class ListingRepository {
  ListingRepository(this._dio);

  final Dio _dio;

  /// L3 — counts per BHK / commercial subtype. Null filters = everything.
  Future<ListingCounts> getCounts({String? city, int? builderId}) async {
    try {
      final response = await _dio.get(
        ApiConfig.listingCounts,
        queryParameters: {'city': ?city, 'builder': ?builderId},
      );
      return ListingCounts.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not load property counts.');
    }
  }

  /// L1 / L2 — one page of resale or rental listings.
  Future<Paged<ListingModel>> getListings({
    required bool rental,
    String? city,
    String? propertyType,
    String? bhk,
    String? commercialSubtype,
    int? builderId,
    int? projectId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        rental ? ApiConfig.rentListings : ApiConfig.saleListings,
        queryParameters: {
          'city': ?city,
          'property_type': ?propertyType,
          'bhk': ?bhk,
          'commercial_subtype': ?commercialSubtype,
          'builder': ?builderId,
          'project': ?projectId,
          'search': ?search,
          'page': page,
          'page_size': pageSize,
        },
      );
      return Paged.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ListingModel.fromJson(json, isRental: rental),
      );
    } on DioException catch (e) {
      // Past the last page the API answers 404 "Invalid page".
      if (e.response?.statusCode == 404 && page > 1) {
        return const Paged(items: [], count: 0);
      }
      throw ApiException.fromDio(e, 'Could not load properties.');
    }
  }

  Future<ListingModel> getListing(int id, {required bool rental}) async {
    try {
      final response = await _dio.get(ApiConfig.listing(id, rental: rental));
      return ListingModel.fromJson(
        response.data as Map<String, dynamic>,
        isRental: rental,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not load this property.');
    }
  }

  /// L4 — below-market "hot deals".
  Future<DistressDeals> getDistressDeals({String? city}) async {
    try {
      final response = await _dio.get(
        ApiConfig.distressDeals,
        queryParameters: {'city': ?city},
      );
      final data = response.data as Map<String, dynamic>;
      return DistressDeals({
        for (final key in const ['resale', 'rent', 'resale_commercial', 'rent_commercial'])
          key: [
            for (final item in data[key] as List? ?? const [])
              ListingModel.fromJson(
                item as Map<String, dynamic>,
                isRental: key.startsWith('rent'),
              ),
          ],
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not load hot deals.');
    }
  }
}
