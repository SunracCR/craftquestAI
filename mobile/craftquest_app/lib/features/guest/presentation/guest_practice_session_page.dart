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
import 'package:craftquest_app/features/guest/data/guest_repository.dart';
import 'package:craftquest_app/features/guest/presentation/bloc/guest_session_cubit.dart';
import 'package:craftquest_app/features/guest/presentation/guest_result_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:craftquest_app/features/practice/presentation/practice_image_precacher.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_elapsed_timer.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_nav_header.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_nav_status.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_resume_dialog.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_session_bottom_bar.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class GuestPracticeSessionPage extends StatefulWidget {
  const GuestPracticeSessionPage({
    super.key,
    required this.visitId,
    required this.token,
    required this.quizTitle,
    this.randomizeQuestions,
    this.showElapsedTimer = false,
    this.activeSessionPrefetch,
  });

  final String visitId;
  final String token;
  final String quizTitle;
  final bool? randomizeQuestions;
  final bool showElapsedTimer;
  final Future<PracticeActiveSessionModel?>? activeSessionPrefetch;

  @override
  State<GuestPracticeSessionPage> createState() =>
      _GuestPracticeSessionPageState();
}

class _GuestPracticeSessionPageState extends State<GuestPracticeSessionPage> {
  late final GuestRepository _repository;

  PracticeSessionModel? _session;
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
    _repository = getIt<GuestRepository>();
    _showTimer = widget.showElapsedTimer;
    _initializeSession();
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

