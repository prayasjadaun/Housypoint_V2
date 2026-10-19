import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/listing/listing_counts.dart';
import '../models/listing/listing_model.dart';
import '../models/master/builder_model.dart';
import '../repositories/listing_repository.dart';

/// Filters + paginated results for the Listings tab. Home count tiles call
/// [applyFilter] and switch to the tab.
class ListingsController extends ChangeNotifier {
  ListingsController(this._repository);

  final ListingRepository _repository;

  DealType deal = DealType.sale;
  PropertyCategory category = PropertyCategory.residential;

  /// Counts-API key of the size/type chip (`three`, `office`…); null = all.
  String? sizeKey;
  String? city;
  BuilderModel? builder;

  List<ListingModel> items = [];
  int total = 0;
  bool isLoading = false;
  bool isLoadingMore = false;
  String? error;

  int _page = 0;
  bool _hasMore = true;
  bool _started = false;
  int _requestId = 0;

  bool get hasMore => _hasMore;

  /// The API takes comma-separated BHKs; "3 BHK" covers 3 and 3.5 (as the
  /// counts endpoint does).
  static const _bhkQuery = {
    'one': '1,1.5',
    'two': '2,2.5',
    'three': '3,3.5',
    'four': '4,4.5',
    'five_plus': '5,5.5,6,6.5,7',
    'studio': 'studio',
  };

  /// First open of the tab — loads with the home city.
  void ensureStarted(String? homeCity) {
    if (_started) return;
    city = homeCity;
    load();
  }

  void applyFilter({
    DealType? deal,
    PropertyCategory? category,
    String? sizeKey,
    String? city,
    BuilderModel? builder,
  }) {
    this.deal = deal ?? this.deal;
    this.category = category ?? this.category;
    this.sizeKey = sizeKey;
    this.city = city;
    this.builder = builder;
    load();
  }

  void setDeal(DealType value) {
    if (deal == value) return;
    deal = value;
    load();
  }

  void setCategory(PropertyCategory value) {
    if (category == value) return;
    category = value;
    sizeKey = null; // BHK chips don't apply to commercial and vice versa
    load();
  }

  void setSize(String? key) {
    if (sizeKey == key) return;
    sizeKey = key;
    load();
  }

  void setCity(String? value) {
    if (city == value) return;
    city = value;
    builder = null;
    load();
  }

  Future<void> load() async {
    _started = true;
    final request = ++_requestId;
    isLoading = true;
    error = null;
    items = [];
    _page = 0;
    _hasMore = true;
    notifyListeners();
    await _fetch(request);
    if (request == _requestId) {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !_hasMore) return;
    isLoadingMore = true;
    notifyListeners();
    await _fetch(_requestId);
    isLoadingMore = false;
    notifyListeners();
  }

  Future<void> _fetch(int request) async {
    try {
      final residential = category == PropertyCategory.residential;
      final page = await _repository.getListings(
        rental: deal == DealType.rent,
        city: city,
        propertyType: category.name,
        bhk: residential && sizeKey != null ? _bhkQuery[sizeKey] : null,
        commercialSubtype: !residential ? sizeKey : null,
        builderId: builder?.id,
        page: _page + 1,
      );
      // A newer filter started meanwhile — drop this stale page.
      if (request != _requestId) return;
      _page++;
      items = [...items, ...page.items];
      if (_page == 1) total = page.count;
      _hasMore = page.hasMore;
    } on ApiException catch (e) {
      if (request != _requestId) return;
      error = e.message;
      _hasMore = false;
    }
  }
}
