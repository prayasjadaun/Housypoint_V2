import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/storage/app_prefs.dart';
import '../models/listing/listing_counts.dart';
import '../models/master/builder_model.dart';
import '../models/master/city_model.dart';
import '../models/project/project_model.dart';
import '../repositories/listing_repository.dart';
import '../models/pdi/pdi_models.dart';
import '../repositories/master_data_repository.dart';
import '../repositories/pdi_repository.dart';
import '../repositories/project_repository.dart';

/// State of the home screen's property filter: city, builder, deal type,
/// category and the listing counts for that selection.
class HomeController extends ChangeNotifier {
  HomeController(this._masterData, this._listings, this._projects, this._pdi);

  final MasterDataRepository _masterData;
  final ListingRepository _listings;
  final ProjectRepository _projects;
  final PdiRepository _pdi;

  List<CityModel> cities = [];
  List<BuilderModel> builders = [];

  /// Null = all cities / all builders.
  String? selectedCity = AppPrefs.selectedCity;
  BuilderModel? selectedBuilder;

  DealType deal = DealType.sale;
  PropertyCategory category = PropertyCategory.residential;

  ListingCounts? counts;
  bool isLoadingCounts = false;
  String? countsError;

  /// Home sections below the filter. Null = still loading.
  DistressDeals? hotDeals;
  List<ProjectSummary>? newLaunches;
  List<BuilderModel>? topBuilders;

  /// Home inspection plans for the pricing strip. Empty = hidden.
  List<PdiPlan>? inspectionPlans;

  bool _started = false;

  String get cityLabel => selectedCity ?? 'All cities';
  String get builderLabel => selectedBuilder?.name ?? 'All builders';

  /// Total for the current deal + category, e.g. "339".
  int get currentTotal => counts?.total(deal, category) ?? 0;

  /// First call from the home tab; later calls are no-ops.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await Future.wait([
      _loadCities(),
      // With no city both lists come from the same request.
      if (selectedCity == null) _loadAllBuilders() else ...[
        _loadBuilders(),
        _loadTopBuilders(),
      ],
      loadCounts(),
      _loadSections(),
      _loadInspectionPlans(),
    ]);
  }

  Future<void> _loadInspectionPlans() async {
    try {
      inspectionPlans = await _pdi.getPlans();
    } catch (_) {
      inspectionPlans = const [];
    }
    notifyListeners();
  }

  Future<void> _loadAllBuilders() async {
    try {
      builders = await _masterData.getBuilders();
    } on ApiException {
      builders = [];
    }
    topBuilders = _top(builders);
    notifyListeners();
  }

  static List<BuilderModel> _top(List<BuilderModel> all) =>
      all.where((b) => b.logoUrl.isNotEmpty).take(24).toList();

  Future<void> refresh() => Future.wait([
    _loadBuilders(),
    loadCounts(),
    _loadSections(),
    // Plans rarely change; only retry when the first load failed.
    if (inspectionPlans?.isEmpty ?? false) _loadInspectionPlans(),
  ]);

  Future<void> selectCity(String? city) async {
    if (city == selectedCity) return;
    selectedCity = city;
    // A builder from the old city may not exist in the new one.
    selectedBuilder = null;
    await AppPrefs.setSelectedCity(city);
    notifyListeners();
    await Future.wait([_loadBuilders(), loadCounts(), _loadSections()]);
  }

  Future<void> selectBuilder(BuilderModel? builder) async {
    if (builder == selectedBuilder) return;
    selectedBuilder = builder;
    notifyListeners();
    await loadCounts();
  }

  /// Deal/category only switch which counts are shown — no new request.
  void setDeal(DealType value) {
    if (deal == value) return;
    deal = value;
    notifyListeners();
  }

  void setCategory(PropertyCategory value) {
    if (category == value) return;
    category = value;
    notifyListeners();
  }

  Future<void> loadCounts() async {
    isLoadingCounts = true;
    countsError = null;
    notifyListeners();
    try {
      counts = await _listings.getCounts(
        city: selectedCity,
        builderId: selectedBuilder?.id,
      );
    } on ApiException catch (e) {
      countsError = e.message;
    } finally {
      isLoadingCounts = false;
      notifyListeners();
    }
  }

  Future<void> _loadCities() async {
    try {
      cities = await _masterData.getCities();
      notifyListeners();
    } on ApiException {
      // The picker shows an empty state and can retry.
    }
  }

  Future<void> _loadBuilders() async {
    try {
      builders = await _masterData.getBuilders(city: selectedCity);
      notifyListeners();
    } on ApiException {
      builders = [];
    }
  }

  /// Hot deals + new launches for the selected city. Failures leave the
  /// section empty (it hides itself) instead of blocking the page.
  Future<void> _loadSections() async {
    hotDeals = null;
    newLaunches = null;
    notifyListeners();
    await Future.wait([
      _listings
          .getDistressDeals(city: selectedCity)
          .then((v) => hotDeals = v)
          .catchError((_) => hotDeals = const DistressDeals({})),
      _projects
          .getNewLaunches(city: selectedCity)
          .then((v) => newLaunches = v)
          .catchError((_) => newLaunches = const <ProjectSummary>[]),
    ]);
    notifyListeners();
  }

  Future<void> _loadTopBuilders() async {
    try {
      final all = await _masterData.getBuilders();
      topBuilders = _top(all);
    } on ApiException {
      topBuilders = const [];
    }
    notifyListeners();
  }

  /// Picker retry when the first city load failed.
  Future<void> ensureCities() async {
    if (cities.isEmpty) await _loadCities();
  }
}
