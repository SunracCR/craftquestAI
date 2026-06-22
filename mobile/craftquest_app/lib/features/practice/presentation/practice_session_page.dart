import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_media_display.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_answer_tile.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/app_zoomable_network_image.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:craftquest_app/features/practice/data/practice_repository.dart';
import 'package:craftquest_app/features/practice/data/practice_preferences_repository.dart';
import 'package:craftquest_app/features/practice/domain/practice_launch_options.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_elapsed_timer.dart';
import 'package:craftquest_app/features/practice/presentation/practice_result_page.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_nav_header.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_nav_status.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_resume_dialog.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_session_bottom_bar.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class PracticeSessionPage extends StatefulWidget {
  const PracticeSessionPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
    this.options = PracticeLaunchOptions.defaults,
    this.resumeSessionId,
    this.classId,
    this.assignmentId,
    this.allowAssignmentRandomizeOverride = false,
    this.forfeitExitCountsAsAttempt = false,
    this.activeSessionPrefetch,
  });

  final String quizId;
  final String quizTitle;
  final PracticeLaunchOptions options;
  final String? resumeSessionId;
  final String? classId;
  final String? assignmentId;
  final bool allowAssignmentRandomizeOverride;
  final bool forfeitExitCountsAsAttempt;
  final Future<PracticeActiveSessionModel?>? activeSessionPrefetch;

  @override
  State<PracticeSessionPage> createState() => _PracticeSessionPageState();
}

class _PracticeSessionPageState extends State<PracticeSessionPage> {
  final _repository = getIt<PracticeRepository>();

  PracticeSessionModel? _session;
  PracticeLaunchOptions _launchOptions = PracticeLaunchOptions.defaults;
  final Map<String, String> _questionStatuses = {};
  final Map<String, Set<String>> _pendingSelections = {};
  int _currentIndex = 0;
  bool _loading = true;
  bool _finishing = false;
  bool _savingProgress = false;
  String? _error;
  String? _loadingMessage;
  bool _showTimer = false;
  Duration _elapsedBaseline = Duration.zero;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _elapsedTicker;
  final Map<String, Timer> _persistDebounceTimers = {};
  final Map<String, Future<void>> _persistInFlight = {};

  @override
  void initState() {
    super.initState();
    _launchOptions = widget.options;
    _showTimer = widget.options.showTimer;
    if (widget.resumeSessionId != null) {
      _resumeSession(widget.resumeSessionId!);
    } else {
      _initializeSession();
    }
  }

