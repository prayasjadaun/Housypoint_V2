import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/master/builder_model.dart';
import '../models/project/project_model.dart';
import '../models/wizard/wizard_models.dart';
import '../repositories/master_data_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/wizard_repository.dart';

/// Sell / rent-out wizard: type → project → details → photos → price → review.
/// Builds the same request body V1 sends (API ref W7/W8).
class PostPropertyController extends ChangeNotifier {
  PostPropertyController(this._wizard, this._master, this._projects, {required this.isRent}) {
    _loadBuilders();
  }

  final WizardRepository _wizard;
  final MasterDataRepository _master;
  final ProjectRepository _projects;

  /// Rent-out flow instead of sell.
  final bool isRent;

  static const stepTitles = ['Type', 'Project', 'Details', 'Photos', 'Price', 'Review'];
  int get stepCount => stepTitles.length;
  int step = 0;

  // Type
  bool isCommercial = false;
  String? subtype;
  bool get isPlot => subtype == 'Plot';

  // Project
  List<BuilderModel>? builders;
  BuilderModel? builder;
  bool otherBuilder = false;
  String builderOther = '';
  List<ProjectSummary>? projects;
  ProjectSummary? project;
  bool otherProject = false;
  String projectOther = '';
  String location = '';
  String city = '';

  // Details
  List<UnitConfiguration>? configurations;
  UnitConfiguration? configuration;
  String bhkOther = '';
  String sizeOther = '';
  String unitNumber = '';
  String tower = '';
  String floor = '';
  String? facing;
  String? furnishing;
  String plotArea = '';
  String plotDimensions = '';
  String? plotConstruction;

  // Photos
  List<ProjectImage>? projectImages;
  final Set<int> selectedProjectImages = {};
  final List<String> customImages = [];

  // Price
  String price = ''; // asking price or monthly rent
  String deposit = '';
  String maintenance = '';
  bool negotiable = false;
  bool corporateLeasing = false;
  bool currentlyRented = false;
  String lockIn = '';
  String leaseDuration = '';

  bool isSubmitting = false;
  String? error;

  bool get _customProject => otherBuilder || otherProject;
  List<String> get subtypes =>
      isCommercial ? WizardOptions.commercialSubtypes : WizardOptions.residentialSubtypes;
  List<String> get furnishingOptions =>
      isCommercial ? WizardOptions.commercialFurnishing : WizardOptions.residentialFurnishing;

  String get builderLabel => otherBuilder ? builderOther : builder?.name ?? '';
  String get projectLabel => _customProject ? projectOther : project?.name ?? '';

  // ── Navigation ────────────────────────────────────────────

  bool get canContinue => switch (step) {
    0 => subtype != null,
    1 =>
      (otherBuilder ? builderOther.trim().isNotEmpty : builder != null) &&
          (_customProject ? projectOther.trim().isNotEmpty && city.trim().isNotEmpty : project != null),
    2 => isPlot
        ? plotArea.trim().isNotEmpty && facing != null
        : (configuration != null || bhkOther.trim().isNotEmpty || sizeOther.trim().isNotEmpty) &&
              unitNumber.trim().isNotEmpty &&
              floor.trim().isNotEmpty,
    3 => selectedProjectImages.isNotEmpty || customImages.isNotEmpty,
    4 => (num.tryParse(price) ?? 0) > 0,
    _ => !isSubmitting,
  };

