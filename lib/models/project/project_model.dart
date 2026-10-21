/// Project card data — new launches (`new-launch/all/`, API ref C5) and
/// project lists (`projects/`, `builders/{id}/projects/`, M4/M5).
class ProjectSummary {
  const ProjectSummary({
    required this.id,
    required this.name,
    this.image = '',
    this.logo = '',
    this.city = '',
    this.builderName = '',
    this.builderLogo = '',
    this.priceRange = '',
    this.projectType = '',
    this.status = '',
    this.isNewLaunch = false,
    this.location = '',
  });

  final int id;
  final String name;
  final String image;
  final String logo;
  final String city;
  final String builderName;
  final String builderLogo;
  final String priceRange;
  final String projectType;
  final String status;
  final bool isNewLaunch;
  final String location;

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    String str(Object? v) => v?.toString().trim() ?? '';
    final builder = json['builder'];
    final city = json['city'];
    final firstImage = json['first_image'];
    return ProjectSummary(
      id: int.parse(json['id'].toString()),
      name: str(json['name']),
      image: str(json['first_image_url']).isNotEmpty
          ? str(json['first_image_url'])
          : firstImage is Map ? str(firstImage['image_url']) : '',
      logo: str(json['project_logo_url'] ?? json['project_logo_image']),
      city: city is Map ? str(city['name']) : str(json['city_name'] ?? city),
      builderName: builder is Map ? str(builder['builder_name']) : '',
      builderLogo: str(json['builder_logo_url']).isNotEmpty
          ? str(json['builder_logo_url'])
          : builder is Map ? str(builder['builder_logo']) : '',
      priceRange: str(json['overview_price_range']),
      projectType: str(json['project_type']),
      status: str(json['project_status']),
      isNewLaunch: json['new_launch'] == true,
      location: str(json['location']),
    );
  }
}

class ProjectConfiguration {
  const ProjectConfiguration({
    required this.detail,
    required this.size,
    this.marketPrice = '',
    this.layoutImage = '',
  });

  final String detail; // "2 BHK"
  final String size; // "1100"
  final String marketPrice; // "2.2 Cr"
  final String layoutImage;

  factory ProjectConfiguration.fromJson(Map<String, dynamic> json) =>
      ProjectConfiguration(
        detail: json['detail']?.toString() ?? '',
        size: json['size']?.toString() ?? '',
        marketPrice: json['market_price']?.toString() ?? '',
        layoutImage: (json['layout_image_url'] ?? json['layout_image'])?.toString() ?? '',
      );
}

class Amenity {
  const Amenity({required this.name, this.icon = ''});

  final String name;
  final String icon;
}

class Landmark {
  const Landmark({required this.name, required this.distance});

  final String name;
  final String distance;
}

/// Full project — `GET /api/projects/{id}/` (API ref M6).
class ProjectDetail {
  const ProjectDetail({
    required this.summary,
    required this.images,
    required this.configurations,
    required this.amenities,
    required this.landmarks,
    this.location = '',
    this.sector = '',
    this.about = '',
    this.rera = '',
    this.paymentPlan = '',
    this.mapEmbedUrl = '',
    this.brochureUrl = '',
    this.masterLayout = '',
  });

  final ProjectSummary summary;
  final List<String> images;
  final List<ProjectConfiguration> configurations;
  final List<Amenity> amenities;
  final List<Landmark> landmarks;
  final String location;
  final String sector;
  final String about;
  final String rera;
  final String paymentPlan;
  final String mapEmbedUrl;
  final String brochureUrl;
  final String masterLayout;

  /// Google Maps link the user can open (the API gives an embed URL).
  String get mapsSearchUrl =>
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${summary.name} ${summary.city}')}';

  /// Google Maps turn-by-turn directions to the project.
  String get directionsUrl =>
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent('${summary.name} ${summary.city}')}';

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    String str(Object? v) {
      final s = v?.toString().trim() ?? '';
      return s == '0' || s == 'null' ? '' : s;
    }

    return ProjectDetail(
      summary: ProjectSummary.fromJson(json),
      images: [
        for (final img in json['images'] as List? ?? const [])
          if (img is Map && str(img['image_url'] ?? img['image']).isNotEmpty)
            str(img['image_url'] ?? img['image']),
      ],
      configurations: [
        for (final c in json['project_configurations'] as List? ?? const [])
          ProjectConfiguration.fromJson(c as Map<String, dynamic>),
      ],
      amenities: [
        for (final a in json['amenities'] as List? ?? const [])
          if (a is Map) Amenity(name: str(a['name']), icon: str(a['image'])),
      ],
      landmarks: [
        for (final l in json['landmarks'] as List? ?? const [])
          if (l is Map) Landmark(name: str(l['name']), distance: str(l['distance'])),
      ],
      location: str(json['location']),
      sector: str(json['sector']),
      about: str(json['project_about']),
      rera: str(json['overview_rera_details']),
      paymentPlan: str(json['overview_payment_plan']),
      mapEmbedUrl: str(json['location_map_link']),
      brochureUrl: str(json['brochure_file_url'] ?? json['brochure_file']),
      masterLayout: str(json['master_layout_image_url'] ?? json['master_layout_image']),
    );
  }
}
