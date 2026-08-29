import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_package_repository.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_question_bank_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_launch_options_card.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshPool());
    });
  }

  @override
  void dispose() {
    _poolDebounce?.cancel();
    super.dispose();
  }

  void _schedulePoolRefresh() {
    _poolDebounce?.cancel();
    _poolDebounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_refreshPool());
    });
  }

  int _defaultQuestionCount(int pool) {
    if (pool <= 0) return 1;
    return pool < 15 ? pool : 15;
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

  Future<void> _refreshPool() async {
    if (!mounted) return;
    setState(() => _loadingPool = true);
    try {
      final sectionIds = _selectedSectionIds.isEmpty
          ? null
          : _selectedSectionIds.toList();
      final pool = widget.isOfflineDownloaded
          ? PrepPracticePoolModel(
              availableQuestionCount: await _offlineRepo.countPracticePool(
                quizId: widget.item.quizId,
                sectionIds: sectionIds,
                difficulty: _selectedDifficulty,
              ),
              maxQuestionCount: await _offlineRepo.countPracticePool(
                quizId: widget.item.quizId,
                sectionIds: sectionIds,
                difficulty: _selectedDifficulty,
              ),
            )
          : await _repo.getPracticePool(
              catalogItemId: widget.item.catalogItemId,
              sectionIds: sectionIds,
              difficulty: _selectedDifficulty,
            );
      if (!mounted) return;
      setState(() {
        _poolCount = pool.availableQuestionCount;
        if (_poolCount <= 0) {
          _selectedQuestionCount = 1;
        } else {
          if (!_questionCountInitialized) {
            _selectedQuestionCount = _defaultQuestionCount(_poolCount);
            _questionCountInitialized = true;
          } else if (_selectedQuestionCount > _poolCount) {
            _selectedQuestionCount = _poolCount;
          }
        }
      });
      _emitSelection();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _poolCount = 0;
        _selectedQuestionCount = 1;
      });
      _emitSelection();
    } finally {
      if (mounted) {
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
    _schedulePoolRefresh();
  }

  void _selectAllSections() {
    setState(() {
      _selectedSectionIds
        ..clear()
        ..addAll(widget.item.practiceSections.map((s) => s.sectionId));
    });
    _schedulePoolRefresh();
  }

  void _clearSections() {
    setState(() => _selectedSectionIds.clear());
    _schedulePoolRefresh();
  }

  void _setDifficulty(String? difficulty) {
    setState(() {
      _selectedDifficulty =
          _selectedDifficulty == difficulty ? null : difficulty;
    });
    _schedulePoolRefresh();
  }

  void _setQuestionCount(double value) {
    setState(() {
      _selectedQuestionCount = value.round();
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
    if (_loadingPool) {
      return l10n.prepPlusCustomPracticeLoadingPool;
    }
    if (_poolCount == 0) {
      return l10n.prepPlusCustomPracticeSelectFilters;
    }

    final chapterSummary = widget.item.practiceSections.isEmpty
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

  int _gridCrossAxisCount(double width) {
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  Widget _buildSectionGrid(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _gridCrossAxisCount(constraints.maxWidth);
        const spacing = AppSpacing.xs;
        final cellWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: widget.item.practiceSections.map((section) {
                final selected =
                    _selectedSectionIds.contains(section.sectionId);
                final label =
                    '${section.name} · ${section.questionCount}';
                return SizedBox(
                  width: cellWidth,
                  child: InkWell(
                    onTap: () => _toggleSection(section.sectionId, !selected),
                    borderRadius: BorderRadius.circular(AppColors.radiusSm),
                    child: Row(
                      children: [
                        Checkbox(
                          value: selected,
                          onChanged: (value) => _toggleSection(
                            section.sectionId,
                            value ?? false,
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
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
            if (widget.item.practiceSections.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.prepPlusCustomPracticeSectionsTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadingPool ? null : _selectAllSections,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(l10n.prepPlusCustomPracticeSelectAll),
                    ),
                    TextButton(
                      onPressed: _loadingPool ? null : _clearSections,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(l10n.prepPlusCustomPracticeSelectNone),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _buildSectionGrid(l10n),
              ),
            ],
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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Text(
                l10n.prepPlusCustomPracticeCountTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.prepPlusCustomPracticeSliderLabel(
                      _selectedQuestionCount,
                      _poolCount > 0 ? _poolCount : 1,
                    ),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Slider(
                    value: _poolCount > 0
                        ? _selectedQuestionCount.clamp(1, _poolCount).toDouble()
                        : 1,
                    min: 1,
                    max: (_poolCount > 0 ? _poolCount : 1).toDouble(),
                    divisions: _poolCount > 1 ? _poolCount - 1 : null,
                    label: '$_selectedQuestionCount',
                    onChanged: _poolCount > 0 ? _setQuestionCount : null,
                  ),
                ],
              ),
            ),
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
