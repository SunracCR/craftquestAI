import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_package_repository.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_chapter_selection_grid.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_launch_options_card.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_count_slider.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PrepCustomPracticeSelection {
  const PrepCustomPracticeSelection({
    this.sectionIds = const [],
    this.difficulty,
    this.questionCount = 1,
    this.poolCount = 0,
  });

  final List<String> sectionIds;
  final String? difficulty;
  final int questionCount;
  final int poolCount;

  bool get isValid => poolCount >= 1;
}

/// Configurador de práctica a medida para ítems Prep+ con acceso activo.
class PrepPlusCustomPracticePanel extends StatefulWidget {
  const PrepPlusCustomPracticePanel({
    super.key,
    required this.item,
    required this.randomizeQuestions,
    required this.showTimer,
    required this.enableSoundEffects,
    required this.onSelectionChanged,
    required this.onRandomizeQuestionsChanged,
    required this.onShowTimerChanged,
    required this.onSoundEffectsChanged,
    this.isLoading = false,
    this.isOfflineDownloaded = false,
  });

  final PrepItemDetailModel item;
  final bool randomizeQuestions;
  final bool showTimer;
  final bool enableSoundEffects;
  final ValueChanged<PrepCustomPracticeSelection> onSelectionChanged;
  final ValueChanged<bool> onRandomizeQuestionsChanged;
  final ValueChanged<bool> onShowTimerChanged;
  final ValueChanged<bool> onSoundEffectsChanged;
  final bool isLoading;
  final bool isOfflineDownloaded;

  @override
  State<PrepPlusCustomPracticePanel> createState() =>
      _PrepPlusCustomPracticePanelState();
}

class _PrepPlusCustomPracticePanelState extends State<PrepPlusCustomPracticePanel> {
  final _repo = getIt<PrepPlusRepository>();
  final _offlineRepo = getIt<OfflinePackageRepository>();
  final _selectedSectionIds = <String>{};
  String? _selectedDifficulty;
  int _selectedQuestionCount = 1;
  int _poolCount = 0;
  bool _loadingPool = false;
  bool _expanded = true;
  bool _questionCountInitialized = false;
  Timer? _poolDebounce;
  int _poolRefreshGeneration = 0;

