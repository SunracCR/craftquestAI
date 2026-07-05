import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/core/theme/app_media_display.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/core/widgets/option_image_picker.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_admin_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_admin_repository.dart';
import 'package:craftquest_app/features/prep_plus/presentation/admin/prep_plus_admin_sample_picker_sheet.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrepPlusAdminItemEditPage extends StatefulWidget {
  const PrepPlusAdminItemEditPage({super.key, this.catalogItemId});

  final String? catalogItemId;

  bool get isCreate => catalogItemId == null;

  @override
  State<PrepPlusAdminItemEditPage> createState() =>
      _PrepPlusAdminItemEditPageState();
}

class _OfferDraft {
  _OfferDraft({
    required this.durationDays,
    this.priceAmount = 0,
    this.currencyCode = 'USD',
    this.isFree = false,
    this.isActive = true,
    this.storeProductId,
  });

  final int durationDays;
  double priceAmount;
  String currencyCode;
  bool isFree;
  bool isActive;
  String? storeProductId;

  Map<String, dynamic> toJson() => {
        'durationDays': durationDays,
        'priceAmount': isFree ? 0 : priceAmount,
        'currencyCode': currencyCode,
        'isFree': isFree,
        'storeProductId':
            storeProductId?.trim().isEmpty == true ? null : storeProductId?.trim(),
        'isActive': isActive,
      };
}

class _PrepPlusAdminItemEditPageState extends State<PrepPlusAdminItemEditPage> {
  static const _durations = [30, 60, 90, 183];

