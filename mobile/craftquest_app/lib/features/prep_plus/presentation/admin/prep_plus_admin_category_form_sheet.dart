import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_admin_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_admin_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

Future<bool?> showPrepCategoryFormSheet(
  BuildContext context, {
  required List<PrepAdminCategoryModel> roots,
  PrepAdminCategoryModel? existing,
  PrepAdminCategoryModel? parent,
  bool? isRoot,
  bool isEdit = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _PrepCategoryFormSheet(
      roots: roots,
      existing: existing,
      parent: parent,
      isRoot: isRoot,
      isEdit: isEdit,
    ),
  );
}

class _PrepCategoryFormSheet extends StatefulWidget {
  const _PrepCategoryFormSheet({
    required this.roots,
    this.existing,
    this.parent,
    this.isRoot,
    this.isEdit = false,
  });

  final List<PrepAdminCategoryModel> roots;
  final PrepAdminCategoryModel? existing;
  final PrepAdminCategoryModel? parent;
  final bool? isRoot;
  final bool isEdit;

  @override
  State<_PrepCategoryFormSheet> createState() => _PrepCategoryFormSheetState();
}

class _PrepCategoryFormSheetState extends State<_PrepCategoryFormSheet> {
  final _repo = getIt<PrepPlusAdminRepository>();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _iconCtrl;
  late final TextEditingController _sortCtrl;
  late String _categoryType;
  late bool _isActive;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  bool get _isRootCategory {
    if (widget.isRoot == true) return true;
    if (widget.parent != null) return false;
    if (_editing) return widget.existing!.parentCategoryId == null;
    return true;
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _slugCtrl = TextEditingController(text: e?.slug ?? '');
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _countryCtrl = TextEditingController(text: e?.countryCode ?? '');
    _iconCtrl = TextEditingController(text: e?.iconKey ?? '');
    _sortCtrl = TextEditingController(text: '${e?.sortOrder ?? 0}');
    _categoryType = e?.categoryType ??
        widget.parent?.categoryType ??
        'geographic';
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _descriptionCtrl.dispose();
    _countryCtrl.dispose();
    _iconCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  String? _resolvedParentId() {
    if (widget.parent != null) return widget.parent!.categoryId;
    if (!_editing) return null;
    final fromEntity = widget.existing!.parentCategoryId;
    if (fromEntity != null && fromEntity.isNotEmpty) return fromEntity;
    for (final root in widget.roots) {
      if (root.children.any((c) => c.categoryId == widget.existing!.categoryId)) {
        return root.categoryId;
      }
    }
    return null;
  }

  String _resolvedCategoryType() {
    final existingType = widget.existing?.categoryType.trim();
    if (existingType != null && existingType.isNotEmpty) {
      return existingType;
    }
    final parentId = _resolvedParentId();
    if (parentId != null) {
      for (final root in widget.roots) {
        if (root.categoryId == parentId) return root.categoryType;
      }
    }
    return widget.parent?.categoryType ?? _categoryType;
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) {
      context.showErrorSnackBar(l10n.prepAdminRequiredField);
      return;
    }
    setState(() => _saving = true);
    final parentId = _resolvedParentId();
    final categoryType = _resolvedCategoryType();
    final body = <String, dynamic>{
      if (parentId != null) 'parentCategoryId': parentId,
      'categoryType': categoryType,
      'slug': _slugCtrl.text.trim(),
      'name': _nameCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      'countryCode': _countryCtrl.text.trim().isEmpty
          ? null
          : _countryCtrl.text.trim().toUpperCase(),
      'iconKey':
          _iconCtrl.text.trim().isEmpty ? null : _iconCtrl.text.trim(),
      'sortOrder': int.tryParse(_sortCtrl.text.trim()) ?? 0,
      'isActive': _isActive,
    };
    try {
      if (_editing) {
        final categoryId = widget.existing!.categoryId;
        if (categoryId.isEmpty) {
          context.showErrorSnackBar(DioErrorMapper.genericMessage(l10n));
          return;
        }
        await _repo.updateCategory(categoryId, body);
      } else {
        await _repo.createCategory(body);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(_repo.mapError(e));
    } catch (_) {
      if (!mounted) return;
      context.showErrorSnackBar(DioErrorMapper.genericMessage(l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _editing
        ? l10n.prepAdminEditCategoryTitle
        : (_isRootCategory
            ? l10n.prepAdminAddRootCategory
            : l10n.prepAdminAddSubcategory);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              if (_isRootCategory && !_editing)
                DropdownButtonFormField<String>(
                  initialValue: _categoryType,
                  decoration: InputDecoration(
                    labelText: l10n.prepAdminCategoryTypeLabel,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'geographic',
                      child: Text(l10n.prepAdminCategoryTypeGeographic),
                    ),
                    DropdownMenuItem(
                      value: 'thematic',
                      child: Text(l10n.prepAdminCategoryTypeThematic),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) {
                          if (v != null) setState(() => _categoryType = v);
                        },
                ),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: l10n.prepAdminNameLabel),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.prepAdminRequiredField : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _slugCtrl,
                decoration: InputDecoration(labelText: l10n.prepAdminSlugLabel),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.prepAdminRequiredField : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _descriptionCtrl,
                decoration:
                    InputDecoration(labelText: l10n.prepAdminDescriptionLabel),
                maxLines: 2,
              ),
              if (_resolvedCategoryType() == 'geographic') ...[
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _countryCtrl,
                  decoration:
                      InputDecoration(labelText: l10n.prepAdminCountryCodeLabel),
                  maxLength: 2,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _iconCtrl,
                decoration: InputDecoration(labelText: l10n.prepAdminIconKeyLabel),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _sortCtrl,
                decoration: InputDecoration(labelText: l10n.prepAdminSortOrderLabel),
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                title: Text(l10n.prepAdminActive),
                value: _isActive,
                onChanged: _saving ? null : (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.profileSaveAction),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
