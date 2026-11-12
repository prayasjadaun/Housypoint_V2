/// Resale or rent.
enum DealType { sale, rent }

/// Residential (BHK) or commercial (office, shop, …).
enum PropertyCategory { residential, commercial }

/// `GET /api/listings/counts/` (API ref L3) — how many listings exist per
/// BHK / commercial subtype, split by sale and rent.
class ListingCounts {
  const ListingCounts({
    required this.totalSale,
    required this.totalRent,
    required this.residential,
    required this.commercial,
    required this.byType,
  });

  final int totalSale;
  final int totalRent;

  /// `sale` / `rent` → { studio, one, two, three, four, five_plus }
  final Map<String, Map<String, int>> residential;

  /// `sale` / `rent` → { office, shop, food court, studio, hotel, … }
  final Map<String, Map<String, int>> commercial;

  /// sale_residential, sale_commercial, rent_residential, rent_commercial
  final Map<String, int> byType;

  static const empty = ListingCounts(
    totalSale: 0,
    totalRent: 0,
    residential: {},
    commercial: {},
    byType: {},
  );

  /// Count for one tile, e.g. `count(DealType.sale, PropertyCategory.residential, 'three')`.
  int count(DealType deal, PropertyCategory category, String key) {
    final source = category == PropertyCategory.residential ? residential : commercial;
    return source[deal.name]?[key] ?? 0;
  }

  /// All listings for the selected deal + category.
  int total(DealType deal, PropertyCategory category) =>
      byType['${deal.name}_${category.name}'] ?? 0;

  factory ListingCounts.fromJson(Map<String, dynamic> json) {
    final total = json['total'] as Map<String, dynamic>? ?? {};
    return ListingCounts(
      totalSale: _toInt(total['sale']),
      totalRent: _toInt(total['rent']),
      residential: _nested(json['residential_bhk']),
      commercial: _nested(json['commercial_subtypes']),
      byType: _flat(json['by_type']),
    );
  }

  static Map<String, Map<String, int>> _nested(Object? value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        entry.key.toString(): _flat(entry.value),
    };
  }

  static Map<String, int> _flat(Object? value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries) entry.key.toString(): _toInt(entry.value),
    };
  }

  static int _toInt(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
}
