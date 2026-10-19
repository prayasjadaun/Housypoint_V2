import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/listing/listing_model.dart';
import '../repositories/saved_repository.dart';

/// Saved (wishlist) and Contacted (interests) listings. Cards everywhere
/// read [isSaved] and call [toggleSave], so the heart stays in sync.
class SavedController extends ChangeNotifier {
  SavedController(this._repository);

  final SavedRepository _repository;

  List<ListingModel> saved = [];
  List<ListingModel> contacted = [];
  bool isLoading = false;
  String? error;

  final Set<String> _savedKeys = {};
  final Set<String> _contactedKeys = {};
  String? _userId;

  static String _key(ListingModel l) => '${l.isRental ? 'r' : 's'}${l.id}';

  bool isSaved(ListingModel l) => _savedKeys.contains(_key(l)) || l.isWishlisted;
  bool isContacted(ListingModel l) =>
      _contactedKeys.contains(_key(l)) || l.isInterested;

  /// Called when the user logs in / the Saved tab opens.
  Future<void> load(String userId) async {
    _userId = userId;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getWishlist(userId),
        _repository.getInterests(userId),
      ]);
      saved = results[0];
      contacted = results[1];
      _savedKeys
        ..clear()
        ..addAll(saved.map(_key));
      _contactedKeys
        ..clear()
        ..addAll(contacted.map(_key));
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_userId != null) await load(_userId!);
  }

  /// Optimistic: flips the heart at once and rolls back if the API fails.
  /// Returns the error message on failure.
  Future<String?> toggleSave(ListingModel listing) async {
    final key = _key(listing);
    final wasSaved = isSaved(listing);
    if (wasSaved) {
      _savedKeys.remove(key);
      saved.removeWhere((l) => _key(l) == key);
    } else {
      _savedKeys.add(key);
      saved.insert(0, listing.copyWith(isWishlisted: true));
    }
    // The model's own flag would otherwise keep the heart filled.
    _overrides[key] = !wasSaved;
    notifyListeners();

    try {
      await _repository.toggleWishlist(listing);
      return null;
    } on ApiException catch (e) {
      _overrides[key] = wasSaved;
      if (wasSaved) {
        _savedKeys.add(key);
        saved.insert(0, listing);
      } else {
        _savedKeys.remove(key);
        saved.removeWhere((l) => _key(l) == key);
      }
      notifyListeners();
      return e.message;
    }
  }

  /// Returns the error message on failure.
  Future<String?> contact(ListingModel listing, {bool distressDeal = false}) async {
    try {
      await _repository.showInterest(listing, distressDeal: distressDeal);
      _contactedKeys.add(_key(listing));
      contacted.insert(0, listing.copyWith(isInterested: true));
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  final Map<String, bool> _overrides = {};

  /// Heart state for a card, honouring local toggles over the API flag.
  bool savedState(ListingModel l) => _overrides[_key(l)] ?? isSaved(l);

  void clear() {
    saved = [];
    contacted = [];
    _savedKeys.clear();
    _contactedKeys.clear();
    _overrides.clear();
    _userId = null;
    notifyListeners();
  }
}
