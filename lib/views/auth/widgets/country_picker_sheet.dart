import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

import '../../../widgets/common/selection_sheet.dart';

final List<Country> _all = CountryService().getAll()
  ..sort((a, b) => a.name.compareTo(b.name));

const _popularCodes = ['IN', 'AE', 'US', 'GB', 'SG', 'CA', 'AU'];

/// Country list for the phone field. Data comes from `country_picker`,
/// the UI is the shared [showSelectionSheet].
Future<Country?> showCountryPickerSheet(
  BuildContext context, {
  required Country selected,
}) {
  return showSelectionSheet<Country>(
    context,
    title: 'Select country',
    subtitle: 'Where is your mobile number registered?',
    searchHint: 'Search country or code',
    items: _all,
    popular: [
      for (final code in _popularCodes)
        ..._all.where((c) => c.countryCode == code),
    ],
    allLabel: 'All countries',
    emptyTitle: 'No country found',
    labelOf: (c) => c.name,
    trailingOf: (c) => '+${c.phoneCode}',
    isSelected: (c) => c.countryCode == selected.countryCode,
    leadingOf: (c, isSelected) => SelectionLeading(
      selected: isSelected,
      child: Text(c.flagEmoji, style: const TextStyle(fontSize: 22)),
    ),
    // Name, ISO code or dialling code (with or without `+`).
    matches: (c, q) {
      final code = q.replaceFirst('+', '');
      return c.name.toLowerCase().contains(q) ||
          c.countryCode.toLowerCase() == q ||
          (code.isNotEmpty && c.phoneCode.startsWith(code));
    },
  );
}
