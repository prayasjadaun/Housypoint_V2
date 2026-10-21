import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../models/search/search_results.dart';
import '../../repositories/project_repository.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/empty_state.dart';
import 'dart:async';

/// Global search across properties, projects and builders (API ref M7).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  SearchResults? _results;
  bool _loading = false;
  String? _error;
  String _lastQuery = '';

  static const _suggestions = [
    'DLF',
    'M3M',
    'Godrej',
    'Sector 65',
    'Golf Course Road',
    'Noida',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
    setState(() {});
  }

  Future<void> _search(String raw) async {
    final query = raw.trim();
    if (query.length < 2) {
      setState(() {
        _results = null;
        _error = null;
      });
      return;
    }
    _lastQuery = query;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await context.read<ProjectRepository>().search(query);
      if (mounted && query == _lastQuery) setState(() => _results = results);
    } on ApiException catch (e) {
      if (mounted && query == _lastQuery) setState(() => _error = e.message);
    } finally {
      if (mounted && query == _lastQuery) setState(() => _loading = false);
    }
  }

  void _open(SearchHit hit) {
    if (hit.builderId != null) {
      context.push(AppRoutes.builderPath(hit.builderId!));
    } else if (hit.projectId != null) {
      context.push(AppRoutes.projectPath(hit.projectId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final results = _results;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.fromLTRB(8, top + 8, AppSpacing.md, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    CupertinoIcons.back,
                    color: AppColors.textPrimary,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: _onChanged,
                    onSubmitted: _search,
                    textInputAction: TextInputAction.search,
                    style: AppTextStyles.body.copyWith(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search projects, builders, localities',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      prefixIcon: const Icon(
                        Iconsax.search_normal_1_copy,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _controller.clear();
                                _onChanged('');
                              },
                              icon: const Icon(
                                Iconsax.close_circle_copy,
                                size: 18,
                                color: AppColors.textTertiary,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primary,
              backgroundColor: Colors.transparent,
            ),
          Expanded(
            child: results == null && _error == null
                ? ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Text(
                        'Popular searches',
                        style: AppTextStyles.title.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 5,
                        runSpacing: 0,
                        children: [
                          for (final s in _suggestions)
                            ActionChip(
                              avatar: const Icon(
                                Iconsax.trend_up_copy,
                                size: 15,
                                color: AppColors.primary,
                              ),
                              label: Text(s, style: AppTextStyles.label),
                              backgroundColor: AppColors.surface,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              onPressed: () {
                                _controller.text = s;
                                _search(s);
                              },
                            ),
                        ],
                      ),
                    ],
                  )
                : _error != null
                ? Center(
                    child: EmptyState(
                      icon: Iconsax.warning_2_copy,
                      title: 'Search failed',
                      message: _error!,
                    ),
                  )
                : results!.isEmpty
                ? const Center(
                    child: EmptyState(
                      icon: Iconsax.search_status_copy,
                      title: 'No results',
                      message: 'Try a project, builder or locality name.',
                    ),
                  )
                : ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
                    ),
                    children: [
                      _Section(
                        title: 'Projects',
                        hits: results.projects,
                        onTap: _open,
                      ),
                      _Section(
                        title: 'Builders',
                        hits: results.builders,
                        onTap: _open,
                      ),
                      _Section(
                        title: 'Properties',
                        hits: results.properties,
                        onTap: _open,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.hits,
    required this.onTap,
  });

  final String title;
  final List<SearchHit> hits;
  final ValueChanged<SearchHit> onTap;

  @override
  Widget build(BuildContext context) {
    if (hits.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Text(
              title.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < hits.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 66,
                      color: AppColors.border,
                    ),
                  ListTile(
                    onTap: () => onTap(hits[i]),
                    leading: Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.7),
                        ),
                      ),
                      child: AppNetworkImage(
                        url: hits[i].image,
                        fit: BoxFit.contain,
                        fallbackIcon: hits[i].kind == 'builder'
                            ? Iconsax.buildings_2_copy
                            : Iconsax.building_copy,
                      ),
                    ),
                    title: Text(
                      hits[i].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: hits[i].subtitle.isEmpty
                        ? null
                        : Text(
                            hits[i].subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                    trailing: const Icon(
                      Iconsax.arrow_right_3_copy,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
