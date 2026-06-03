import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_admin_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_admin_repository.dart';
import 'package:craftquest_app/features/prep_plus/presentation/admin/prep_plus_admin_item_edit_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class PrepPlusAdminItemsPage extends StatefulWidget {
  const PrepPlusAdminItemsPage({super.key});

  @override
  State<PrepPlusAdminItemsPage> createState() => _PrepPlusAdminItemsPageState();
}

class _PrepPlusAdminItemsPageState extends State<PrepPlusAdminItemsPage> {
  final _repo = getIt<PrepPlusAdminRepository>();
  final _searchCtrl = TextEditingController();
  List<PrepAdminItemSummaryModel> _items = [];
  bool? _publishedFilter;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.listItems(
        isPublished: _publishedFilter,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        take: 100,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _repo.mapError(e);
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

  Future<void> _openItem({String? catalogItemId}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PrepPlusAdminItemEditPage(catalogItemId: catalogItemId),
      ),
    );
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.prepAdminCatalogTitle),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openItem(),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.prepAdminNewCatalogItem),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n.prepPlusSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchCtrl.clear();
                    _load();
                  },
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.prepPlusFilterAll),
                  selected: _publishedFilter == null,
                  onSelected: (_) {
                    setState(() => _publishedFilter = null);
                    _load();
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                FilterChip(
                  label: Text(l10n.prepAdminPublishedFilter),
                  selected: _publishedFilter == true,
                  onSelected: (_) {
                    setState(() => _publishedFilter = true);
                    _load();
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                FilterChip(
                  label: Text(l10n.prepAdminDraftFilter),
                  selected: _publishedFilter == false,
                  onSelected: (_) {
                    setState(() => _publishedFilter = false);
                    _load();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: _loading
                ? const AppLoadingView()
                : _error != null
                    ? AppErrorView(
                        message: _error!,
                        retryLabel: l10n.retry,
                        onRetry: _load,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _items.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height: 120,
                                    child: Center(
                                      child: Text(
                                        l10n.prepAdminCatalogEmpty,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: AppSpacing.listBottom,
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                  final item = _items[index];
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.md,
                                      0,
                                      AppSpacing.md,
                                      AppSpacing.xs,
                                    ),
                                    child: AppSectionCard(
                                      padding: EdgeInsets.zero,
                                      child: ListTile(
                                        title: Text(item.displayTitle),
                                        subtitle: Text(
                                          l10n.prepAdminItemSummarySubtitle(
                                            item.categoryName,
                                            item.questionCount,
                                            item.activeOfferCount,
                                            item.sampleQuestionCount,
                                            item.isPublished
                                                ? l10n.prepAdminPublishedFilter
                                                : l10n.prepAdminDraftFilter,
                                          ),
                                        ),
                                        isThreeLine: true,
                                        trailing: Icon(
                                          item.isPublished
                                              ? Icons.visibility_rounded
                                              : Icons.edit_note_rounded,
                                          color: item.isPublished
                                              ? AppColors.accentMint
                                              : AppColors.textSecondary,
                                        ),
                                        onTap: () => _openItem(
                                          catalogItemId: item.catalogItemId,
                                        ),
                                      ),
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
}
