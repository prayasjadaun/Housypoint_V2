import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/utils/app_haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Searchable picker sheet used for country, city and builder selection.
///
/// Resolves to the tapped item, or null when dismissed. Items in [popular]
/// are pinned on top while the search box is empty.
Future<T?> showSelectionSheet<T>(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String searchHint,
  required List<T> items,
  required String Function(T item) labelOf,
  required bool Function(T item) isSelected,
  required Widget Function(T item, bool selected) leadingOf,
  List<T> popular = const [],
  String popularLabel = 'Popular',
  String allLabel = 'All',
  String Function(T item)? subtitleOf,
  String Function(T item)? trailingOf,
  bool Function(T item, String query)? matches,
  String emptyTitle = 'Nothing found',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SelectionSheet<T>(
      title: title,
      subtitle: subtitle,
      searchHint: searchHint,
      items: items,
      popular: popular,
      popularLabel: popularLabel,
      allLabel: allLabel,
      labelOf: labelOf,
      subtitleOf: subtitleOf,
      trailingOf: trailingOf,
      isSelected: isSelected,
      leadingOf: leadingOf,
      matches: matches,
      emptyTitle: emptyTitle,
    ),
  );
}

/// Rounded square that holds a leading icon/flag/logo in sheet rows.
class SelectionLeading extends StatelessWidget {
  const SelectionLeading({super.key, required this.child, this.selected = false});

  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: selected ? AppColors.surface : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: child,
    );
  }
}

class _SelectionSheet<T> extends StatefulWidget {
  const _SelectionSheet({
    required this.title,
    required this.subtitle,
    required this.searchHint,
    required this.items,
    required this.popular,
    required this.popularLabel,
    required this.allLabel,
    required this.labelOf,
    required this.isSelected,
    required this.leadingOf,
    required this.emptyTitle,
    this.subtitleOf,
    this.trailingOf,
    this.matches,
  });

  final String title;
  final String subtitle;
  final String searchHint;
  final List<T> items;
  final List<T> popular;
  final String popularLabel;
  final String allLabel;
  final String Function(T) labelOf;
  final String Function(T)? subtitleOf;
  final String Function(T)? trailingOf;
  final bool Function(T) isSelected;
  final Widget Function(T, bool) leadingOf;
  final bool Function(T, String)? matches;
  final String emptyTitle;

  @override
  State<_SelectionSheet<T>> createState() => _SelectionSheetState<T>();
}

class _SelectionSheetState<T> extends State<_SelectionSheet<T>> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    final matches = widget.matches ??
        (T item, String q) => widget.labelOf(item).toLowerCase().contains(q);
    return widget.items.where((item) => matches(item, q)).toList();
  }

  void _select(T item) {
    AppHaptics.selection();
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.82;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final searching = _query.trim().isNotEmpty;
    final results = _results;
    final showSections = !searching && widget.popular.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        height: height,
        decoration: BoxDecoration(
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
                        Text(widget.title, style: AppTextStyles.title),
                        const SizedBox(height: 2),
                        Text(widget.subtitle, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
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
                  hintText: widget.searchHint,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  prefixIcon: Icon(
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
                          icon: Icon(
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
                  ? _EmptyResults(title: widget.emptyTitle)
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
                        if (showSections) ...[
                          _SectionLabel(widget.popularLabel),
                          for (final item in widget.popular) _tile(item),
                          const SizedBox(height: AppSpacing.sm),
                          _SectionLabel(widget.allLabel),
                        ],
                        for (final item in results) _tile(item),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(T item) {
    final selected = widget.isSelected(item);
    final subtitle = widget.subtitleOf?.call(item) ?? '';
    final trailing = widget.trailingOf?.call(item) ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => _select(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                widget.leadingOf(item, selected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.labelOf(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 15,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                    ],
                  ),
                ),
                if (trailing.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    trailing,
                    style: AppTextStyles.label.copyWith(
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (selected) ...[
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
  const _EmptyResults({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.search_status_copy,
            size: 40,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTextStyles.title.copyWith(fontSize: 15)),
          const SizedBox(height: 2),
          Text('Try a different search', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
