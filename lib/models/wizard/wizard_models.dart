String _str(Object? v) {
  final s = v?.toString().trim() ?? '';
  return s == 'null' ? '' : s;
}

/// A unit type in a project — `wizard/projects/{id}/configurations/` (W4).
class UnitConfiguration {
  const UnitConfiguration({required this.id, required this.detail, required this.size, required this.bhk});

  final int id;
  final String detail; // "3 BHK"
  final String size; // "1626"
  final String bhk;

  String get label => size.isEmpty ? detail : '$detail · $size sqft';

  factory UnitConfiguration.fromJson(Map<String, dynamic> json) => UnitConfiguration(
    id: int.tryParse(_str(json['id'])) ?? 0,
    detail: _str(json['detail']),
    size: _str(json['size']),
    bhk: _str(json['bhk']),
  );
}

/// A builder-provided project photo — `wizard/projects/{id}/images/` (W5).
class ProjectImage {
  const ProjectImage({required this.id, required this.url});

  final int id;
  final String url;

  static const _cdn = 'https://housymediabucket.blr1.cdn.digitaloceanspaces.com/media/';

  factory ProjectImage.fromJson(Map<String, dynamic> json) {
    var url = _str(json['image_url']).isNotEmpty ? _str(json['image_url']) : _str(json['image']);
    // Relative paths live on the media CDN.
    if (url.isNotEmpty && !url.startsWith('http')) {
      url = '$_cdn${url.startsWith('/') ? url.substring(1) : url}';
    }
    return ProjectImage(id: int.tryParse(_str(json['id'])) ?? 0, url: url);
  }
}

/// Fixed option lists from V1's wizards.
class WizardOptions {
  WizardOptions._();

  static const residentialSubtypes = ['Apartment', 'Floor', 'Villa', 'Penthouse', 'Plot'];
  static const commercialSubtypes = [
    'Office Space', 'Shop', 'Food Court', 'Studio Apartment', 'Hotel',
    'Cinema Hall', 'Restaurant', 'Warehouse', 'Plot',
  ];
  static const facings = [
    'North', 'North East', 'North West', 'South', 'South East', 'South West', 'East', 'West',
  ];
  static const plotFacings = [...facings, 'Sher Mukhi', 'Gau Mukhi', 'T Point', 'Trikona'];
  static const residentialFurnishing = ['Raw', 'Semi Furnished', 'Furnished'];
  static const commercialFurnishing = ['Warmshell (Raw)', 'Furnished'];
  static const plotConstruction = ['Raw', 'Built Up'];

  // Buy requirement
  static const buySources = ['Resale', 'New Launch'];
  static const bhkOptions = ['1', '2', '3', '4', '5+'];
  static const commercialStatus = ['Pre-leased', 'Under Construction', 'Ready to Move'];
  static const usage = ['Self Use', 'Investment', 'Rental Income'];
  static const timelines = ['Immediately', '1-3 Months', '3-6 Months', '6+ Months'];

  /// "Office Space" → "office" (API value), "Food Court" → "food court".
  static String apiSubtype(String label) {
    final l = label.toLowerCase();
    if (l == 'office space') return 'office';
    if (l == 'cinema hall') return 'cinema';
    if (l == 'studio apartment') return 'studio';
    return l;
  }

  /// "Semi Furnished" → "semi-furnished"; "Warmshell (Raw)" → "raw".
  static String apiFurnishing(String label) =>
      label.toLowerCase().contains('raw') ? 'raw' : label.toLowerCase().replaceAll(' ', '-');
}
