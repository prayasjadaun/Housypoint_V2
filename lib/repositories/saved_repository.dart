import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../core/network/api_exception.dart';
import '../models/listing/listing_model.dart';

/// Wishlist ("Saved") and interests ("Contacted") — API ref S1–S4.
class SavedRepository {
  SavedRepository(this._dio);

  final Dio _dio;

  /// S1 — `{wishlist: [{listing: {...}} | {rent_listing: {...}}]}`
  Future<List<ListingModel>> getWishlist(String userId) =>
      _list(ApiConfig.wishlist, userId, 'wishlist');

  /// S3 — `{interests: [{listing: {...}}]}`
  Future<List<ListingModel>> getInterests(String userId) =>
      _list(ApiConfig.interests, userId, 'interests');

  /// S2 — adds or removes the listing.
  Future<void> toggleWishlist(ListingModel listing) async {
    try {
      await _dio.post(ApiConfig.wishlistToggle, data: _idBody(listing));
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not update your saved list.');
    }
  }

  /// S4 — tells the owner/agent the user is interested.
  Future<void> showInterest(ListingModel listing, {bool distressDeal = false}) async {
    try {
      await _dio.post(
        ApiConfig.showInterest,
        data: {..._idBody(listing), 'distress_deal': distressDeal},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not send your request.');
    }
  }

  Map<String, dynamic> _idBody(ListingModel l) =>
      l.isRental ? {'rent_listing_id': l.id} : {'listing_id': l.id};

  Future<List<ListingModel>> _list(String path, String userId, String key) async {
    try {
      final response = await _dio.get(path, queryParameters: {'user_id': userId});
      final items = (response.data as Map<String, dynamic>)[key] as List? ?? const [];
      return [
        for (final item in items)
          if (item is Map) ...[
            if (item['listing'] is Map)
              ListingModel.fromJson(
                Map<String, dynamic>.from(item['listing'] as Map),
                isRental: false,
              ),
            if (item['rent_listing'] is Map)
              ListingModel.fromJson(
                Map<String, dynamic>.from(item['rent_listing'] as Map),
                isRental: true,
              ),
          ],
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not load your properties.');
    }
  }
}
