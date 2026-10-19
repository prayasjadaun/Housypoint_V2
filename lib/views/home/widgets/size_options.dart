import 'package:flutter/widgets.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// A BHK size or commercial subtype, keyed like the counts API.
class SizeOption {
  const SizeOption({required this.key, required this.label, this.icon});

  /// Key in the counts API, e.g. `three`, `office`.
  final String key;
  final String label;
  final IconData? icon;
}

const residentialTiles = [
  SizeOption(key: 'one', label: '1 BHK'),
  SizeOption(key: 'two', label: '2 BHK'),
  SizeOption(key: 'three', label: '3 BHK'),
  SizeOption(key: 'four', label: '4 BHK'),
  SizeOption(key: 'five_plus', label: '5+ BHK'),
  SizeOption(key: 'studio', label: 'Studio', icon: Iconsax.lamp_on_copy),
];

const commercialTiles = [
  SizeOption(key: 'office', label: 'Office', icon: Iconsax.building_4_copy),
  SizeOption(key: 'shop', label: 'Shop', icon: Iconsax.shop_copy),
  SizeOption(key: 'food court', label: 'Food court', icon: Iconsax.coffee_copy),
  SizeOption(key: 'restaurant', label: 'Restaurant', icon: Iconsax.reserve_copy),
  SizeOption(key: 'hotel', label: 'Hotel', icon: Iconsax.building_3_copy),
  SizeOption(key: 'studio', label: 'Studio', icon: Iconsax.video_square_copy),
  SizeOption(key: 'cinema', label: 'Cinema', icon: Iconsax.video_play_copy),
  SizeOption(key: 'warehouse', label: 'Warehouse', icon: Iconsax.box_copy),
  SizeOption(key: 'plot', label: 'Plot', icon: Iconsax.map_1_copy),
];
