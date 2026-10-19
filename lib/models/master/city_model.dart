/// A city from `GET /api/cities/` (API ref M1).
class CityModel {
  const CityModel({
    required this.id,
    required this.name,
    this.state = '',
    this.country = '',
  });

  final int id;
  final String name;
  final String state;
  final String country;

  /// "Haryana, India" — shown under the name in pickers.
  String get region => [state, country].where((p) => p.isNotEmpty).join(', ');

  factory CityModel.fromJson(Map<String, dynamic> json) {
    final state = json['state'] as Map<String, dynamic>?;
    final country = state?['country'] as Map<String, dynamic>?;
    return CityModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      state: state?['name']?.toString() ?? '',
      country: country?['name']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) => other is CityModel && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
