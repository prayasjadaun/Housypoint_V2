/// A developer from `GET /api/builders/` (API ref M2).
class BuilderModel {
  const BuilderModel({
    required this.id,
    required this.name,
    this.logoUrl = '',
    this.address = '',
  });

  final int id;
  final String name;
  final String logoUrl;

  /// Head office — only on the detail endpoint (M3).
  final String address;

  factory BuilderModel.fromJson(Map<String, dynamic> json) => BuilderModel(
    // The detail endpoint sends the id as a string.
    id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
    name: json['builder_name']?.toString() ?? '',
    logoUrl: json['builder_logo']?.toString() ?? '',
    address: json['headquaters_address']?.toString() ?? '',
  );

  @override
  bool operator ==(Object other) => other is BuilderModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
