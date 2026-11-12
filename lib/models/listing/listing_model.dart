import '../../core/utils/formatters.dart';

/// A resale or rental listing from `listings/properties/` or
/// `listings/rentals/` (API ref L1/L2). Same shape for both; rentals carry
/// rent / deposit / maintenance instead of an asking price.
class ListingModel {
  const ListingModel({
    required this.id,
    required this.isRental,
    required this.propertyType,
    required this.subtype,
    required this.price,
    required this.images,
    this.projectId,
    this.projectName = '',
    this.projectLogo = '',
    this.projectStatus = '',
    this.builderName = '',
    this.builderLogo = '',
    this.location = '',
    this.city = '',
    this.sector = '',
    this.bhk = '',
    this.size = '',
    this.sizeUnit = 'sqft',
    this.marketPrice = '',
    this.layoutImage = '',
    this.furnishing = '',
    this.floor = '',
    this.unitNumber = '',
    this.tower = '',
    this.facing = '',
    this.description = '',
    this.negotiable = false,
    this.securityDeposit,
    this.maintenance,
    this.corporateLeasing = false,
    this.isWishlisted = false,
    this.isInterested = false,
    this.createdAt,
  });

  final int id;
  final bool isRental;

  /// `residential` / `commercial`
  final String propertyType;

  /// apartment, floor, villa… or office, shop…
  final String subtype;

  /// Asking price (sale) or monthly rent (rental).
  final double price;
  final List<String> images;

  final int? projectId;
  final String projectName;
  final String projectLogo;
  final String projectStatus;
  final String builderName;
  final String builderLogo;
  final String location;
  final String city;
  final String sector;

  final String bhk;
  final String size;
  final String sizeUnit;
  final String marketPrice;
  final String layoutImage;

  final String furnishing;
  final String floor;
  final String unitNumber;
  final String tower;
  final String facing;
  final String description;
  final bool negotiable;

  final double? securityDeposit;
  final double? maintenance;
  final bool corporateLeasing;

  final bool isWishlisted;
  final bool isInterested;
  final DateTime? createdAt;

  bool get isCommercial => propertyType == 'commercial';

  /// "3 BHK Apartment" / "Office space"
  String get title {
    final kind = Formatters.humanize(subtype);
    if (!isCommercial && bhk.isNotEmpty) {
      return '$bhk BHK${kind.isEmpty ? '' : ' $kind'}';
    }
    return kind.isEmpty ? (isCommercial ? 'Commercial space' : 'Property') : kind;
  }

  /// "₹3 Cr" / "₹40,000/mo"
  String get priceLabel =>
      isRental ? '${Formatters.price(price)}/mo' : Formatters.price(price);

  String get areaLabel => size.isEmpty ? '' : '$size $sizeUnit';

  /// "Sector 61, Gurgaon"
  String get place {
    final parts = [
      if (sector.isNotEmpty) 'Sector $sector',
      if (city.isNotEmpty) city,
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    return location;
  }

  String get coverImage => images.isEmpty ? '' : images.first;

  ListingModel copyWith({bool? isWishlisted, bool? isInterested}) => ListingModel(
    id: id,
    isRental: isRental,
    propertyType: propertyType,
    subtype: subtype,
    price: price,
    images: images,
    projectId: projectId,
    projectName: projectName,
    projectLogo: projectLogo,
    projectStatus: projectStatus,
    builderName: builderName,
    builderLogo: builderLogo,
    location: location,
    city: city,
    sector: sector,
    bhk: bhk,
    size: size,
    sizeUnit: sizeUnit,
    marketPrice: marketPrice,
    layoutImage: layoutImage,
    furnishing: furnishing,
    floor: floor,
    unitNumber: unitNumber,
    tower: tower,
    facing: facing,
    description: description,
    negotiable: negotiable,
    securityDeposit: securityDeposit,
    maintenance: maintenance,
    corporateLeasing: corporateLeasing,
    isWishlisted: isWishlisted ?? this.isWishlisted,
    isInterested: isInterested ?? this.isInterested,
    createdAt: createdAt,
  );

  factory ListingModel.fromJson(Map<String, dynamic> json, {bool? isRental}) {
    final rental = isRental ?? json.containsKey('rent_price');
    final project = json['project'] as Map<String, dynamic>?;
    final builder = (json['builder'] ?? project?['builder']) as Map<String, dynamic>?;
    final config = json['configuration'] as Map<String, dynamic>?;
    final isCommercial = json['property_type'] == 'commercial';

    final images = <String>[
      for (final url in json['image_urls'] as List? ?? const [])
        if (url is String && url.isNotEmpty) url,
    ];
    final projectImage =
        (project?['first_image'] as Map<String, dynamic>?)?['image_url'] as String?;
    if (images.isEmpty && projectImage != null) images.add(projectImage);

    String str(Object? v) => v?.toString().trim() ?? '';

    return ListingModel(
      id: json['id'] as int,
      isRental: rental,
      propertyType: str(json['property_type']),
      subtype: str(isCommercial ? json['commercial_subtype'] : json['residential_subtype']),
      price: _toDouble(rental ? json['rent_price'] : json['asking_price']) ?? 0,
      images: images,
      projectId: project?['id'] as int?,
      projectName: str(project?['name']).isNotEmpty
          ? str(project?['name'])
          : str(json['project_other']),
      projectLogo: str(project?['project_logo_url'] ?? project?['project_logo_image']),
      projectStatus: str(project?['project_status']),
      builderName: str(builder?['builder_name']).isNotEmpty
          ? str(builder?['builder_name'])
          : str(json['builder_other']),
      builderLogo: str(builder?['builder_logo']),
      location: str(project?['location']).isNotEmpty
          ? str(project?['location'])
          : str(json['location']),
      city: str(project?['city_name']).isNotEmpty
          ? str(project?['city_name'])
          : str(json['city']),
      sector: str(project?['sector']).isNotEmpty
          ? str(project?['sector'])
          : str(json['sector']),
      bhk: str(config?['bhk']).isNotEmpty ? str(config?['bhk']) : str(json['config_bhk_other']),
      size: str(config?['size']).isNotEmpty ? str(config?['size']) : str(json['config_size_other']),
      sizeUnit: str(json['config_size_other_unit_type']).isEmpty
          ? 'sqft'
          : str(json['config_size_other_unit_type']),
      marketPrice: str(config?['market_price']),
      layoutImage: str(config?['layout_image_url'] ?? config?['layout_image']),
      furnishing: str(json['furnishing'] ?? json['commercial_furnishing']),
      floor: str(json['floor_number']),
      unitNumber: str(json['unit_number']),
      tower: str(json['block_tower']),
      facing: str(json['exit_location']),
      description: str(json['description']),
      negotiable: json['price_negotiable'] == true,
      securityDeposit: _toDouble(json['security_deposit']),
      maintenance: _toDouble(json['maintenance']),
      corporateLeasing: json['corporate_leasing_interest'] == true,
      isWishlisted: json['is_wishlisted'] == true,
      isInterested: json['is_interested'] == true,
      createdAt: DateTime.tryParse(str(json['created_at'])),
    );
  }

  static double? _toDouble(Object? v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');
}
