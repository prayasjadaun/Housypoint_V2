import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../models/master/builder_model.dart';
import '../../models/master/city_model.dart';
import '../../theme/app_colors.dart';
import '../common/selection_sheet.dart';

const _allCities = CityModel(id: 0, name: 'All cities');
const _allBuilders = BuilderModel(id: 0, name: 'All builders');

const _popularCityNames = [
  'Gurgaon',
  'New Delhi',
  'Noida',
  'Mumbai',
  'Bengaluru',
  'Pune',
  'Hyderabad',
  'Dubai',
];

/// Result of a picker: [picked] is false when the sheet was dismissed;
/// otherwise [value] is the choice (null = "All").
typedef PickResult<T> = ({bool picked, T? value});

Future<PickResult<String>> showCityPicker(
  BuildContext context, {
  required List<CityModel> cities,
  required String? selected,
}) async {
  final city = await showSelectionSheet<CityModel>(
    context,
    title: 'Select city',
    subtitle: 'See properties and builders in this city',
    searchHint: 'Search city',
    items: [_allCities, ...cities],
    popular: [
      _allCities,
      for (final name in _popularCityNames) ...cities.where((c) => c.name == name),
    ],
    popularLabel: 'Popular cities',
    allLabel: 'All cities',
    emptyTitle: 'No city found',
    labelOf: (c) => c.name,
    subtitleOf: (c) => c.id == 0 ? 'Everywhere on Housy Point' : c.region,
    isSelected: (c) => c.id == 0 ? selected == null : c.name == selected,
    leadingOf: (c, isSelected) => SelectionLeading(
      selected: isSelected,
      child: Icon(
        c.id == 0 ? Iconsax.global_copy : Iconsax.location_copy,
        size: 20,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
    ),
  );
  if (city == null) return (picked: false, value: null);
  return (picked: true, value: city.id == 0 ? null : city.name);
}

Future<PickResult<BuilderModel>> showBuilderPicker(
  BuildContext context, {
  required List<BuilderModel> builders,
  required BuilderModel? selected,
  required String cityLabel,
}) async {
  final builder = await showSelectionSheet<BuilderModel>(
    context,
    title: 'Select builder',
    subtitle: 'Developers with projects in $cityLabel',
    searchHint: 'Search builder',
    items: [_allBuilders, ...builders],
    emptyTitle: 'No builder found',
    labelOf: (b) => b.name,
    isSelected: (b) => b.id == 0 ? selected == null : b == selected,
    leadingOf: (b, isSelected) => SelectionLeading(
      selected: isSelected,
      child: b.logoUrl.isEmpty
          ? Icon(
              Iconsax.buildings_2_copy,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            )
          : Padding(
              padding: const EdgeInsets.all(4),
              child: Image.network(
                b.logoUrl,
                fit: BoxFit.contain,
                cacheWidth: 120,
                errorBuilder: (_, _, _) => const Icon(
                  Iconsax.buildings_2_copy,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
    ),
  );
  if (builder == null) return (picked: false, value: null);
  return (picked: true, value: builder.id == 0 ? null : builder);
}
