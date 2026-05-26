import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/core/network/api_error_mapper.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/ai_generation/ai_generation_limits.dart';
import 'package:craftquest_app/features/ai_generation/data/models/study_material_models.dart';
import 'package:craftquest_app/features/ai_generation/data/study_material_repository.dart';
import 'package:craftquest_app/features/ai_generation/presentation/ai_generation_progress_page.dart';
import 'package:craftquest_app/features/ai_generation/presentation/study_material_review_text_page.dart';
import 'package:craftquest_app/features/ai_generation/presentation/widgets/question_count_selector.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class QuizGenerationParametersPage extends StatefulWidget {
  const QuizGenerationParametersPage({
    super.key,
    required this.studyMaterialId,
    required this.detail,
    this.targetQuizId,
    this.targetQuizTitle,
  });

  final String studyMaterialId;
  final StudyMaterialDetailModel detail;
  final String? targetQuizId;
  final String? targetQuizTitle;

  @override
  State<QuizGenerationParametersPage> createState() =>
      _QuizGenerationParametersPageState();
}

class _QuizGenerationParametersPageState extends State<QuizGenerationParametersPage> {
  static const _minQuestions = 5;
  static const _absoluteMaxQuestions = 40;
  static const _estimateDebounce = Duration(milliseconds: 400);

  final _repository = getIt<StudyMaterialRepository>();
  final _topicController = TextEditingController();
  Timer? _estimateTimer;
  late StudyMaterialDetailModel _detail;
  late int _pageFrom;
  late int _pageTo;
  late int _questionCount;
  String _difficulty = 'mixed';
  late String _language;
  final Set<String> _allowedQuestionTypes = {
    'single_choice',
    'multiple_choice',
    'true_false',
  };
  QuizGenerationEstimateModel? _estimate;
  int? _maxSelectableQuestions;
  bool _loadingEstimate = true;
  bool _refreshingEstimate = false;
  bool _starting = false;

  static const _allQuestionTypes = [
    ('single_choice', 'aiGenerationTypeSingleChoice'),
    ('multiple_choice', 'aiGenerationTypeMultipleChoice'),
    ('true_false', 'aiGenerationTypeTrueFalse'),
  ];

  int _materialMaxFromDetail() {
    var max = _detail.estimatedMaxQuestions;
    if (max <= 0) {
      max = _absoluteMaxQuestions;
    }
    return max.clamp(_minQuestions, _absoluteMaxQuestions);
  }

  int get _effectiveMax =>
      (_maxSelectableQuestions ?? _materialMaxFromDetail())
          .clamp(_minQuestions, _absoluteMaxQuestions);

  void _applyEstimateLimits(QuizGenerationEstimateModel estimate) {
    _maxSelectableQuestions = estimate.maxSelectableQuestions.clamp(
      _minQuestions,
      _materialMaxFromDetail(),
    );
    if (_questionCount > _effectiveMax) {
      _questionCount = _effectiveMax;
    }
  }

  static int _previewCredits(int questionCount) =>
      2 + (questionCount / 10).ceil();

  static String _normalizeLanguageCode(String? code) {
    final normalized = code?.trim().toLowerCase();
    return switch (normalized) {
      'en' || 'es' || 'pt' => normalized!,
      _ => 'en',
    };
  }

  String _initialMaterialLanguage() =>
      _normalizeLanguageCode(_detail.languageCode);

  String _languageLabel(AppLocalizations l10n, String code) => switch (code) {
        'es' => l10n.languageSpanish,
        'pt' => l10n.languagePortuguese,
        _ => l10n.languageEnglish,
      };

  @override
  void initState() {
    super.initState();
    _detail = widget.detail;
    _pageFrom = _detail.selectionPageFrom ?? 1;
    _pageTo = _detail.selectionPageTo ?? _detail.pageCount ?? _pageFrom;
    if (_detail.selectionTopic != null) {
      _topicController.text = _detail.selectionTopic!;
    }
    _language = _initialMaterialLanguage();
    _questionCount = 15.clamp(_minQuestions, _materialMaxFromDetail());
    _loadEstimate(initial: true);
  }

  @override
  void dispose() {
    _estimateTimer?.cancel();
    _topicController.dispose();
    super.dispose();
  }

  bool get _hidePageRange =>
      _detail.editedExtractedText != null &&
      _detail.editedExtractedText!.trim().isNotEmpty;

  int _wordsInRange() {
    if (_detail.editedExtractedText != null &&
        _detail.editedExtractedText!.trim().isNotEmpty) {
      return _detail.wordCount ?? 0;
    }
    return _detail.pages
        .where((p) => p.pageNumber >= _pageFrom && p.pageNumber <= _pageTo)
        .fold<int>(0, (sum, p) => sum + p.wordCount);
  }

  void _onPageRangeChanged(RangeValues values) {
    final maxPage = _detail.pageCount ?? 1;
    setState(() {
      _pageFrom = values.start.round().clamp(1, maxPage);
      _pageTo = values.end.round().clamp(_pageFrom, maxPage);
    });
  }

