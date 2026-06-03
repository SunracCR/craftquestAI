import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_admin_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_admin_repository.dart';
import 'package:craftquest_app/features/prep_plus/presentation/admin/prep_plus_admin_category_form_sheet.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class PrepPlusAdminCategoriesPage extends StatefulWidget {
  const PrepPlusAdminCategoriesPage({super.key});

  @override
  State<PrepPlusAdminCategoriesPage> createState() =>
      _PrepPlusAdminCategoriesPageState();
}

class _PrepPlusAdminCategoriesPageState extends State<PrepPlusAdminCategoriesPage> {
  final _repo = getIt<PrepPlusAdminRepository>();
  List<PrepAdminCategoryModel> _roots = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final roots = await _repo.getCategories(includeInactive: false);
      if (!mounted) return;
      setState(() {
        _roots = _dedupeCategoryTree(roots);
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

  Future<void> _addRoot() async {
    final l10n = AppLocalizations.of(context)!;
    final saved = await showPrepCategoryFormSheet(
      context,
      roots: _roots,
      isRoot: true,
    );
    if (saved == true && mounted) {
      context.showSuccessSnackBar(l10n.prepAdminCategorySaved);
      await _load();
    }
  }

  Future<void> _addChild(PrepAdminCategoryModel parent) async {
    final l10n = AppLocalizations.of(context)!;
    final saved = await showPrepCategoryFormSheet(
      context,
      roots: _roots,
      parent: parent,
      isRoot: false,
    );
    if (saved == true && mounted) {
      context.showSuccessSnackBar(l10n.prepAdminCategorySaved);
      await _load();
    }
  }

  Future<void> _editCategory(
    PrepAdminCategoryModel category, {
    PrepAdminCategoryModel? parent,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final saved = await showPrepCategoryFormSheet(
      context,
      roots: _roots,
      existing: category,
      parent: parent,
      isEdit: true,
    );
    if (saved == true && mounted) {
      context.showSuccessSnackBar(l10n.prepAdminCategorySaved);
      await _load();
    }
  }

  Future<void> _deleteCategory(PrepAdminCategoryModel category) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.prepAdminDeleteCategoryTitle),
        content: Text(l10n.prepAdminDeleteCategoryMessage(category.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteQuestionAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _repo.deleteCategory(category.categoryId);
      if (!mounted) return;
      context.showSuccessSnackBar(l10n.prepAdminCategoryDeleted);
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(_repo.mapError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.prepAdminCategoriesTitle),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRoot,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.prepAdminAddRootCategory),
      ),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: AppSpacing.listBottom,
                    children: [
                      for (final root in _roots) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.xs,
                          ),
                          child: _RootHeader(
                            root: root,
                            onEdit: () => _editCategory(root),
                            onDelete: () => _deleteCategory(root),
                            onAddChild: () => _addChild(root),
                          ),
                        ),
                        for (final child in _dedupeByCategoryId(root.children))
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.xs,
                            ),
                            child: AppSectionCard(
                              padding: EdgeInsets.zero,
                              child: ListTile(
                                title: Text(child.name),
                                subtitle: Text(
                                  '${child.slug} · ${child.isActive ? l10n.prepAdminActive : l10n.prepAdminInactive}',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') {
                                      _editCategory(child, parent: root);
                                    }
                                    if (v == 'delete') _deleteCategory(child);
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text(l10n.editQuestionAction),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(l10n.deleteQuestionAction),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

List<PrepAdminCategoryModel> _dedupeCategoryTree(
  List<PrepAdminCategoryModel> roots,
) {
  final seenRootIds = <String>{};
  return roots
      .where((r) => seenRootIds.add(r.categoryId))
      .map(
        (r) => PrepAdminCategoryModel(
          categoryId: r.categoryId,
          parentCategoryId: r.parentCategoryId,
          categoryType: r.categoryType,
          slug: r.slug,
          name: r.name,
          description: r.description,
          countryCode: r.countryCode,
          iconKey: r.iconKey,
          sortOrder: r.sortOrder,
          isActive: r.isActive,
          children: _dedupeByCategoryId(r.children),
        ),
      )
      .toList();
}

List<PrepAdminCategoryModel> _dedupeByCategoryId(
  List<PrepAdminCategoryModel> items,
) {
  final seenIds = <String>{};
  final seenSlugs = <String>{};
  return items.where((c) {
    if (!seenIds.add(c.categoryId)) return false;
    final slugKey = '${c.parentCategoryId ?? ''}|${c.slug.toLowerCase()}';
    return seenSlugs.add(slugKey);
  }).toList();
}

class _RootHeader extends StatelessWidget {
  const _RootHeader({
    required this.root,
    required this.onEdit,
    required this.onDelete,
    required this.onAddChild,
  });

  final PrepAdminCategoryModel root;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Text(
            root.name,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.prepAdminAddSubcategory,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: onAddChild,
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
