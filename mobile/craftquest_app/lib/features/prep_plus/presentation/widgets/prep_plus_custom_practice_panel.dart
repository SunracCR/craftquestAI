import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_launch_options_card.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PrepCustomPracticeSelection {
  const PrepCustomPracticeSelection({
    this.sectionIds = const [],
    this.topicIds = const [],
    this.difficulty,
    this.questionCount,
    this.poolCount = 0,
  });

  final List<String> sectionIds;
  final List<String> topicIds;
  final String? difficulty;
  final int? questionCount;
  final int poolCount;

  bool get isValid => poolCount > 0;
}

/// Configurador de práctica a medida para ítems Prep+ con banco etiquetado.
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

  @override
  State<PrepPlusCustomPracticePanel> createState() =>
      _PrepPlusCustomPracticePanelState();
}

class _PrepPlusCustomPracticePanelState extends State<PrepPlusCustomPracticePanel> {
  final _repo = getIt<PrepPlusRepository>();
  final _selectedSectionIds = <String>{};
  final _selectedTopicIds = <String>{};
  String? _selectedDifficulty;
  int? _selectedQuestionCount;
  int _poolCount = 0;
  bool _loadingPool = false;
  bool _expanded = true;
  Timer? _poolDebounce;

  static const _questionCountPresets = [10, 15, 20, 30];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emitSelection();
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

  Future<void> _refreshPool() async {
    if (!mounted) return;
    setState(() => _loadingPool = true);
    try {
      final pool = await _repo.getPracticePool(
        catalogItemId: widget.item.catalogItemId,
        sectionIds: _selectedSectionIds.isEmpty
            ? null
            : _selectedSectionIds.toList(),
        topicIds:
            _selectedTopicIds.isEmpty ? null : _selectedTopicIds.toList(),
        difficulty: _selectedDifficulty,
      );
      if (!mounted) return;
      setState(() {
        _poolCount = pool.availableQuestionCount;
        if (_selectedQuestionCount != null &&
            _selectedQuestionCount! > _poolCount) {
          _selectedQuestionCount = _poolCount > 0 ? _poolCount : null;
        }
      });
      _emitSelection();
    } catch (_) {
      if (!mounted) return;
      setState(() => _poolCount = 0);
      _emitSelection();
    } finally {
      if (mounted) {
        setState(() => _loadingPool = false);
      }
    }
  }

  void _emitSelection() {
    widget.onSelectionChanged(
      PrepCustomPracticeSelection(
        sectionIds: _selectedSectionIds.toList(),
        topicIds: _selectedTopicIds.toList(),
        difficulty: _selectedDifficulty,
        questionCount: _selectedQuestionCount,
        poolCount: _poolCount,
      ),
    );
  }

  void _toggleSection(String sectionId, bool selected) {
    setState(() {
      if (selected) {
        _selectedSectionIds.add(sectionId);
      } else {
        _selectedSectionIds.remove(sectionId);
        final section = widget.item.practiceSections
            .firstWhere((s) => s.sectionId == sectionId);
        for (final topic in section.topics) {
          _selectedTopicIds.remove(topic.topicId);
        }
      }
    });
    _schedulePoolRefresh();
  }

  void _toggleTopic(String topicId, bool selected) {
    setState(() {
      if (selected) {
        _selectedTopicIds.add(topicId);
      } else {
        _selectedTopicIds.remove(topicId);
      }
    });
    _schedulePoolRefresh();
  }

  void _setDifficulty(String? difficulty) {
    setState(() {
      _selectedDifficulty =
          _selectedDifficulty == difficulty ? null : difficulty;
    });
    _schedulePoolRefresh();
  }

  void _setQuestionCount(int? count) {
    setState(() => _selectedQuestionCount = count);
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
    final countLabel = _selectedQuestionCount == null
        ? l10n.prepPlusCustomPracticeAllQuestions(_poolCount)
        : l10n.prepPlusCustomPracticeQuestionCountSummary(
            _selectedQuestionCount!,
            _poolCount,
          );
    return countLabel;
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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Text(
                l10n.prepPlusCustomPracticeSectionsTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ...widget.item.practiceSections.map((section) {
              final sectionSelected =
                  _selectedSectionIds.contains(section.sectionId);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CheckboxListTile(
                    value: sectionSelected,
                    onChanged: (value) =>
                        _toggleSection(section.sectionId, value ?? false),
                    title: Text(section.name),
                    subtitle: Text(
                      l10n.prepPlusCustomPracticeSectionCount(
                        section.questionCount,
                      ),
                    ),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (sectionSelected && section.topics.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.lg),
                      child: Column(
                        children: section.topics.map((topic) {
                          return CheckboxListTile(
                            value: _selectedTopicIds.contains(topic.topicId),
                            onChanged: (value) => _toggleTopic(
                              topic.topicId,
                              value ?? false,
                            ),
                            title: Text(topic.name),
                            subtitle: Text(
                              l10n.prepPlusCustomPracticeTopicCount(
                                topic.questionCount,
                              ),
                            ),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        }).toList(),
                      ),
                    ),
                ],
              );
            }),
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
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  ..._questionCountPresets.map((count) {
                    final enabled = _poolCount >= count;
                    return ChoiceChip(
                      label: Text('$count'),
                      selected: _selectedQuestionCount == count,
                      onSelected: enabled
                          ? (_) => _setQuestionCount(count)
                          : null,
                    );
                  }),
                  ChoiceChip(
                    label: Text(l10n.prepPlusCustomPracticeAllChip),
                    selected: _selectedQuestionCount == null,
                    onSelected: _poolCount > 0
                        ? (_) => _setQuestionCount(null)
                        : null,
                  ),
                ],
              ),
            ),
            if (_poolCount > 0 &&
                _selectedQuestionCount != null &&
                _selectedQuestionCount! > _poolCount)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  0,
                ),
                child: Text(
                  l10n.prepPlusCustomPracticePoolLimited(_poolCount),
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                  ),
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
