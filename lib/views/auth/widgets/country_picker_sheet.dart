import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Opens the country list as a bottom sheet; resolves to the picked country
/// (or null if dismissed). Data comes from `country_picker`, UI is ours.
Future<Country?> showCountryPickerSheet(
  BuildContext context, {
  required Country selected,
}) {
  return showModalBottomSheet<Country>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CountryPickerSheet(selected: selected),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.selected});

  final Country selected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  static const _popularCodes = ['IN', 'AE', 'US', 'GB', 'SG', 'CA', 'AU'];

  static final List<Country> _all = CountryService().getAll()
    ..sort((a, b) => a.name.compareTo(b.name));

  static final List<Country> _popular = [
    for (final code in _popularCodes) ..._all.where((c) => c.countryCode == code),
  ];

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Matches name, ISO code or dialling code (with or without `+`).
  List<Country> get _results {
    final q = _query.trim().toLowerCase().replaceFirst('+', '');
    if (q.isEmpty) return _all;
    return _all
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.countryCode.toLowerCase() == q ||
              c.phoneCode.startsWith(q),
        )
        .toList();
  }

  void _select(Country country) {
    AppHaptics.selection();
    Navigator.pop(context, country);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.82;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final searching = _query.trim().isNotEmpty;
    final results = _results;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select country', style: AppTextStyles.title),
                        const SizedBox(height: 2),
                        Text(
                          'Where is your mobile number registered?',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Iconsax.close_circle_copy,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                style: AppTextStyles.body.copyWith(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search country or code',
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  prefixIcon: const Icon(
                    Iconsax.search_normal_1_copy,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: searching
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(
                            Iconsax.close_circle_copy,
                            size: 18,
                            color: AppColors.textTertiary,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: results.isEmpty
                  ? const _EmptyResults()
                  : ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        MediaQuery.paddingOf(context).bottom + AppSpacing.md,
                      ),
                      children: [
                        if (!searching) ...[
                          const _SectionLabel('Popular'),
                          for (final c in _popular) _tile(c),
                          const SizedBox(height: AppSpacing.sm),
                          const _SectionLabel('All countries'),
                        ],
                        for (final c in results) _tile(c),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(Country country) {
    final isSelected = country.countryCode == widget.selected.countryCode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isSelected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => _select(country),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.surface : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
                  ),
                  child: Text(country.flagEmoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    country.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '+${country.phoneCode}',
                  style: AppTextStyles.label.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Iconsax.tick_circle_copy,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, AppSpacing.sm, 10, AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Iconsax.global_copy, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.sm),
          Text('No country found', style: AppTextStyles.title.copyWith(fontSize: 15)),
          const SizedBox(height: 2),
          Text('Try a different name or code', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
