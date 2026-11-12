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
/// are pinned on top while the search box is empty — as a list, or as a grid
/// of small cards when [popularColumns] is set. [imageOf] gives a grid card
/// an asset photo (null = icon card). With 2+ [tabs], a switch under the
/// search box splits the list (e.g. India / Overseas).
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
  int? popularColumns,
  String? Function(T item)? imageOf,
  List<SelectionTab<T>> tabs = const [],
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
      popularColumns: popularColumns,
      imageOf: imageOf,
      tabs: tabs,
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

/// One segment of the sheet's tab switch; [test] says which items it shows.
class SelectionTab<T> {
  const SelectionTab({
    required this.label,
    required this.icon,
    required this.test,
  });

  final String label;
  final IconData icon;
  final bool Function(T item) test;
}

/// Rounded square that holds a leading icon/flag/logo in sheet rows.
class SelectionLeading extends StatelessWidget {
  const SelectionLeading({
    super.key,
    required this.child,
    this.selected = false,
  });

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
    this.popularColumns,
    this.imageOf,
    this.tabs = const [],
    this.subtitleOf,
    this.trailingOf,
    this.matches,
  });

  final String title;
  final String subtitle;
  final String searchHint;
  final List<T> items;
  final List<T> popular;
  final int? popularColumns;
  final String? Function(T)? imageOf;
  final List<SelectionTab<T>> tabs;
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
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // Open on the tab that holds the current selection (e.g. Overseas
    // when Dubai is picked).
    final tabs = widget.tabs;
    final selected = widget.items.where(widget.isSelected).firstOrNull;
    if (tabs.isNotEmpty && selected != null) {
      _tab = tabs.indexWhere((t) => t.test(selected)).clamp(0, tabs.length - 1);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _inTab(T item) => widget.tabs.isEmpty || widget.tabs[_tab].test(item);

  List<T> get _popular => widget.popular.where(_inTab).toList();

  /// Search looks across every tab, so typing "Dubai" on India still finds it.
  List<T> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items.where(_inTab).toList();
    final matches =
        widget.matches ??
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
    final popular = _popular;
    final showSections = !searching && popular.isNotEmpty;
    final showTabs = widget.tabs.length > 1 && !searching;

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
            if (showTabs)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: _TabSwitch(
                  labels: [for (final t in widget.tabs) t.label],
                  icons: [for (final t in widget.tabs) t.icon],
                  index: _tab,
                  onChanged: (i) {
                    AppHaptics.selection();
                    setState(() => _tab = i);
                  },
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
                          if (widget.popularColumns case final columns?)
                            _popularGrid(popular, columns)
                          else
                            for (final item in popular) _tile(item),
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

  Widget _popularGrid(List<T> popular, int columns) {
    const gap = 8.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in popular)
                SizedBox(width: width, child: _card(item)),
            ],
          );
        },
      ),
    );
  }

  /// Small card for a popular item: a photo with the name over it when
  /// [_SelectionSheet.imageOf] has one, otherwise icon on top, name below.
  /// With images on, every card is square so the grid lines up.
  Widget _card(T item) {
    final selected = widget.isSelected(item);
    final image = widget.imageOf?.call(item);
    final radius = BorderRadius.circular(AppRadius.md);
    final label = widget.labelOf(item);

    final Widget content = image != null
        ? Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(image, fit: BoxFit.cover, cacheWidth: 360),
              // Bottom fade keeps the white name readable on any photo
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.35, 1],
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selected)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.tick_circle,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.leadingOf(item, selected),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12.5,
                    color: selected
                        ? AppColors.primaryText
                        : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          );

    final card = Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          width: selected && image != null ? 2 : 1,
          color: selected
              ? AppColors.primary.withValues(alpha: image != null ? 1 : 0.5)
              : AppColors.border.withValues(alpha: 0.7),
        ),
      ),
      // Ripple sits above the photo
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          content,
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: () => _select(item)),
            ),
          ),
        ],
      ),
    );

    return widget.imageOf == null
        ? card
        : AspectRatio(aspectRatio: 1, child: card);
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
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
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
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
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

/// Segmented pill switch — the selected segment slides under the label.
class _TabSwitch extends StatelessWidget {
  const _TabSwitch({
    required this.labels,
    required this.icons,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final List<IconData> icons;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final count = labels.length;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment(
              count == 1 ? 0 : -1 + 2 * index / (count - 1),
              0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / count,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),
          // Poori height lo — warna Row top par baithti hai aur text pill
          // ke beech me nahi aata
          Positioned.fill(
            child: Row(
              children: [
                for (var i = 0; i < count; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: i == index ? null : () => onChanged(i),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icons[i],
                            size: 16,
                            color: i == index
                                ? AppColors.surface
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.w600,
                              color: i == index
                                  ? AppColors.surface
                                  : AppColors.textSecondary,
                            ),
                            child: Text(labels[i]),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