  Future<void> _initializeSession() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
      _loadingMessage = l10n.practicePreparingSession;
    });

    try {
      final active = await _repository.getActiveSession(
        visitId: widget.visitId,
        token: widget.token,
      );

      if (!mounted) return;

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
        await _repository.abandonSession(
          visitId: widget.visitId,
          token: widget.token,
          sessionId: active.practiceSessionId,
        );
      }

      if (!mounted) return;
      await _start();
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

  Duration get _totalElapsed => _elapsedBaseline + _stopwatch.elapsed;

  void _beginElapsedTimer() {
    if (!_showTimer) return;
    if (!_stopwatch.isRunning) _stopwatch.start();
    _elapsedTicker?.cancel();
    _elapsedTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopElapsedTimer() {
    _elapsedTicker?.cancel();
    _elapsedTicker = null;
    _stopwatch.stop();
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
    _precacheAdjacentQuestions();
  }

  void _precacheAdjacentQuestions() {
    final session = _session;
    if (session == null || !mounted) {
      return;
    }
    PracticeImagePrecacher.precacheAdjacentQuestions(
      context,
      apiBaseUrl: getIt<ApiClient>().dio.options.baseUrl,
      questions: session.questions,
      currentIndex: _currentIndex,
    );
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
      _loadingMessage = l10n.practicePreparingSession;
    });
    try {
      final session = await _repository.startPractice(
        visitId: widget.visitId,
        token: widget.token,
        randomizeQuestions: widget.randomizeQuestions,
        showElapsedTimer: widget.showElapsedTimer,
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

  Future<void> _resumeSession(String sessionId) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
      _loadingMessage = l10n.practicePreparingSession;
    });
    try {
      final session = await _repository.getSession(
        visitId: widget.visitId,
        token: widget.token,
        sessionId: sessionId,
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

  Future<void> _saveProgress() async {
    final session = _session;
    if (session == null || _savingProgress) return;
    await _awaitPendingPersists();
    setState(() => _savingProgress = true);
    try {
      await _repository.updateProgress(
        visitId: widget.visitId,
        token: widget.token,
        sessionId: session.practiceSessionId,
        currentQuestionIndex: _currentIndex,
        elapsedSecondsBeforePause: _totalElapsed.inSeconds,
      );
    } finally {
      if (mounted) setState(() => _savingProgress = false);
    }
  }

  void _hydrateSelections(PracticeQuestionModel question) {
    if (question.selectedAnswerOptionIds.isEmpty) return;
    _pendingSelections[question.practiceQuestionSnapshotId] =
        question.selectedAnswerOptionIds.toSet();
  }

  void _goToQuestion(int index) {
    final session = _session;
    if (session == null || index < 0 || index >= session.questions.length) {
      return;
    }
    setState(() {
      _currentIndex = index;
      _hydrateSelections(session.questions[index]);
    });
    _precacheAdjacentQuestions();
  }

  Set<String> _selectionFor(PracticeQuestionModel question) {
    return _pendingSelections.putIfAbsent(
      question.practiceQuestionSnapshotId,
      () => {},
    );
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

  bool _isSingleSelect(String questionType) {
    return questionType == 'single_choice' ||
        questionType == 'true_false' ||
        questionType == 'image_choice' ||
        questionType == 'image_based_question';
  }

  List<PracticeQuestionNavStatus> _navStatuses() {
    return _session!.questions.map((q) {
      return _isQuestionDone(q)
          ? PracticeQuestionNavStatus.answered
          : PracticeQuestionNavStatus.pending;
    }).toList();
  }

  Future<void> _persistSelection(PracticeQuestionModel question) async {
    final session = _session;
    if (session == null) return;

    final questionId = question.practiceQuestionSnapshotId;
    final selected = _selectionFor(question).toList();
    if (selected.isEmpty) {
      if (_statusFor(question) == 'answered') {
        setState(() => _questionStatuses[questionId] = 'unanswered');
      }
      return;
    }

    final future = _repository.submitAnswer(
      visitId: widget.visitId,
      token: widget.token,
      sessionId: session.practiceSessionId,
      snapshotId: questionId,
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

  void _toggleSingleOption(PracticeQuestionModel question, String optionId) {
    final questionId = question.practiceQuestionSnapshotId;
    setState(() {
      _selectionFor(question)
        ..clear()
        ..add(optionId);
      _questionStatuses[questionId] = 'answered';
    });
    _schedulePersistSelection(question);
  }

  void _toggleMultiOption(
      PracticeQuestionModel question, String optionId, bool wasSelected) {
    final questionId = question.practiceQuestionSnapshotId;
    setState(() {
      final set = _selectionFor(question);
      if (wasSelected) {
        set.remove(optionId);
      } else {
        set.add(optionId);
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
    if (session == null) return;

    setState(() => _finishing = true);
    try {
      await _awaitPendingPersists();
      _stopElapsedTimer();
      final result = await _repository.finishSession(
        visitId: widget.visitId,
        token: widget.token,
        sessionId: session.practiceSessionId,
      );
      if (!mounted) return;
      final guestCubit = context.read<GuestSessionCubit>();
      final elapsed = _showTimer ? _totalElapsed : null;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BlocProvider.value(
            value: guestCubit,
            child: GuestResultPage(
              result: result,
              quizTitle: widget.quizTitle,
              guestVisitId: widget.visitId,
              guestToken: widget.token,
              elapsed: elapsed,
            ),
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _finishing = false);
      context.showDioErrorSnackBar(e);
    }
  }

  Future<bool> _confirmExit(BuildContext context, AppLocalizations l10n) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.guestExitPracticeTitle),
        content: Text(l10n.guestExitPracticeMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.guestExitPracticeConfirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String? _resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    final base =
        getIt<ApiClient>().dio.options.baseUrl.replaceAll(RegExp(r'/$'), '');
    final path = url.startsWith('/') ? url : '/$url';
    return '$base$path';
  }

  Widget? _buildBottomBar(AppLocalizations l10n) {
    final session = _session;
    if (session == null || session.questions.isEmpty) return null;

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

  PracticeQuestionModel? get _currentQuestion {
    final session = _session;
    if (session == null || session.questions.isEmpty) return null;
    if (_currentIndex >= session.questions.length) return null;
    return session.questions[_currentIndex];
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
        final should = await _confirmExit(context, l10n);
        if (should && mounted) {
          _stopElapsedTimer();
          await _awaitPendingPersists();
          await _saveProgress();
          if (mounted) Navigator.of(context).pop();
        }
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
          ],
        ),
        bottomBar: _buildBottomBar(l10n),
        body: _loading
            ? AppLoadingView(message: _loadingMessage)
            : _error != null
                ? AppErrorView(
                    message: _error!,
                    retryLabel: l10n.retry,
                    onRetry: _initializeSession,
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
                                  horizontal: AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    question.questionText,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  if (_resolveMediaUrl(
                                          question.questionMediaUrl) !=
                                      null) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    AppZoomableNetworkImage(
                                      imageUrl: _resolveMediaUrl(
                                          question.questionMediaUrl)!,
                                      height: AppMediaDisplay.questionImageHeight,
                                      borderRadius: BorderRadius.circular(
                                          AppColors.radiusSm),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.lg),
                                  Column(
                                    children: question.answers.map((option) {
                                        final selected =
                                            _selectionFor(question).contains(
                                                option.answerOptionId);
                                        final text = option.text?.trim();
                                        final label = text != null &&
                                                text.isNotEmpty
                                            ? '${option.displayLabel}. $text'
                                            : option.displayLabel;
                                        final imageUrl = _resolveMediaUrl(
                                            option.mediaUrl);

                                        if (_isSingleSelect(
                                            question.questionType)) {
                                          return AppAnswerTile(
                                            label: label,
                                            selected: selected,
                                            mediaImageUrl: imageUrl,
                                            onTap: () => _toggleSingleOption(
                                                question, option.answerOptionId),
                                          );
                                        }
                                        return AppAnswerTile(
                                          label: label,
                                          selected: selected,
                                          mediaImageUrl: imageUrl,
                                          onTap: () => _toggleMultiOption(
                                              question,
                                              option.answerOptionId,
                                              selected),
                                        );
                                      }).toList(),
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
}
