import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_list_entry_card.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:craftquest_app/features/prep_plus/presentation/prep_plus_item_detail_page.dart';
import 'package:craftquest_app/features/prep_plus/presentation/widgets/prep_plus_filters_sheet.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class PrepPlusCategoryPage extends StatefulWidget {
  const PrepPlusCategoryPage({
    super.key,
    required this.category,
    required this.showInstitutionFilter,
  });

  final PrepCategoryModel category;
  final bool showInstitutionFilter;

  @override
  State<PrepPlusCategoryPage> createState() => _PrepPlusCategoryPageState();
}

class _PrepPlusCategoryPageState extends State<PrepPlusCategoryPage> {
  final _repository = getIt<PrepPlusRepository>();
  final _searchController = TextEditingController();
  List<PrepBrowseItemModel> _items = [];
  bool _loading = true;
  String? _error;
  String _priceFilter = 'all';
  String _accessFilter = 'all';
  String? _institutionTag;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final hadItems = _items.isNotEmpty;
    setState(() {
      if (!hadItems) {
        _loading = true;
      }
      _error = null;
    });
    try {
      final items = await _repository.browseCategoryItems(
        categoryId: widget.category.categoryId,
        search: _searchController.text.trim(),
        priceFilter: _priceFilter,
        institutionTag: _institutionTag,
        userAccessFilter: _accessFilter,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _repository.mapError(e);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.genericMessage();
        _loading = false;
      });
    }
  }

  Future<void> _openFilters() async {
    final result = await showPrepPlusFiltersSheet(
      context,
      showInstitutionFilter: widget.showInstitutionFilter,
      priceFilter: _priceFilter,
      accessFilter: _accessFilter,
      institutionTag: _institutionTag,
    );
    if (result == null || !mounted) return;
    setState(() {
      _priceFilter = result.priceFilter;
      _accessFilter = result.accessFilter;
      _institutionTag = result.institutionTag;
    });
    await _load(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: widget.category.name),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openFilters,
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.tune_rounded),
        label: Text(l10n.prepPlusFiltersAction),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.prepPlusSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    _load();
                  },
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: _loading
                ? const AppLoadingView()
                : _error != null
                    ? AppErrorView(
                        message: _error!,
                        retryLabel: l10n.retry,
                        onRetry: _load,
                      )
                    : _items.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.sizeOf(context).height * 0.35,
                                  child: AppEmptyView(
                                    message: l10n.prepPlusCategoryEmpty,
                                    icon: Icons.menu_book_outlined,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: AppSpacing.listBottom,
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.md,
                                    AppSpacing.xs,
                                    AppSpacing.md,
                                    0,
                                  ),
                                  child: AppListEntryCard(
                                    title: item.title,
                                    subtitle: _subtitleFor(context, item),
                                    accentColor: _accentFor(item),
                                    leadingIcon: Icons.quiz_rounded,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => PrepPlusItemDetailPage(
                                            catalogItemId: item.catalogItemId,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  String _subtitleFor(BuildContext context, PrepBrowseItemModel item) {
    final l10n = AppLocalizations.of(context)!;
    final parts = <String>[
      l10n.prepPlusQuestionCount(item.questionCount),
      _accessLabel(l10n, item.userAccessState),
    ];
    if (item.hasFreeOffer) {
      parts.add(l10n.prepPlusHasFreeOffer);
    } else if (item.lowestPaidPrice != null) {
      parts.add(
        l10n.prepPlusFromPrice(
          item.lowestPaidPrice!,
          item.currencyCode ?? 'USD',
        ),
      );
    }
    return parts.join(' · ');
  }

  String _accessLabel(AppLocalizations l10n, String state) => switch (state) {
        'active' => l10n.prepPlusAccessActive,
        'expired' => l10n.prepPlusAccessExpired,
        _ => l10n.prepPlusAccessNone,
      };

  Color _accentFor(PrepBrowseItemModel item) => switch (item.userAccessState) {
        'active' => AppColors.accentMint,
        'expired' => AppColors.textSecondary,
        _ => AppColors.accentGold,
      };
}
