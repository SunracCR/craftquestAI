import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_answer_tile.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:craftquest_app/features/prep_plus/domain/prep_preview_grader.dart';
import 'package:craftquest_app/features/prep_plus/presentation/prep_plus_preview_result_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Vista previa interactiva: califica en el cliente al finalizar (sin esperar al servidor).
class PrepPlusPreviewPage extends StatefulWidget {
  const PrepPlusPreviewPage({
    super.key,
    required this.catalogItemId,
    required this.title,
  });

  final String catalogItemId;
  final String title;

  @override
  State<PrepPlusPreviewPage> createState() => _PrepPlusPreviewPageState();
}

class _PrepPlusPreviewPageState extends State<PrepPlusPreviewPage> {
  final _repository = getIt<PrepPlusRepository>();
  bool _loading = true;
  String? _error;
  PrepPreviewModel? _preview;
  int _currentIndex = 0;
  final Map<String, Set<String>> _selections = {};
  final Stopwatch _elapsed = Stopwatch();

  List<PrepPreviewQuestionModel> get _questions =>
      _preview?.sampleQuestions ?? [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _elapsed.stop();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preview = await _repository.getPreview(widget.catalogItemId);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _loading = false;
      });
      _elapsed
        ..reset()
        ..start();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _repository.mapError(e, AppLocalizations.of(context)!);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.genericMessage(AppLocalizations.of(context)!);
        _loading = false;
      });
    }
  }

  PrepPreviewQuestionModel? get _question =>
      _questions.isEmpty ? null : _questions[_currentIndex];

  bool _isSingleSelect(String type) =>
      type == 'single_choice' || type == 'true_false';

  Set<String> _selectionFor(String questionId) =>
      _selections[questionId] ?? {};

  void _toggleOption(PrepPreviewQuestionModel question, String optionId) {
    setState(() {
      final current = _selectionFor(question.questionId);
      if (_isSingleSelect(question.questionType)) {
        _selections[question.questionId] = {optionId};
      } else {
        final next = Set<String>.from(current);
        if (next.contains(optionId)) {
          next.remove(optionId);
        } else {
          next.add(optionId);
        }
        _selections[question.questionId] = next;
      }
    });
  }

  void _goTo(int index) {
    if (index < 0 || index >= _questions.length) return;
    setState(() => _currentIndex = index);
  }

  Future<void> _finishSimulation() async {
    final preview = _preview;
    if (preview == null) {
      return;
    }

    _elapsed.stop();
    final elapsed = _elapsed.elapsed;

    try {
      final PrepPreviewFinishResultModel result;
      if (preview.finishPackage != null) {
        result = PrepPreviewGrader.grade(
          preview: preview,
          selections: _selections,
        );
      } else {
        result = await _repository.finishPreview(
          catalogItemId: widget.catalogItemId,
          selections: _selections,
          durationSeconds: elapsed.inSeconds,
        );
      }

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PrepPlusPreviewResultPage(
            result: result,
            quizTitle: widget.title,
            catalogItemId: widget.catalogItemId,
            elapsed: elapsed,
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      _elapsed.start();
      context.showDioErrorSnackBar(e);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _elapsed.start();
      context.showErrorSnackBar(
        DioErrorMapper.genericMessage(AppLocalizations.of(context)!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final question = _question;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.prepPlusPreviewSimulationTitle),
      bottomBar: question == null
          ? null
          : AppBottomActionBar(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 108,
                      child: Opacity(
                        opacity: _currentIndex > 0 ? 1 : 0,
                        child: IgnorePointer(
                          ignoring: _currentIndex == 0,
                          child: AppTextActionButton(
                            label: l10n.prepPlusPreviewPrevious,
                            onPressed: () => _goTo(_currentIndex - 1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppPrimaryButton(
                        label: _currentIndex >= _questions.length - 1
                            ? l10n.prepPlusPreviewFinishCta
                            : l10n.prepPlusPreviewNext,
                        onPressed: () {
                          if (_currentIndex >= _questions.length - 1) {
                            unawaited(_finishSimulation());
                          } else {
                            _goTo(_currentIndex + 1);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : question == null
                  ? AppEmptyView(message: l10n.prepAdminSamplesEmpty)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SimulationBanner(l10n: l10n, title: widget.title),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.xs,
                          ),
                          child: _PreviewProgressStrip(
                            current: _currentIndex,
                            total: _questions.length,
                            onDotTap: _goTo,
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.prepPlusPreviewQuestionLabel(
                                    _currentIndex + 1,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.accentGold,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  question.text,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        height: 1.25,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l10n.prepPlusPreviewTryInteraction,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                ...question.answerOptions.asMap().entries.map(
                                  (entry) {
                                    final option = entry.value;
                                    final labelIndex = entry.key;
                                    final letter = String.fromCharCode(
                                      65 + labelIndex,
                                    );
                                    final optionText = option.text?.trim();
                                    final label = optionText != null &&
                                            optionText.isNotEmpty
                                        ? '$letter. $optionText'
                                        : '$letter. ${option.stableKey}';
                                    final selected = _selectionFor(
                                      question.questionId,
                                    ).contains(option.answerOptionId);
                                    return AppAnswerTile(
                                      label: label,
                                      selected: selected,
                                      onTap: () => _toggleOption(
                                        question,
                                        option.answerOptionId,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: AppSpacing.xl),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _SimulationBanner extends StatelessWidget {
  const _SimulationBanner({required this.l10n, required this.title});

  final AppLocalizations l10n;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentCool.withValues(alpha: 0.25),
            AppColors.accentGold.withValues(alpha: 0.18),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.accentGold.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.play_circle_outline_rounded,
            color: AppColors.accentGold,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.prepPlusPreviewSimulationBanner,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  l10n.prepPlusPreviewSimulationSubtitle(title),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewProgressStrip extends StatelessWidget {
  const _PreviewProgressStrip({
    required this.current,
    required this.total,
    required this.onDotTap,
  });

  final int current;
  final int total;
  final ValueChanged<int> onDotTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.prepPlusPreviewQuestionLabel(current + 1),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              '$total',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: List.generate(total, (i) {
            final active = i == current;
            final done = i < current;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: i < total - 1 ? 4 : 0,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onDotTap(i),
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: active
                            ? AppColors.accentGold
                            : done
                                ? AppColors.accentMint.withValues(alpha: 0.7)
                                : AppColors.inputBorder,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
