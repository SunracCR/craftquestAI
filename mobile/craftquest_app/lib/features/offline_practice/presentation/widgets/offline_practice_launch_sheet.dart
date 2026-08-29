import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_package_repository.dart';
import 'package:craftquest_app/features/practice/data/practice_preferences_repository.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_chapter_selection_grid.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_launch_options_card.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_count_slider.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class OfflinePracticeLaunchConfig {
  const OfflinePracticeLaunchConfig({
    required this.sectionIds,
    required this.questionCount,
    required this.randomizeQuestions,
    required this.showElapsedTimer,
  });

  final List<String> sectionIds;
  final int questionCount;
  final bool randomizeQuestions;
  final bool showElapsedTimer;
}

/// Bottom sheet to configure offline practice before starting a session.
class OfflinePracticeLaunchSheet extends StatefulWidget {
  const OfflinePracticeLaunchSheet({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.package,
    required this.initialRandomizeQuestions,
    required this.initialShowTimer,
  });

  final String quizId;
  final String quizTitle;
  final OfflineQuizPackageModel package;
  final bool initialRandomizeQuestions;
  final bool initialShowTimer;

  static Future<OfflinePracticeLaunchConfig?> show(
    BuildContext context, {
    required String quizId,
    required String quizTitle,
  }) async {
    final packageRepo = getIt<OfflinePackageRepository>();
    final prefsRepo = getIt<PracticePreferencesRepository>();

    final package = await packageRepo.loadStoredQuizContent(quizId);
    if (package == null || !context.mounted) {
      return null;
    }

    var randomizeQuestions = package.randomizeQuestions;
    var showTimer = true;
    try {
      final prefs = await prefsRepo.loadLaunchOptions(quizId);
      randomizeQuestions = prefs.randomizeQuestions;
      showTimer = prefs.showTimer;
    } catch (_) {}

    if (!context.mounted) return null;

    return showModalBottomSheet<OfflinePracticeLaunchConfig>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => OfflinePracticeLaunchSheet(
        quizId: quizId,
        quizTitle: quizTitle,
        package: package,
        initialRandomizeQuestions: randomizeQuestions,
        initialShowTimer: showTimer,
      ),
    );
  }

  @override
  State<OfflinePracticeLaunchSheet> createState() =>
      _OfflinePracticeLaunchSheetState();
}

class _OfflinePracticeLaunchSheetState extends State<OfflinePracticeLaunchSheet> {
  final _selectedSectionIds = <String>{};
  late bool _randomizeQuestions;
  late bool _showTimer;
  int _selectedQuestionCount = 1;
  bool _questionCountInitialized = false;

  List<PracticeChapterOption> get _chapters =>
      OfflinePackageRepository.chapterOptionsFromPackage(widget.package);

  int get _poolCount => PracticeChapterSelectionGrid.poolCountFromSections(
        totalQuestionCount: widget.package.questions.length,
        chapters: _chapters,
        selectedSectionIds: _selectedSectionIds,
      );

  @override
  void initState() {
    super.initState();
    _randomizeQuestions = widget.initialRandomizeQuestions;
    _showTimer = widget.initialShowTimer;
    _applyPoolDefaults();
  }

  void _applyPoolDefaults() {
    final pool = _poolCount;
    if (!_questionCountInitialized) {
      _selectedQuestionCount =
          PracticeQuestionCountSlider.defaultCountForPool(pool);
      _questionCountInitialized = true;
    } else if (_selectedQuestionCount > pool) {
      _selectedQuestionCount = pool > 0 ? pool : 1;
    }
  }

  void _onSectionToggled(String sectionId, bool selected) {
    setState(() {
      if (selected) {
        _selectedSectionIds.add(sectionId);
      } else {
        _selectedSectionIds.remove(sectionId);
      }
      _applyPoolDefaults();
    });
  }

  void _selectAllSections() {
    setState(() {
      _selectedSectionIds
        ..clear()
        ..addAll(_chapters.map((s) => s.sectionId));
      _applyPoolDefaults();
    });
  }

  void _clearSections() {
    setState(() {
      _selectedSectionIds.clear();
      _applyPoolDefaults();
    });
  }

  void _startPractice() {
    if (_poolCount < 1) return;
    Navigator.of(context).pop(
      OfflinePracticeLaunchConfig(
        sectionIds: _selectedSectionIds.toList(),
        questionCount: _selectedQuestionCount,
        randomizeQuestions: _randomizeQuestions,
        showElapsedTimer: _showTimer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.quizTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.prepPlusCustomPracticeTitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: PracticeQuestionCountSlider(
                        poolCount: _poolCount,
                        selectedCount: _selectedQuestionCount,
                        onChanged: (value) {
                          setState(() {
                            _selectedQuestionCount = value;
                            _questionCountInitialized = true;
                          });
                        },
                      ),
                    ),
                    PracticeChapterSelectionGrid(
                      chapters: _chapters,
                      selectedSectionIds: _selectedSectionIds,
                      onSectionToggled: _onSectionToggled,
                      onSelectAll: _selectAllSections,
                      onClearAll: _clearSections,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PracticeLaunchOptionsCard(
                      randomizeQuestions: _randomizeQuestions,
                      showTimer: _showTimer,
                      enableSoundEffects: true,
                      showSoundEffectsOption: false,
                      onRandomizeQuestionsChanged: (value) {
                        setState(() => _randomizeQuestions = value);
                      },
                      onShowTimerChanged: (value) {
                        setState(() => _showTimer = value);
                      },
                      showSectionTitle: false,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: AppPrimaryButton(
                  label: l10n.prepPlusPracticeAction,
                  onPressed: _poolCount >= 1 ? _startPractice : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