  Future<void> _initializeSession() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
      _loadingMessage = l10n.practicePreparingSession;
    });

    try {
      PracticeActiveSessionModel? active;
      if (widget.activeSessionPrefetch != null) {
        active = await widget.activeSessionPrefetch;
      } else {
        active = await _repository.getActiveSessionForQuiz(
          widget.quizId,
          assignmentId: widget.assignmentId,
        );
      }

      if (!mounted) {
        return;
      }

      if (active != null) {
        final choice = await showPracticeResumeDialog(
          context,
          summary: active,
        );
        if (!mounted || choice == null || choice == PracticeResumeChoice.cancel) {
          Navigator.of(context).pop();
          return;
        }
        if (choice == PracticeResumeChoice.resume) {
          await _resumeSession(active.practiceSessionId);
          return;
        }
        await _repository.abandonSession(active.practiceSessionId);
      }

      if (widget.assignmentId == null) {
        try {
          final preferencesRepository = getIt<PracticePreferencesRepository>();
          _launchOptions =
              await preferencesRepository.loadLaunchOptions(widget.quizId);
        } catch (_) {
          _launchOptions = widget.options;
        }
      } else {
        _launchOptions = widget.options;
      }

      if (!mounted) {
        return;
      }

      _showTimer = _launchOptions.showTimer;
      await _start();
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = DioErrorMapper.map(e);
        _loading = false;
        _loadingMessage = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = DioErrorMapper.genericMessage();
        _loading = false;
        _loadingMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _elapsedTicker?.cancel();
    for (final timer in _persistDebounceTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> _awaitPendingPersists() async {
    for (final timer in _persistDebounceTimers.values) {
      timer.cancel();
    }
    _persistDebounceTimers.clear();
    if (_persistInFlight.isNotEmpty) {
      await Future.wait(_persistInFlight.values);
    }
  }

  Duration get _totalElapsed => _elapsedBaseline + _stopwatch.elapsed;

  void _beginElapsedTimer() {
    if (!_showTimer) {
      return;
    }
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
    }
    _elapsedTicker?.cancel();
    _elapsedTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _applySession(PracticeSessionModel session) {
    _questionStatuses.clear();
    _pendingSelections.clear();
    for (final q in session.questions) {
      _questionStatuses[q.practiceQuestionSnapshotId] = q.answerStatus;
      _hydrateSelections(q);
    }
    final index = session.currentQuestionIndex.clamp(
      0,
      session.questions.isEmpty ? 0 : session.questions.length - 1,
    );
    _showTimer = session.showElapsedTimer;
    _elapsedBaseline = Duration(seconds: session.elapsedSecondsBeforePause);
    _currentIndex = index;
    _session = session;
  }

  Future<void> _resumeSession(String sessionId) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
      _loadingMessage = l10n.practicePreparingSession;
    });
    try {
      final session = await _repository.getSession(sessionId);
      if (!mounted) return;
      setState(() {
        _applySession(session);
        _loading = false;
        _loadingMessage = null;
      });
      _beginElapsedTimer();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.map(e);
        _loading = false;
        _loadingMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.genericMessage();
        _loading = false;
        _loadingMessage = null;
      });
    }
  }

  Future<void> _saveProgress() async {
    final session = _session;
    if (session == null || _savingProgress) {
      return;
    }
    setState(() => _savingProgress = true);
    try {
      await _repository.updateProgress(
        sessionId: session.practiceSessionId,
        currentQuestionIndex: _currentIndex,
        elapsedSecondsBeforePause: _totalElapsed.inSeconds,
      );
    } finally {
      if (mounted) {
        setState(() => _savingProgress = false);
      }
    }
  }

  bool get _forfeitExitApplies =>
      widget.assignmentId != null && widget.forfeitExitCountsAsAttempt;

  Future<bool> _confirmForfeitExit() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.practiceForfeitExitDialogTitle),
        content: Text(l10n.practiceForfeitExitDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.practiceForfeitExitCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.practiceForfeitExitConfirm),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _forfeitAndExit() async {
    final session = _session;
    if (session == null) {
      return;
    }
    _stopElapsedTimer();
    setState(() => _savingProgress = true);
    try {
      await _repository.forfeitSession(session.practiceSessionId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } catch (_) {
      if (!mounted) return;
      context.showErrorSnackBar(DioErrorMapper.genericMessage());
    } finally {
      if (mounted) {
        setState(() => _savingProgress = false);
      }
    }
  }

  Future<void> _handleExitAttempt() async {
    if (_forfeitExitApplies) {
      final confirmed = await _confirmForfeitExit();
      if (!confirmed || !mounted) {
        return;
      }
      await _forfeitAndExit();
      return;
    }
    await _saveAndExit();
  }

  Future<void> _saveAndExit() async {
    _stopElapsedTimer();
    await _awaitPendingPersists();
    await _saveProgress();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _stopElapsedTimer() {
    _elapsedTicker?.cancel();
    _elapsedTicker = null;
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
    }
  }

  String _formatElapsed(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
      _loadingMessage = l10n.practicePreparingSession;
    });
    try {
      final session = await _repository.startSession(
        quizId: widget.quizId,
        randomizeQuestions: widget.assignmentId != null
            ? (widget.allowAssignmentRandomizeOverride
                ? _launchOptions.randomizeQuestions
                : null)
            : _launchOptions.randomizeQuestions,
        showElapsedTimer: _launchOptions.showTimer,
        classId: widget.classId,
        assignmentId: widget.assignmentId,
      );
      if (!mounted) return;
      setState(() {
        _applySession(session);
        _loading = false;
        _loadingMessage = null;
      });
      _beginElapsedTimer();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.map(e);
        _loading = false;
        _loadingMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.genericMessage();
        _loading = false;
        _loadingMessage = null;
      });
    }
  }

  PracticeQuestionModel? get _currentQuestion {
    final session = _session;
    if (session == null || session.questions.isEmpty) {
      return null;
    }
    if (_currentIndex >= session.questions.length) {
      return null;
    }
    return session.questions[_currentIndex];
  }

  String _statusFor(PracticeQuestionModel question) =>
      _questionStatuses[question.practiceQuestionSnapshotId] ?? 'unanswered';

  bool _isQuestionDone(PracticeQuestionModel question) {
    if (_statusFor(question) == 'answered') {
      return true;
    }
    return _selectionFor(question).isNotEmpty;
  }

  int get _completedCount {
    final session = _session;
    if (session == null) return 0;
    return session.questions.where(_isQuestionDone).length;
  }

  bool get _allCompleted {
    final session = _session;
    if (session == null) return false;
    return _completedCount >= session.questions.length;
  }

  Set<String> _selectionFor(PracticeQuestionModel question) {
    return _pendingSelections.putIfAbsent(
      question.practiceQuestionSnapshotId,
      () => {},
    );
  }

  bool _isSingleSelect(String questionType) {
    return questionType == 'single_choice' ||
        questionType == 'true_false' ||
        questionType == 'image_choice' ||
        questionType == 'image_based_question';
  }

  List<PracticeQuestionNavStatus> _navStatuses() {
    final session = _session!;
    return session.questions.map((q) {
      return _isQuestionDone(q)
          ? PracticeQuestionNavStatus.answered
          : PracticeQuestionNavStatus.pending;
    }).toList();
  }

  void _hydrateSelections(PracticeQuestionModel question) {
    if (question.selectedAnswerOptionIds.isEmpty) return;
    _pendingSelections[question.practiceQuestionSnapshotId] =
        question.selectedAnswerOptionIds.toSet();
  }

  void _goToQuestion(int index) {
    final session = _session;
    if (session == null) return;
    if (index < 0 || index >= session.questions.length) return;
    setState(() {
      _currentIndex = index;
      _hydrateSelections(session.questions[index]);
    });
  }

  Future<void> _persistSelection(PracticeQuestionModel question) async {
    final session = _session;
    if (session == null) {
      return;
    }

    final questionId = question.practiceQuestionSnapshotId;
    final selected = _selectionFor(question).toList();
    if (selected.isEmpty) {
      if (_statusFor(question) == 'answered') {
        setState(() => _questionStatuses[questionId] = 'unanswered');
      }
      return;
    }

    final future = _repository.submitAnswer(
      sessionId: session.practiceSessionId,
      practiceQuestionSnapshotId: questionId,
      selectedAnswerOptionIds: selected,
    ).then((_) async {
      if (!mounted) return;
      setState(() => _questionStatuses[questionId] = 'answered');
    }).catchError((Object error) {
      if (!mounted) return;
      if (error is DioException) {
        context.showDioErrorSnackBar(error);
      }
      setState(() {
        _questionStatuses.remove(questionId);
      });
    }).whenComplete(() {
      _persistInFlight.remove(questionId);
    });

    _persistInFlight[questionId] = future;
  }

  void _schedulePersistSelection(PracticeQuestionModel question) {
    final questionId = question.practiceQuestionSnapshotId;
    if (_isSingleSelect(question.questionType)) {
      unawaited(_persistSelection(question));
      return;
    }

    _persistDebounceTimers[questionId]?.cancel();
    _persistDebounceTimers[questionId] = Timer(
      const Duration(milliseconds: 450),
      () {
        _persistDebounceTimers.remove(questionId);
        if (mounted) {
          unawaited(_persistSelection(question));
        }
      },
    );
  }

  void _toggleSingleOption(
    PracticeQuestionModel question,
    String answerOptionId,
  ) {
    final questionId = question.practiceQuestionSnapshotId;
    setState(() {
      _selectionFor(question)
        ..clear()
        ..add(answerOptionId);
      _questionStatuses[questionId] = 'answered';
    });
    _schedulePersistSelection(question);
  }

  void _toggleMultiOption(
    PracticeQuestionModel question,
    String answerOptionId,
    bool wasSelected,
  ) {
    final questionId = question.practiceQuestionSnapshotId;
    setState(() {
      final set = _selectionFor(question);
      if (wasSelected) {
        set.remove(answerOptionId);
      } else {
        set.add(answerOptionId);
      }
      if (set.isEmpty) {
        _questionStatuses.remove(questionId);
      } else {
        _questionStatuses[questionId] = 'answered';
      }
    });
    _schedulePersistSelection(question);
  }

  Future<void> _finish() async {
    final session = _session;
    if (session == null) {
      return;
    }

    setState(() => _finishing = true);
    try {
      await _awaitPendingPersists();
      _stopElapsedTimer();
      final result =
          await _repository.finishSession(session.practiceSessionId);
      if (!mounted) return;
      final elapsed = _showTimer ? _totalElapsed : null;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PracticeResultPage(
            result: result,
            quizTitle: widget.quizTitle,
            elapsed: elapsed,
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _finishing = false);
      context.showDioErrorSnackBar(e);
    }
  }

  Widget? _buildBottomBar(AppLocalizations l10n) {
    final session = _session;
    if (session == null || session.questions.isEmpty) {
      return null;
    }

    final isBusy = _finishing;

    return PracticeSessionBottomBar(
      canGoBack: _currentIndex > 0,
      canGoForward: _currentIndex < session.questions.length - 1,
      allCompleted: _allCompleted,
      isBusy: isBusy,
      onPrevious: () => _goToQuestion(_currentIndex - 1),
      onNext: () => _goToQuestion(_currentIndex + 1),
      onFinish: _finish,
      l10n: l10n,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = _session;
    final question = _currentQuestion;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleExitAttempt();
      },
      child: EdgeAwareScaffold(
      appBar: craftQuestAppBar(
        title: widget.quizTitle,
        actions: [
          if (_finishing || _savingProgress)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          if (!_forfeitExitApplies)
            IconButton(
              tooltip: l10n.practiceSaveAndExitAction,
              onPressed: (_session == null || _finishing || _savingProgress)
                  ? null
                  : _saveAndExit,
              icon: const Icon(Icons.pause_circle_outline_rounded),
            ),
        ],
      ),
      bottomBar: _buildBottomBar(l10n),
      body: _loading
          ? AppLoadingView(message: _loadingMessage)
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: widget.resumeSessionId != null
                      ? () => _resumeSession(widget.resumeSessionId!)
                      : _initializeSession,
                )
              : session == null || question == null
                  ? AppEmptyView(message: l10n.practiceNoQuestions)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.xs,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PracticeQuestionNavHeader(
                                currentIndex: _currentIndex,
                                displayOrder: question.displayOrder,
                                totalQuestions: session.questions.length,
                                completedCount: _completedCount,
                                statuses: _navStatuses(),
                                onSelected: _goToQuestion,
                              ),
                              if (_showTimer) ...[
                                const SizedBox(height: AppSpacing.sm),
                                PracticeElapsedTimer(
                                  label: l10n.practiceElapsedLabel(
                                    _formatElapsed(_totalElapsed),
                                  ),
                                ),
                              ],
                            ],
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
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  question.questionText,
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                ),
                                if (_resolveMediaUrl(question.questionMediaUrl) !=
                                    null) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  AppZoomableNetworkImage(
                                    imageUrl: _resolveMediaUrl(
                                      question.questionMediaUrl,
                                    )!,
                                    height: AppMediaDisplay.questionImageHeight,
                                    borderRadius: BorderRadius.circular(
                                      AppColors.radiusSm,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.lg),
                                IgnorePointer(
                                  ignoring: _finishing,
                                  child: Column(
                                    children: question.answers.map((option) {
                                      final selected = _selectionFor(question)
                                          .contains(option.answerOptionId);
                                      final optionText = option.text?.trim();
                                      final label = optionText != null &&
                                              optionText.isNotEmpty
                                          ? '${option.displayLabel}. $optionText'
                                          : option.displayLabel;
                                      final imageUrl =
                                          _resolveMediaUrl(option.mediaUrl);
                                      if (_isSingleSelect(
                                        question.questionType,
                                      )) {
                                        return AppAnswerTile(
                                          label: label,
                                          selected: selected,
                                          mediaImageUrl: imageUrl,
                                          onTap: () => _toggleSingleOption(
                                            question,
                                            option.answerOptionId,
                                          ),
                                        );
                                      }

                                      return AppAnswerTile(
                                        label: label,
                                        selected: selected,
                                        mediaImageUrl: imageUrl,
                                        onTap: () => _toggleMultiOption(
                                          question,
                                          option.answerOptionId,
                                          selected,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
      ),
    );
  }

  String? _resolveMediaUrl(String? mediaUrl) {
    if (mediaUrl == null || mediaUrl.isEmpty) {
      return null;
    }
    if (mediaUrl.startsWith('http')) {
      return mediaUrl;
    }
    final baseUrl =
        getIt<ApiClient>().dio.options.baseUrl.replaceAll(RegExp(r'/$'), '');
    final path = mediaUrl.startsWith('/') ? mediaUrl : '/$mediaUrl';
    return '$baseUrl$path';
  }
}