  String get missingHint => switch (step) {
    0 => 'Choose the property type',
    1 => 'Add builder and project${_customProject ? ' with city' : ''}',
    2 => isPlot ? 'Add plot area and facing' : 'Add configuration, unit and floor',
    3 => 'Add at least one photo',
    4 => isRent ? 'Enter the monthly rent' : 'Enter your asking price',
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

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  // ── Type ──────────────────────────────────────────────────

  void setCommercial(bool value) {
    if (isCommercial == value) return;
    isCommercial = value;
    subtype = null;
    furnishing = null;
    notifyListeners();
  }

  // ── Project ───────────────────────────────────────────────

  Future<void> _loadBuilders() async {
    try {
      builders = await _master.getBuilders();
    } on ApiException {
      builders = const [];
    }
    notifyListeners();
  }

  Future<void> setBuilder(BuilderModel value) async {
    builder = value;
    otherBuilder = false;
    project = null;
    projects = null;
    otherProject = false;
    _resetProjectData();
    notifyListeners();
    try {
      projects = await _projects.getBuilderProjects(value.id);
    } on ApiException {
      projects = const [];
    }
    notifyListeners();
  }

  Future<void> setProject(ProjectSummary value) async {
    project = value;
    otherProject = false;
    _resetProjectData();
    notifyListeners();
    // Configurations and builder photos are per project.
    try {
      final results = await Future.wait([
        _wizard.getConfigurations(value.id),
        _wizard.getProjectImages(value.id),
      ]);
      if (project?.id != value.id) return;
      configurations = results[0] as List<UnitConfiguration>;
      projectImages = results[1] as List<ProjectImage>;
    } on ApiException {
      configurations = const [];
      projectImages = const [];
    }
    notifyListeners();
  }

  void setOtherBuilder(bool value) {
    otherBuilder = value;
    if (value) {
      builder = null;
      project = null;
      projects = null;
      _resetProjectData();
    }
    notifyListeners();
  }

  void setOtherProject(bool value) {
    otherProject = value;
    if (value) {
      project = null;
      _resetProjectData();
    }
    notifyListeners();
  }

  void _resetProjectData() {
    configurations = null;
    configuration = null;
    projectImages = null;
    selectedProjectImages.clear();
  }

  // ── Photos ────────────────────────────────────────────────

  void toggleProjectImage(int id) {
    selectedProjectImages.contains(id) ? selectedProjectImages.remove(id) : selectedProjectImages.add(id);
    notifyListeners();
  }

  void addCustomImages(Iterable<String> paths) {
    customImages.addAll(paths.where((p) => !customImages.contains(p)));
    notifyListeners();
  }

  void removeCustomImage(String path) {
    customImages.remove(path);
    notifyListeners();
  }

  // ── Submit ────────────────────────────────────────────────

  Future<bool> submit() async {
    isSubmitting = true;
    error = null;
    notifyListeners();
    try {
      final imageIds = await _wizard.uploadImages(customImages);
      await _wizard.submitListing(_body(imageIds), rental: isRent);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _body(List<int> customImageIds) {
    final amount = num.tryParse(price) ?? 0;
    final body = <String, dynamic>{
      'property_type': isCommercial ? 'commercial' : 'residential',
      if (isCommercial)
        'commercial_subtype': WizardOptions.apiSubtype(subtype!)
      else
        'residential_subtype': WizardOptions.apiSubtype(subtype!),
      'price_negotiable': negotiable,
      if (otherBuilder) 'builder_other': builderOther.trim() else 'builder_id': builder!.id,
      if (_customProject) 'project_other': projectOther.trim() else 'project_id': project!.id,
      if (_customProject) ...{'location': location.trim(), 'city': city.trim(), 'country': 'India'},
      if (selectedProjectImages.isNotEmpty) 'selected_project_images': selectedProjectImages.toList(),
      if (customImageIds.isNotEmpty) 'custom_image_ids': customImageIds,
    };

    if (isPlot) {
      body['plot_area'] = int.tryParse(plotArea.trim()) ?? plotArea.trim();
      body['plot_dimensions'] = plotDimensions.trim();
      body['plot_exit_location'] = facing?.toLowerCase();
      body['plot_construction'] = plotConstruction?.toLowerCase();
    } else {
      body['unit_number'] = unitNumber.trim();
      body['block_tower'] = tower.trim();
      body['floor_number'] = floor.trim();
      body['exit_location'] = facing?.toLowerCase();
      if (furnishing != null) {
        body[isCommercial ? 'commercial_furnishing' : 'furnishing'] = WizardOptions.apiFurnishing(furnishing!);
      }
      if (configuration != null) {
        body['configuration_id'] = configuration!.id;
        body['has_config_id'] = true;
      } else {
        body['has_config_id'] = false;
        if (bhkOther.trim().isNotEmpty) body['config_bhk_other'] = bhkOther.trim();
        if (sizeOther.trim().isNotEmpty) {
          body['config_size_other'] = sizeOther.trim();
          body['config_size_other_unit_type'] = 'sqft';
        }
      }
    }

    if (isRent) {
      body['rent_price'] = amount;
      body['security_deposit'] = num.tryParse(deposit) ?? 0;
      body['maintenance'] = num.tryParse(maintenance) ?? 0;
      body['corporate_leasing_interest'] = corporateLeasing;
      body['description'] = 'Property listed through Housy Point app';
      if (currentlyRented) {
        body['currently_rented'] = 'yes';
        if (lockIn.isNotEmpty) body['lockin_period'] = int.tryParse(lockIn) ?? 0;
        if (leaseDuration.isNotEmpty) body['lease_duration'] = int.tryParse(leaseDuration) ?? 0;
      }
    } else {
      body['asking_price'] = amount;
    }
    return body;
  }
}
