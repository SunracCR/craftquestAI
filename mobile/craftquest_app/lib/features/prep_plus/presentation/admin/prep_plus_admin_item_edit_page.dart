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
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

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
    this.isLifetimeAccess = false,
    this.priceAmount = 0,
    this.currencyCode = 'USD',
    this.isFree = false,
    this.isActive = true,
    this.storeProductId,
  });

  final int durationDays;
  final bool isLifetimeAccess;
  double priceAmount;
  String currencyCode;
  bool isFree;
  bool isActive;
  String? storeProductId;

  Map<String, dynamic> toJson() => {
        'durationDays': isLifetimeAccess ? 0 : durationDays,
        'isLifetimeAccess': isLifetimeAccess,
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
  late _OfferDraft _lifetimeOffer;
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
    _lifetimeOffer = _OfferDraft(durationDays: 0, isLifetimeAccess: true);
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
        if (!o.isLifetimeAccess && o.durationDays == days) {
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

    PrepAdminOfferModel? lifetimeExisting;
    for (final o in item.offers) {
      if (o.isLifetimeAccess) {
        lifetimeExisting = o;
        break;
      }
    }
    _lifetimeOffer = lifetimeExisting != null
        ? _OfferDraft(
            durationDays: 0,
            isLifetimeAccess: true,
            priceAmount: lifetimeExisting.priceAmount,
            currencyCode: lifetimeExisting.currencyCode,
            isFree: lifetimeExisting.isFree,
            isActive: lifetimeExisting.isActive,
            storeProductId: lifetimeExisting.storeProductId,
          )
        : _OfferDraft(durationDays: 0, isLifetimeAccess: true, isActive: false);
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

  Map<String, dynamic> _buildMetadataPayload() => {
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
      };

  bool get _coverPersistedOnServer =>
      _coverMediaId != null &&
      _coverMediaId!.isNotEmpty &&
      _coverMediaId == _item?.coverMediaId;

  Future<void> _onCoverMediaChanged(String? id) async {
    final previousId = _item?.coverMediaId;
    setState(() => _coverMediaId = id);
    if (widget.isCreate) {
      if (!mounted) return;
      context.showSuccessSnackBar(
        AppLocalizations.of(context)!.prepAdminCoverUploadedPendingCreate,
      );
      return;
    }
    if (widget.catalogItemId == null || _categoryId == null) {
      if (!mounted) return;
      context.showErrorSnackBar(
        AppLocalizations.of(context)!.prepAdminCoverSaveNeedsCategory,
      );
      setState(() => _coverMediaId = previousId);
      return;
    }
    final saved = await _persistMetadata(
      showSuccessSnackBar: false,
      successMessage: id == null
          ? AppLocalizations.of(context)!.prepAdminCoverRemoved
          : AppLocalizations.of(context)!.prepAdminCoverSaved,
    );
    if (!saved && mounted) {
      setState(() => _coverMediaId = previousId);
    }
  }

  Future<bool> _persistMetadata({
    bool showSuccessSnackBar = true,
    String? successMessage,
  }) async {
    if (widget.isCreate || widget.catalogItemId == null || _categoryId == null) {
      return false;
    }
    setState(() => _saving = true);
    try {
      final updated = await _repo.updateItem(
        widget.catalogItemId!,
        _buildMetadataPayload(),
      );
      if (!mounted) return false;
      _bindItem(updated, _subcategories);
      _changed = true;
      if (showSuccessSnackBar || successMessage != null) {
        context.showSuccessSnackBar(
          successMessage ?? AppLocalizations.of(context)!.prepAdminMetadataSaved,
        );
      }
      setState(() {});
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      context.showErrorSnackBar(
        _repo.mapError(e, AppLocalizations.of(context)!),
      );
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildCoverSaveStatus(AppLocalizations l10n) {
    if (_coverMediaId == null || _coverMediaId!.isEmpty) {
      return const SizedBox.shrink();
    }
    if (_saving) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.prepAdminCoverSaving,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (widget.isCreate) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          l10n.prepAdminCoverWillSaveOnCreate,
          style: TextStyle(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 12,
          ),
        ),
      );
    }
    if (_coverPersistedOnServer) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.prepAdminCoverSavedStatus,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        l10n.prepAdminCoverNotSavedStatus,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 12,
        ),
      ),
    );
  }

  String _itemDisplayTitle(AppLocalizations l10n) {
    final override = _titleCtrl.text.trim();
    if (override.isNotEmpty) {
      return override;
    }
    return _item?.quizTitle ?? l10n.prepPlusItemDetailTitle;
  }

  Future<void> _copyShareLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    context.showSuccessSnackBar(AppLocalizations.of(context)!.shareCodeLinkCopied);
  }

  Future<void> _sharePublicLink(String url) async {
    final l10n = AppLocalizations.of(context)!;
    final message = l10n.prepPlusShareLinkMessage(_itemDisplayTitle(l10n), url);
    await Share.share(message);
  }

  Widget _buildShareLinkSection(AppLocalizations l10n) {
    if (widget.isCreate || _item == null) {
      return const SizedBox.shrink();
    }

    final shareUrl = _item!.publicShareUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppSectionTitle(title: l10n.prepAdminShareLinkSection),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (shareUrl != null && shareUrl.isNotEmpty) ...[
                  if (_coverMediaId == null || _coverMediaId!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        l10n.prepAdminShareLinkNoCover,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  SelectableText(
                    shareUrl,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.prepAdminShareLinkHint,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _copyShareLink(shareUrl),
                        icon: const Icon(Icons.link_rounded, size: 18),
                        label: Text(l10n.shareCodeCopyLinkAction),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _sharePublicLink(shareUrl),
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: Text(l10n.shareCodeShareLinkAction),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    l10n.prepAdminShareLinkUnavailable,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
    if (widget.isCreate) {
      if (_selectedQuizId == null) {
        context.showErrorSnackBar(l10n.prepAdminSelectQuizError);
        return;
      }
      setState(() => _saving = true);
      try {
        final created = await _repo.createItem({
          'quizId': _selectedQuizId,
          'categoryId': _categoryId,
          ..._buildMetadataPayload(),
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
      } on DioException catch (e) {
        if (!mounted) return;
        context.showErrorSnackBar(_repo.mapError(e));
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }

    await _persistMetadata();
  }

  Future<void> _saveOffers() async {
    if (widget.isCreate) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      final payload = [
        ..._offers.map((o) => o.toJson()),
        if (_lifetimeOffer.isActive) _lifetimeOffer.toJson(),
      ];
      final activeOffers = payload.where((o) => o['isActive'] == true).toList();
      if (activeOffers.isEmpty) {
        context.showErrorSnackBar(l10n.prepAdminOffersRequired);
        return;
      }
      final updated = await _repo.upsertOffers(
        widget.catalogItemId!,
        payload,
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
                        _buildShareLinkSection(l10n),
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
                                showUploadSuccessSnackBar: false,
                                onChanged: _saving ? null : _onCoverMediaChanged,
                              ),
                              _buildCoverSaveStatus(l10n),
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l10n.prepAdminLifetimeOfferSection,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _OfferRow(
                                  label: l10n.prepPlusAccessLifetime,
                                  offer: _lifetimeOffer,
                                  enabled: !_saving,
                                  onChanged: () => setState(() {}),
                                ),
                                const Divider(height: AppSpacing.lg),
                                Text(
                                  l10n.prepAdminTimedOffersSection,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
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