  final _repo = getIt<PrepPlusAdminRepository>();
  final _quizSearchCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  PrepAdminItemDetailModel? _item;
  List<PrepAdminSubcategoryOption> _subcategories = [];
  List<PrepAdminLinkableQuizModel> _linkableQuizzes = [];
  String? _selectedQuizId;
  String? _categoryId;
  List<String> _sampleQuestionIds = [];
  late List<_OfferDraft> _offers;
  DateTime? _listingStartsAt;
  DateTime? _listingEndsAt;
  String? _coverMediaId;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _offers = _durations
        .map((d) => _OfferDraft(durationDays: d))
        .toList();
    _load();
  }

  @override
  void dispose() {
    _quizSearchCtrl.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _institutionCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final roots = await _repo.getCategories();
      final subs = flattenPrepSubcategories(roots);
      if (widget.isCreate) {
        final quizzes = await _repo.getLinkableQuizzes(
          search: _quizSearchCtrl.text.trim().isEmpty
              ? null
              : _quizSearchCtrl.text.trim(),
        );
        if (!mounted) return;
        setState(() {
          _subcategories = subs;
          _linkableQuizzes = quizzes;
          _categoryId = subs.isNotEmpty ? subs.first.categoryId : null;
          _selectedQuizId = quizzes.isNotEmpty ? quizzes.first.quizId : null;
          _loading = false;
        });
        return;
      }
      final item = await _repo.getItem(widget.catalogItemId!);
      if (!mounted) return;
      _bindItem(item, subs);
      setState(() => _loading = false);
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

  void _bindItem(PrepAdminItemDetailModel item, List<PrepAdminSubcategoryOption> subs) {
    _item = item;
    _subcategories = subs;
    _categoryId = item.categoryId;
    _selectedQuizId = item.quizId;
    _titleCtrl.text = item.titleOverride ?? '';
    _descriptionCtrl.text = item.description ?? '';
    _institutionCtrl.text = item.institutionTag ?? '';
    _tagsCtrl.text = item.tags.join(', ');
    _listingStartsAt = item.listingStartsAt;
    _listingEndsAt = item.listingEndsAt;
    _coverMediaId = item.coverMediaId;
    _sampleQuestionIds =
        item.sampleQuestions.map((s) => s.questionId).toList();
    _offers = _durations.map((days) {
      PrepAdminOfferModel? existing;
      for (final o in item.offers) {
        if (o.durationDays == days) {
          existing = o;
          break;
        }
      }
      if (existing != null) {
        return _OfferDraft(
          durationDays: days,
          priceAmount: existing.priceAmount,
          currencyCode: existing.currencyCode,
          isFree: existing.isFree,
          isActive: existing.isActive,
          storeProductId: existing.storeProductId,
        );
      }
      return _OfferDraft(durationDays: days, isActive: false);
    }).toList();
  }

  PrepAdminSubcategoryOption? get _selectedSubcategory {
    if (_categoryId == null) return null;
    for (final s in _subcategories) {
      if (s.categoryId == _categoryId) return s;
    }
    return null;
  }

  bool get _showInstitutionTag =>
      _selectedSubcategory?.isGeographic ?? false;

  List<String> _parseTags() => _tagsCtrl.text
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  String _durationLabel(int days, AppLocalizations l10n) {
    return switch (days) {
      30 => l10n.prepPlusDuration30,
      60 => l10n.prepPlusDuration60,
      90 => l10n.prepPlusDuration90,
      183 => l10n.prepPlusDuration6Months,
      _ => l10n.prepPlusDurationDays(days),
    };
  }

  Future<void> _reloadLinkableQuizzes() async {
    if (!widget.isCreate) return;
    setState(() => _saving = true);
    try {
      final quizzes = await _repo.getLinkableQuizzes(
        search: _quizSearchCtrl.text.trim().isEmpty
            ? null
            : _quizSearchCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _linkableQuizzes = quizzes;
        if (_selectedQuizId == null ||
            !quizzes.any((q) => q.quizId == _selectedQuizId)) {
          _selectedQuizId = quizzes.isNotEmpty ? quizzes.first.quizId : null;
        }
      });
    } on DioException catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(_repo.mapError(e, AppLocalizations.of(context)!));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveMetadata() async {
    final l10n = AppLocalizations.of(context)!;
    if (_categoryId == null) {
      context.showErrorSnackBar(l10n.prepAdminSelectCategoryError);
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.isCreate) {
        if (_selectedQuizId == null) {
          if (mounted) setState(() => _saving = false);
          context.showErrorSnackBar(l10n.prepAdminSelectQuizError);
          return;
        }
        final created = await _repo.createItem({
          'quizId': _selectedQuizId,
          'categoryId': _categoryId,
          'titleOverride':
              _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
          'description': _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
          'coverMediaId': _coverMediaId,
          'tags': _parseTags(),
          if (_showInstitutionTag && _institutionCtrl.text.trim().isNotEmpty)
            'institutionTag': _institutionCtrl.text.trim(),
          'listingStartsAt': _listingStartsAt?.toUtc().toIso8601String(),
          'listingEndsAt': _listingEndsAt?.toUtc().toIso8601String(),
        });
        if (!mounted) return;
        _changed = true;
        context.showSuccessSnackBar(l10n.prepAdminItemCreated);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<bool>(
            builder: (_) => PrepPlusAdminItemEditPage(
              catalogItemId: created.catalogItemId,
            ),
          ),
        );
        return;
      }

      final updated = await _repo.updateItem(widget.catalogItemId!, {
        'categoryId': _categoryId,
        'titleOverride':
            _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        'coverMediaId': _coverMediaId,
        'tags': _parseTags(),
        'institutionTag': _showInstitutionTag
            ? (_institutionCtrl.text.trim().isEmpty
                ? null
                : _institutionCtrl.text.trim())
            : null,
        'listingStartsAt': _listingStartsAt?.toUtc().toIso8601String(),
        'listingEndsAt': _listingEndsAt?.toUtc().toIso8601String(),
      });
      if (!mounted) return;
      _bindItem(updated, _subcategories);
      _changed = true;
      context.showSuccessSnackBar(l10n.prepAdminMetadataSaved);
      setState(() {});
    } on DioException catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(_repo.mapError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveOffers() async {
    if (widget.isCreate) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      final activeOffers = _offers.where((o) => o.isActive).toList();
      if (activeOffers.isEmpty) {
        context.showErrorSnackBar(l10n.prepAdminOffersRequired);
        return;
      }
      final updated = await _repo.upsertOffers(
        widget.catalogItemId!,
        _offers.map((o) => o.toJson()).toList(),
      );
      if (!mounted) return;
      _bindItem(updated, _subcategories);
      _changed = true;
      context.showSuccessSnackBar(l10n.prepAdminOffersSaved);
      setState(() {});
    } on DioException catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(_repo.mapError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickSamples() async {
    if (_item == null) return;
    final picked = await showPrepSamplePickerSheet(
      context,
      quizId: _item!.quizId,
      initialSelectedIds: _sampleQuestionIds,
    );
    if (picked == null || picked.length != 3) return;
    setState(() => _saving = true);
    try {
      final updated = await _repo.upsertSamples(
        widget.catalogItemId!,
        picked,
      );
      if (!mounted) return;
      _bindItem(updated, _subcategories);
      _changed = true;
      context.showSuccessSnackBar(
        AppLocalizations.of(context)!.prepAdminSamplesSaved,
      );
      setState(() {});
    } on DioException catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(_repo.mapError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publish(bool publish) async {
    if (widget.isCreate) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      final updated = publish
          ? await _repo.publishItem(widget.catalogItemId!)
          : await _repo.unpublishItem(widget.catalogItemId!);
      if (!mounted) return;
      _bindItem(updated, _subcategories);
      _changed = true;
      context.showSuccessSnackBar(
        publish ? l10n.prepAdminPublished : l10n.prepAdminUnpublished,
      );
      setState(() {});
    } on DioException catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(_repo.mapError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteItem() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.prepAdminDeleteItemTitle),
        content: Text(l10n.prepAdminDeleteItemMessage),
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
    setState(() => _saving = true);
    try {
      await _repo.deleteItem(widget.catalogItemId!);
      if (!mounted) return;
      context.showSuccessSnackBar(l10n.prepAdminItemDeleted);
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(_repo.mapError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _listingStartsAt : _listingEndsAt) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _listingStartsAt = picked;
      } else {
        _listingEndsAt = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat.yMMMd(Localizations.localeOf(context).toString());

    return PopScope(
      canPop: !_changed,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context, _changed);
      },
      child: EdgeAwareScaffold(
        appBar: craftQuestAppBar(
          title: widget.isCreate
              ? l10n.prepAdminNewCatalogItem
              : l10n.prepAdminEditItemTitle,
        ),
        body: _loading
            ? const AppLoadingView()
            : _error != null
                ? AppErrorView(
                    message: _error!,
                    retryLabel: l10n.retry,
                    onRetry: _load,
                  )
                : ListView(
                    padding: AppSpacing.listBottom,
                    children: [
                      if (_item != null) ...[
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              Chip(
                                label: Text(
                                  _item!.isPublished
                                      ? l10n.prepAdminPublishedFilter
                                      : l10n.prepAdminDraftFilter,
                                ),
                                backgroundColor: _item!.isPublished
                                    ? AppColors.accentMint.withValues(alpha: 0.2)
                                    : null,
                              ),
                              Chip(
                                label: Text(
                                  l10n.prepPlusQuestionCount(_item!.questionCount),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  l10n.prepAdminOffersChip(_item!.offers
                                      .where((o) => o.isActive)
                                      .length),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  l10n.prepAdminSamplesChip(
                                    _item!.sampleQuestions.length,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_item!.quizTitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              l10n.prepAdminLinkedQuiz(_item!.quizTitle),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: AppSectionTitle(title: l10n.prepAdminMetadataSection),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: AppSectionCard(
                          child: Column(
                            children: [
                              if (widget.isCreate) ...[
                                TextField(
                                  controller: _quizSearchCtrl,
                                  decoration: InputDecoration(
                                    labelText: l10n.prepAdminQuizSearchLabel,
                                    hintText: l10n.prepPlusSearchHint,
                                    prefixIcon: const Icon(Icons.search_rounded),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.refresh_rounded),
                                      onPressed: _saving ? null : _reloadLinkableQuizzes,
                                    ),
                                  ),
                                  onSubmitted: (_) => _reloadLinkableQuizzes(),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                if (_linkableQuizzes.isEmpty)
                                  Text(
                                    l10n.prepAdminLinkableQuizzesEmpty,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                else
                                  DropdownButtonFormField<String>(
                                    value: _selectedQuizId,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: l10n.prepAdminSelectQuizLabel,
                                      helperText: l10n.prepAdminSelectQuizHint,
                                    ),
                                    items: _linkableQuizzes
                                        .map(
                                          (q) => DropdownMenuItem(
                                            value: q.quizId,
                                            child: Text(
                                              l10n.prepAdminLinkableQuizOption(
                                                q.title,
                                                q.questionCount,
                                                q.createdByDisplayName,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: _saving
                                        ? null
                                        : (v) => setState(() => _selectedQuizId = v),
                                  ),
                              ],
                              DropdownButtonFormField<String>(
                                value: _categoryId,
                                decoration: InputDecoration(
                                  labelText: l10n.prepAdminSubcategoryLabel,
                                ),
                                items: _subcategories
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s.categoryId,
                                        child: Text(s.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _saving
                                    ? null
                                    : (v) => setState(() => _categoryId = v),
                              ),
                              TextField(
                                controller: _titleCtrl,
                                decoration: InputDecoration(
                                  labelText: l10n.prepAdminTitleOverrideLabel,
                                ),
                              ),
                              TextField(
                                controller: _descriptionCtrl,
                                decoration: InputDecoration(
                                  labelText: l10n.prepAdminDescriptionLabel,
                                ),
                                maxLines: 3,
                              ),
                              OptionImagePicker(
                                label: l10n.prepAdminCoverImageLabel,
                                mediaAssetId: _coverMediaId,
                                previewHeight: AppMediaDisplay.questionImageHeight,
                                onChanged: _saving
                                    ? null
                                    : (id) => setState(() => _coverMediaId = id),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.xs,
                                  bottom: AppSpacing.sm,
                                ),
                                child: Text(
                                  l10n.prepAdminCoverImageHint,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (_showInstitutionTag)
                                TextField(
                                  controller: _institutionCtrl,
                                  decoration: InputDecoration(
                                    labelText: l10n.prepPlusFilterInstitutionLabel,
                                  ),
                                ),
                              TextField(
                                controller: _tagsCtrl,
                                decoration: InputDecoration(
                                  labelText: l10n.prepAdminTagsLabel,
                                  helperText: l10n.prepAdminTagsHint,
                                ),
                              ),
                              ListTile(
                                title: Text(l10n.prepAdminListingStartLabel),
                                subtitle: Text(
                                  _listingStartsAt != null
                                      ? dateFmt.format(_listingStartsAt!)
                                      : l10n.prepAdminOptionalDate,
                                ),
                                trailing: const Icon(Icons.calendar_today_outlined),
                                onTap: () => _pickDate(isStart: true),
                              ),
                              ListTile(
                                title: Text(l10n.prepAdminListingEndLabel),
                                subtitle: Text(
                                  _listingEndsAt != null
                                      ? dateFmt.format(_listingEndsAt!)
                                      : l10n.prepAdminOptionalDate,
                                ),
                                trailing: const Icon(Icons.calendar_today_outlined),
                                onTap: () => _pickDate(isStart: false),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              FilledButton(
                                onPressed: _saving ? null : _saveMetadata,
                                child: _saving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        widget.isCreate
                                            ? l10n.prepAdminCreateItemAction
                                            : l10n.prepAdminSaveMetadataAction,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!widget.isCreate) ...[
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: AppSectionTitle(title: l10n.prepAdminOffersSection),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: AppSectionCard(
                            child: Column(
                              children: [
                                for (final offer in _offers)
                                  _OfferRow(
                                    label: _durationLabel(offer.durationDays, l10n),
                                    offer: offer,
                                    enabled: !_saving,
                                    onChanged: () => setState(() {}),
                                  ),
                                const SizedBox(height: AppSpacing.sm),
                                FilledButton(
                                  onPressed: _saving ? null : _saveOffers,
                                  child: Text(l10n.prepAdminSaveOffersAction),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: AppSectionTitle(title: l10n.prepAdminSamplesSection),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: AppSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_item!.sampleQuestions.isEmpty)
                                  Text(
                                    l10n.prepAdminSamplesEmpty,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                else
                                  for (final s in _item!.sampleQuestions)
                                    ListTile(
                                      dense: true,
                                      title: Text(
                                        s.promptPreview,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      leading: CircleAvatar(
                                        radius: 14,
                                        child: Text('${s.sortOrder}'),
                                      ),
                                    ),
                                OutlinedButton.icon(
                                  onPressed: _saving ? null : _pickSamples,
                                  icon: const Icon(Icons.checklist_rounded),
                                  label: Text(l10n.prepAdminPickSamplesAction),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: AppSectionTitle(title: l10n.prepAdminPublishSection),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: AppSectionCard(
                            child: Column(
                              children: [
                                if (_item!.isPublished)
                                  FilledButton(
                                    onPressed: _saving
                                        ? null
                                        : () => _publish(false),
                                    child: Text(l10n.prepAdminUnpublishAction),
                                  )
                                else
                                  FilledButton(
                                    onPressed:
                                        _saving ? null : () => _publish(true),
                                    child: Text(l10n.prepAdminPublishAction),
                                  ),
                                const SizedBox(height: AppSpacing.sm),
                                OutlinedButton(
                                  onPressed: _saving ? null : _deleteItem,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                  child: Text(l10n.prepAdminDeleteItemAction),
                                ),
                              ],
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

class _OfferRow extends StatelessWidget {
  const _OfferRow({
    required this.label,
    required this.offer,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final _OfferDraft offer;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Switch(
                value: offer.isActive,
                onChanged: enabled
                    ? (v) {
                        offer.isActive = v;
                        onChanged();
                      }
                    : null,
              ),
            ],
          ),
          if (offer.isActive) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.prepAdminOfferFreeLabel),
              value: offer.isFree,
              onChanged: enabled
                  ? (v) {
                      offer.isFree = v;
                      onChanged();
                    }
                  : null,
            ),
            if (!offer.isFree)
              TextFormField(
                enabled: enabled,
                initialValue: offer.priceAmount.toString(),
                decoration: InputDecoration(
                  labelText: l10n.prepAdminOfferPriceLabel,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) {
                  offer.priceAmount = double.tryParse(v) ?? 0;
                },
              ),
            TextFormField(
              enabled: enabled,
              initialValue: offer.currencyCode,
              decoration: InputDecoration(
                labelText: l10n.prepAdminOfferCurrencyLabel,
              ),
              onChanged: (v) => offer.currencyCode = v.toUpperCase(),
            ),
            TextFormField(
              enabled: enabled,
              initialValue: offer.storeProductId ?? '',
              decoration: InputDecoration(
                labelText: l10n.prepAdminStoreProductIdLabel,
              ),
              onChanged: (v) => offer.storeProductId = v,
            ),
          ],
        ],
      ),
    );
  }
}
