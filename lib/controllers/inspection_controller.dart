import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/master/builder_model.dart';
import '../models/pdi/pdi_models.dart';
import '../models/project/project_model.dart';
import '../repositories/master_data_repository.dart';
import '../repositories/pdi_repository.dart';
import '../repositories/project_repository.dart';

/// State of the 5-step home inspection booking:
/// location → property → plan → schedule → review.
class InspectionController extends ChangeNotifier {
  InspectionController(this._pdi, this._master, this._projects, {this.city}) {
    _init();
  }

  final PdiRepository _pdi;
  final MasterDataRepository _master;
  final ProjectRepository _projects;

  static const int stepCount = 5;
  static const stepTitles = ['Location', 'Property', 'Plan', 'Schedule', 'Review'];

  int step = 0;

  // 1 · Location
  String? city;

  // 2 · Property
  List<BuilderModel>? builders;
  BuilderModel? builder;
  String builderOther = '';
  bool useOtherBuilder = false;
  List<ProjectSummary>? projects;
  ProjectSummary? project;
  String projectOther = '';
  bool useOtherProject = false;
  String unitNumber = '';
  String floorNumber = '';
  String? floorPlanName;
  String? floorPlanUrl;
  bool uploadingFloorPlan = false;

  // 3 · Plan
  List<PdiPlan>? plans;
  PdiPlan? plan;

  // 4 · Schedule
  List<DateTime>? dates;
  DateTime? date;
  List<PdiSlot>? slots;
  PdiSlot? slot;

  // 5 · Review
  String notes = '';
  bool isSubmitting = false;
  String? error;

  Future<void> _init() async {
    try {
      final results = await Future.wait([_pdi.getPlans(), _pdi.getDates()]);
      plans = results[0] as List<PdiPlan>;
      dates = results[1] as List<DateTime>;
      plan = plans!.firstWhere((p) => p.isPopular, orElse: () => plans!.first);
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      // Empty plan list — the step shows its own empty state.
    }
    notifyListeners();
    if (city != null) _loadBuilders();
  }

  // ── Navigation ────────────────────────────────────────────

  bool get canContinue => switch (step) {
    0 => city != null,
    1 =>
      (useOtherBuilder ? builderOther.trim().isNotEmpty : builder != null) &&
          (useOtherProject || useOtherBuilder
              ? projectOther.trim().isNotEmpty
              : project != null) &&
          unitNumber.trim().isNotEmpty &&
          floorNumber.trim().isNotEmpty &&
          !uploadingFloorPlan,
    2 => plan != null,
    3 => slot != null,
    _ => !isSubmitting,
  };

  /// What's missing on the current step, for the snackbar.
  String get missingHint => switch (step) {
    0 => 'Select the city of your property',
    1 => 'Add builder, project, unit and floor',
    2 => 'Choose an inspection plan',
    3 => 'Pick a date and time slot',
    _ => '',
  };

  void next() {
    if (step < stepCount - 1 && canContinue) {
      step++;
      notifyListeners();
    }
  }

  void back() {
    if (step > 0) {
      step--;
      notifyListeners();
    }
  }

  // ── Step 1 ────────────────────────────────────────────────

  void setCity(String value) {
    if (city == value) return;
    city = value;
    builder = null;
    project = null;
    projects = null;
    notifyListeners();
    _loadBuilders();
  }

  Future<void> _loadBuilders() async {
    builders = null;
    notifyListeners();
    try {
      builders = await _master.getBuilders(city: city);
    } on ApiException {
      builders = const [];
    }
    notifyListeners();
  }

  // ── Step 2 ────────────────────────────────────────────────

  Future<void> setBuilder(BuilderModel value) async {
    builder = value;
    useOtherBuilder = false;
    project = null;
    projects = null;
    useOtherProject = false;
    notifyListeners();
    try {
      final all = await _projects.getBuilderProjects(value.id, type: 'Residential');
      // Prefer projects in the chosen city; fall back to all of them.
      final inCity = all.where((p) => p.city.toLowerCase() == city?.toLowerCase()).toList();
      projects = inCity.isEmpty ? all : inCity;
    } on ApiException {
      projects = const [];
    }
    notifyListeners();
  }

  void setUseOtherBuilder(bool value) {
    useOtherBuilder = value;
    if (value) {
      builder = null;
      project = null;
      projects = null;
    }
    notifyListeners();
  }

  void setProject(ProjectSummary value) {
    project = value;
    useOtherProject = false;
    notifyListeners();
  }

  void setUseOtherProject(bool value) {
    useOtherProject = value;
    if (value) project = null;
    notifyListeners();
  }

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  /// Returns the error message on failure.
  Future<String?> uploadFloorPlan(String path, String name) async {
    uploadingFloorPlan = true;
    notifyListeners();
    try {
      floorPlanUrl = await _pdi.uploadFloorPlan(path, name);
      floorPlanName = name;
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      uploadingFloorPlan = false;
      notifyListeners();
    }
  }

  void removeFloorPlan() {
    floorPlanUrl = null;
    floorPlanName = null;
    notifyListeners();
  }

  // ── Step 3 / 4 ────────────────────────────────────────────

  void setPlan(PdiPlan value) {
    plan = value;
    notifyListeners();
  }

  Future<void> setDate(DateTime value) async {
    date = value;
    slot = null;
    slots = null;
    notifyListeners();
    try {
      final result = await _pdi.getSlots(value);
      if (date == value) slots = result;
    } on ApiException {
      if (date == value) slots = const [];
    }
    notifyListeners();
  }

  void setSlot(PdiSlot value) {
    slot = value;
    notifyListeners();
  }

  // ── Step 5 ────────────────────────────────────────────────

  String get builderLabel => useOtherBuilder ? builderOther : builder?.name ?? '';
  String get projectLabel =>
      useOtherProject || useOtherBuilder ? projectOther : project?.name ?? '';

  /// Books the inspection. Returns the booking, or null with [error] set.
  Future<PdiBooking?> submit() async {
    isSubmitting = true;
    error = null;
    notifyListeners();
    try {
      return await _pdi.book(
        city: city!,
        plan: plan!,
        slot: slot!,
        unitNumber: unitNumber.trim(),
        floorNumber: floorNumber.trim(),
        builderId: useOtherBuilder ? null : builder?.id,
        builderOther: useOtherBuilder ? builderOther.trim() : null,
        projectId: useOtherProject || useOtherBuilder ? null : project?.id,
        projectOther: useOtherProject || useOtherBuilder ? projectOther.trim() : null,
        notes: notes.trim(),
        floorPlanUrl: floorPlanUrl,
      );
    } on ApiException catch (e) {
      error = e.message;
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