  void _onPageRangeChangeEnd(RangeValues values) {
    _onPageRangeChanged(values);
    _scheduleEstimateReload();
  }

  String _typeLabel(AppLocalizations l10n, String type) {
    return switch (type) {
      'single_choice' => l10n.aiGenerationTypeSingleChoice,
      'multiple_choice' => l10n.aiGenerationTypeMultipleChoice,
      'true_false' => l10n.aiGenerationTypeTrueFalse,
      _ => type,
    };
  }

  QuizGenerationParameters _buildParams() {
    final topic = _topicController.text.trim();
    return QuizGenerationParameters(
      targetQuizId: widget.targetQuizId,
      questionCount: _questionCount,
      language: _language,
      difficulty: _difficulty,
      allowedQuestionTypes: _allowedQuestionTypes.toList(),
      pageFrom: _pageFrom,
      pageTo: _pageTo,
      topicFocus: topic.isEmpty ? null : topic,
    );
  }

  void _scheduleEstimateReload() {
    _estimateTimer?.cancel();
    _estimateTimer = Timer(_estimateDebounce, () {
      if (mounted) {
        unawaited(_loadEstimate());
      }
    });
  }

  Future<void> _loadEstimate({bool initial = false}) async {
    if (!initial) {
      setState(() => _refreshingEstimate = true);
    } else {
      setState(() => _loadingEstimate = true);
    }

    try {
      final estimate = await _repository.estimate(
        studyMaterialId: widget.studyMaterialId,
        parameters: _buildParams(),
      );
      if (!mounted) return;
      setState(() {
        _estimate = estimate;
        _language = _normalizeLanguageCode(estimate.generationLanguage);
        _applyEstimateLimits(estimate);
        _loadingEstimate = false;
        _refreshingEstimate = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
      setState(() {
        _loadingEstimate = false;
        _refreshingEstimate = false;
      });
    }
  }

  void _onQuestionCountSlide(int value) {
    final next = value.clamp(_minQuestions, _effectiveMax);
    if (next == _questionCount) return;
    setState(() => _questionCount = next);
  }

  void _onQuestionCountSlideEnd(int value) {
    final next = value.clamp(_minQuestions, _effectiveMax);
    if (next != _questionCount) {
      setState(() => _questionCount = next);
    }
    _scheduleEstimateReload();
  }

  Future<void> _start() async {
    if (_allowedQuestionTypes.isEmpty) return;
    setState(() => _starting = true);
    try {
      final topic = _topicController.text.trim();
      final updatedDetail = await _repository.updateSelection(
        studyMaterialId: widget.studyMaterialId,
        pageFrom: _pageFrom,
        pageTo: _pageTo,
        topic: topic,
      );
      _detail = updatedDetail;

      final result = await _repository.startGeneration(
        studyMaterialId: widget.studyMaterialId,
        parameters: _buildParams(),
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (result.resumedExistingJob) {
        context.showInfoSnackBar(l10n.aiGenerationResumedSnack);
      } else {
        context.showInfoSnackBar(l10n.aiGenerationBackgroundSnack);
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => AiGenerationProgressPage(
            aiJobId: result.aiJobId,
            targetQuizId: result.targetQuizId ?? widget.targetQuizId,
            quizTitle: widget.targetQuizTitle ?? _detail.title,
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final existingJobId = ApiErrorMapper.tryGetAiJobId(e);
      if (existingJobId != null) {
        final l10n = AppLocalizations.of(context)!;
        context.showInfoSnackBar(l10n.aiGenerationResumedSnack);
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => AiGenerationProgressPage(
              aiJobId: existingJobId,
              targetQuizId:
                  ApiErrorMapper.tryGetTargetQuizId(e) ?? widget.targetQuizId,
              quizTitle: widget.targetQuizTitle ?? _detail.title,
            ),
          ),
        );
        return;
      }
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _openTextReview() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudyMaterialReviewTextPage(
          studyMaterialId: widget.studyMaterialId,
          initialDetail: _detail,
          targetQuizId: widget.targetQuizId,
          targetQuizTitle: widget.targetQuizTitle,
        ),
      ),
    );
  }

  bool get _isPageRangeOverLimit {
    if (_hidePageRange) return false;
    return (_pageTo - _pageFrom + 1) > AiGenerationLimits.maxPagesPerGeneration;
  }

  Widget _buildPageRangeSelector(AppLocalizations l10n, ThemeData theme) {
    final maxPage = _detail.pageCount ?? 1;
    final selectedCount = _pageTo - _pageFrom + 1;
    final overLimit =
        selectedCount > AiGenerationLimits.maxPagesPerGeneration;
    final words = _wordsInRange();

    return AppSectionCard(
      variant: AppCardVariant.highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.aiGenerationPageRangeHelp,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.aiGenerationPageRangeOfTotal(_pageFrom, _pageTo, maxPage),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              l10n.aiGenerationPageRangeSelectedCount(selectedCount),
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          RangeSlider(
            values: RangeValues(
              _pageFrom.toDouble(),
              _pageTo.toDouble().clamp(
                    _pageFrom.toDouble(),
                    maxPage.toDouble(),
                  ),
            ),
            min: 1,
            max: maxPage.toDouble(),
            divisions: maxPage > 1 ? maxPage - 1 : 1,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.textSecondary.withValues(alpha: 0.25),
            onChanged: _onPageRangeChanged,
            onChangeEnd: _onPageRangeChangeEnd,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$maxPage',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (maxPage > AiGenerationLimits.maxPagesPerGeneration) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.aiGenerationUploadLimitsHint(
                AiGenerationLimits.maxPagesPerMaterial,
                AiGenerationLimits.maxPagesPerGeneration,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.accentGold,
                height: 1.4,
              ),
            ),
          ],
          if (overLimit) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.aiGenerationPageRangeOverLimit(
                AiGenerationLimits.maxPagesPerGeneration,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 18,
                color: AppColors.accentCool.withValues(alpha: 0.9),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.aiGenerationWordsInScopePurpose(words),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScopeSection(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionTitle(title: l10n.aiGenerationOutlineTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _detail.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (_detail.needsOcr) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.aiGenerationNeedsOcr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.accentCool,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (!_hidePageRange) ...[
          _buildPageRangeSelector(l10n, theme),
          const SizedBox(height: AppSpacing.md),
        ] else ...[
          Text(
            l10n.aiGenerationWordsInScopePurpose(_wordsInRange()),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        TextField(
          controller: _topicController,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
          cursorColor: AppColors.accentCool,
          decoration: InputDecoration(
            labelText: l10n.aiGenerationTopicHint,
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.surfaceHighlight,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
              borderSide: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.28),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
              borderSide: BorderSide(
                color: AppColors.accentCool.withValues(alpha: 0.65),
              ),
            ),
          ),
          maxLines: 2,
          onChanged: (_) => _scheduleEstimateReload(),
        ),
        if (_detail.needsOcr && !_detail.requiresTextReview) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _openTextReview,
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: Text(l10n.aiGenerationReviewTextAction),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppSectionTitle(title: l10n.aiGenerationParamsTitle),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildQuestionCountCard(
    AppLocalizations l10n,
    ThemeData theme,
    int maxQuestions,
  ) {
    final displayCredits = _estimate != null && !_refreshingEstimate
        ? _estimate!.creditsRequired
        : _previewCredits(_questionCount);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QuestionCountSelector(
              value: _questionCount,
              min: _minQuestions,
              max: maxQuestions,
              onChanged: _onQuestionCountSlide,
              onChangeEnd: _onQuestionCountSlideEnd,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
                border: Border.all(
                  color: AppColors.accentCool.withValues(alpha: 0.35),
                ),
              ),
              child: AnimatedOpacity(
                opacity: _refreshingEstimate ? 0.55 : 1,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: AppColors.accentCool.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.aiGenerationCreditsCost(
                          displayCredits,
                          _estimate?.aiCreditsAvailable ?? 0,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (_refreshingEstimate)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final estimate = _estimate;
    final maxQuestions = _effectiveMax;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.aiGenerationParamsTitle),
      bottomBar: AppBottomActionBar(
        children: [
          AppGradientPrimaryButton(
            label: l10n.aiGenerationStartAction,
            isLoading: _starting,
            onPressed: _starting ||
                    _allowedQuestionTypes.isEmpty ||
                    _loadingEstimate ||
                    _isPageRangeOverLimit
                ? null
                : _start,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildScopeSection(l10n, theme),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 20,
                  color: AppColors.accent.withValues(alpha: 0.9),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.aiGenerationMaterialLanguageNotice(
                      _languageLabel(l10n, _language),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loadingEstimate)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _buildQuestionCountCard(l10n, theme, maxQuestions),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _difficulty,
            decoration: InputDecoration(labelText: l10n.aiGenerationDifficulty),
            items: [
              DropdownMenuItem(value: 'easy', child: Text(l10n.aiGenerationDifficultyEasy)),
              DropdownMenuItem(value: 'medium', child: Text(l10n.aiGenerationDifficultyMedium)),
              DropdownMenuItem(value: 'hard', child: Text(l10n.aiGenerationDifficultyHard)),
              DropdownMenuItem(value: 'mixed', child: Text(l10n.aiGenerationDifficultyMixed)),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _difficulty = v);
              _scheduleEstimateReload();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.aiGenerationQuestionTypes),
          Wrap(
            spacing: AppSpacing.sm,
            children: _allQuestionTypes.map((entry) {
              final selected = _allowedQuestionTypes.contains(entry.$1);
              return FilterChip(
                label: Text(_typeLabel(l10n, entry.$1)),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _allowedQuestionTypes.add(entry.$1);
                    } else if (_allowedQuestionTypes.length > 1) {
                      _allowedQuestionTypes.remove(entry.$1);
                    }
                  });
                  _scheduleEstimateReload();
                },
              );
            }).toList(),
          ),
          if (!_loadingEstimate && estimate == null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                l10n.aiGenerationFailed,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