  List<PracticeChapterOption> get _chapterOptions =>
      widget.item.practiceSections
          .map(
            (s) => PracticeChapterOption(
              sectionId: s.sectionId,
              name: s.name,
              questionCount: s.questionCount,
            ),
          )
          .toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyLocalPool(emit: false);
      unawaited(_confirmPoolFromNetwork());
    });
  }

  @override
  void dispose() {
    _poolDebounce?.cancel();
    super.dispose();
  }

  int _localPoolCount() {
    return PracticeChapterSelectionGrid.poolCountFromSections(
      totalQuestionCount: widget.item.questionCount,
      chapters: _chapterOptions,
      selectedSectionIds: _selectedSectionIds,
    );
  }

  void _applyLocalPool({required bool emit}) {
    final localPool = _localPoolCount();
    setState(() {
      _poolCount = localPool;
      if (localPool <= 0) {
        _selectedQuestionCount = 1;
      } else if (!_questionCountInitialized) {
        _selectedQuestionCount =
            PracticeQuestionCountSlider.defaultCountForPool(localPool);
        _questionCountInitialized = true;
      } else if (_selectedQuestionCount > localPool) {
        _selectedQuestionCount = localPool;
      }
    });
    if (emit) {
      _emitSelection();
    }
  }

  void _schedulePoolConfirm() {
    _applyLocalPool(emit: true);
    _poolDebounce?.cancel();
    _poolDebounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_confirmPoolFromNetwork());
    });
  }

  void _emitSelection() {
    widget.onSelectionChanged(
      PrepCustomPracticeSelection(
        sectionIds: _selectedSectionIds.toList(),
        difficulty: _selectedDifficulty,
        questionCount: _poolCount > 0 ? _selectedQuestionCount : 1,
        poolCount: _poolCount,
      ),
    );
  }

  Future<void> _confirmPoolFromNetwork() async {
    if (!mounted) return;
    final generation = ++_poolRefreshGeneration;
    setState(() => _loadingPool = true);

    try {
      final sectionIds = _selectedSectionIds.isEmpty
          ? null
          : _selectedSectionIds.toList();

      final remoteCount = widget.isOfflineDownloaded
          ? await _offlineRepo.countPracticePool(
              quizId: widget.item.quizId,
              sectionIds: sectionIds,
              difficulty: _selectedDifficulty,
            )
          : (await _repo.getPracticePool(
              catalogItemId: widget.item.catalogItemId,
              sectionIds: sectionIds,
              difficulty: _selectedDifficulty,
            ))
              .availableQuestionCount;

      if (!mounted || generation != _poolRefreshGeneration) return;

      setState(() {
        if (remoteCount > 0) {
          _poolCount = remoteCount;
          if (!_questionCountInitialized) {
            _selectedQuestionCount =
                PracticeQuestionCountSlider.defaultCountForPool(remoteCount);
            _questionCountInitialized = true;
          } else if (_selectedQuestionCount > remoteCount) {
            _selectedQuestionCount = remoteCount;
          }
        }
      });
      _emitSelection();
    } catch (_) {
      // Keep last good local pool; do not zero out on transient errors.
      if (mounted && generation == _poolRefreshGeneration) {
        _emitSelection();
      }
    } finally {
      if (mounted && generation == _poolRefreshGeneration) {
        setState(() => _loadingPool = false);
      }
    }
  }

  void _toggleSection(String sectionId, bool selected) {
    setState(() {
      if (selected) {
        _selectedSectionIds.add(sectionId);
      } else {
        _selectedSectionIds.remove(sectionId);
      }
    });
    _schedulePoolConfirm();
  }

  void _selectAllSections() {
    setState(() {
      _selectedSectionIds
        ..clear()
        ..addAll(_chapterOptions.map((s) => s.sectionId));
    });
    _schedulePoolConfirm();
  }

  void _clearSections() {
    setState(() => _selectedSectionIds.clear());
    _schedulePoolConfirm();
  }

  void _setDifficulty(String? difficulty) {
    setState(() {
      _selectedDifficulty =
          _selectedDifficulty == difficulty ? null : difficulty;
    });
    _schedulePoolConfirm();
  }

  void _setQuestionCount(int value) {
    setState(() {
      _selectedQuestionCount = value;
      _questionCountInitialized = true;
    });
    _emitSelection();
  }

  String _difficultyLabel(AppLocalizations l10n, String code) {
    return switch (code) {
      'easy' => l10n.prepPlusCustomPracticeDifficultyEasy,
      'medium' => l10n.prepPlusCustomPracticeDifficultyMedium,
      'hard' => l10n.prepPlusCustomPracticeDifficultyHard,
      _ => code,
    };
  }

  String _summary(AppLocalizations l10n) {
    if (_loadingPool && _poolCount == 0) {
      return l10n.prepPlusCustomPracticeLoadingPool;
    }
    if (_poolCount == 0) {
      return l10n.prepPlusCustomPracticeSelectFilters;
    }

    final chapterSummary = _chapterOptions.isEmpty
        ? null
        : _selectedSectionIds.isEmpty
            ? l10n.prepPlusCustomPracticeAllChapters
            : l10n.prepPlusCustomPracticeChaptersSummary(
                _selectedSectionIds.length,
                _poolCount,
              );

    final countLabel = l10n.prepPlusCustomPracticeSliderLabel(
      _selectedQuestionCount,
      _poolCount,
    );

    if (chapterSummary == null) {
      return countLabel;
    }
    return '$chapterSummary · $countLabel';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.prepPlusCustomPracticeTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _summary(l10n),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_loadingPool)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(
              height: 1,
              color: AppColors.textSecondary.withValues(alpha: 0.12),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: PracticeQuestionCountSlider(
                poolCount: _poolCount,
                selectedCount: _selectedQuestionCount,
                onChanged: _setQuestionCount,
              ),
            ),
            PracticeChapterSelectionGrid(
              chapters: _chapterOptions,
              selectedSectionIds: _selectedSectionIds,
              onSectionToggled: _toggleSection,
              loading: _loadingPool,
              onSelectAll: _selectAllSections,
              onClearAll: _clearSections,
            ),
            if (widget.item.availableDifficulties.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Text(
                  l10n.prepPlusCustomPracticeDifficultyTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: widget.item.availableDifficulties.map((code) {
                    final selected = _selectedDifficulty == code;
                    return FilterChip(
                      label: Text(_difficultyLabel(l10n, code)),
                      selected: selected,
                      onSelected: (_) => _setDifficulty(code),
                    );
                  }).toList(),
                ),
              ),
            ],
            Divider(
              height: AppSpacing.lg,
              color: AppColors.textSecondary.withValues(alpha: 0.12),
            ),
            PracticeLaunchOptionsCard(
              randomizeQuestions: widget.randomizeQuestions,
              showTimer: widget.showTimer,
              enableSoundEffects: widget.enableSoundEffects,
              onRandomizeQuestionsChanged: widget.onRandomizeQuestionsChanged,
              onShowTimerChanged: widget.onShowTimerChanged,
              onSoundEffectsChanged: widget.onSoundEffectsChanged,
              showSectionTitle: false,
            ),
          ],
        ],
      ),
    );
  }
}
