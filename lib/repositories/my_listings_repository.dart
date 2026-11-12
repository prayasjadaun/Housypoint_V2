import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../core/network/api_exception.dart';
import '../models/listing/listing_model.dart';

/// Properties the user posted (API ref W10).
class MyListings {
  const MyListings({required this.forSale, required this.forRent});

  final List<ListingModel> forSale;
  final List<ListingModel> forRent;
}

class MyListingsRepository {
  MyListingsRepository(this._dio);

  final Dio _dio;

  Future<MyListings> get() async {
    try {
      final data = (await _dio.get(ApiConfig.myListings)).data as Map<String, dynamic>;
      List<ListingModel> parse(String key, {required bool rental}) => [
        for (final item in data[key] as List? ?? const [])
          if (item is Map) ListingModel.fromJson(Map<String, dynamic>.from(item), isRental: rental),
      ];
      return MyListings(
        forSale: [
          ...parse('property_listings', rental: false),
          ...parse('commercial_sale_listings', rental: false),
        ],
        forRent: [
          ...parse('rent_listings', rental: true),
          ...parse('commercial_rent_listings', rental: true),
        ],
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not load your listings.');
    }
  }
}
