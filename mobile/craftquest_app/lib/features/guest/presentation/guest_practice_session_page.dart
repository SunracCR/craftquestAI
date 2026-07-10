import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/utils/deferred_screen_load.dart';
import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/services/sound_service.dart';
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
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_nav_header.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_nav_status.dart';
import 'package:craftquest_app/features/practice/presentation/practice_session_feedback.dart';
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
    this.enableSoundEffects = true,
    this.activeSessionPrefetch,
  });

  final String visitId;
  final String token;
  final String quizTitle;
  final bool? randomizeQuestions;
  final bool showElapsedTimer;
  final bool enableSoundEffects;
  final Future<PracticeActiveSessionModel?>? activeSessionPrefetch;

  @override
  State<GuestPracticeSessionPage> createState() =>
      _GuestPracticeSessionPageState();
}

class _GuestPracticeSessionPageState extends State<GuestPracticeSessionPage>
    with ScreenLoadGeneration {
  late final GuestRepository _repository;
  final _soundService = getIt<SoundService>();
  late final PracticeSessionFeedback _feedback;

  PracticeSessionModel? _session;
  List<PracticeQuestionNavModel> _questionNav = [];
  final Map<String, PracticeQuestionModel> _questionCache = {};
  final Map<String, String> _questionStatuses = {};
  final Map<String, Set<String>> _pendingSelections = {};
  int _currentIndex = 0;
  bool _loading = true;
  bool _loadingQuestion = false;
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
    _feedback = PracticeSessionFeedback(
      _soundService,
      enabled: widget.enableSoundEffects,
    );
    _repository = getIt<GuestRepository>();
    _showTimer = widget.showElapsedTimer;
    scheduleInitialScreenLoad(_initializeSession);
  }

  @override
  void dispose() {
    _elapsedTicker?.cancel();
    for (final timer in _persistDebounceTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<PracticeActiveSessionModel?> _resolveActiveSession() {
    final prefetch = widget.activeSessionPrefetch;
    if (prefetch != null) {
      return prefetch;
    }
    return _repository.getActiveSession(
      visitId: widget.visitId,
      token: widget.token,
    );
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
    final loadId = beginScreenLoad();
    final l10n = AppLocalizations.of(context)!;
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _loadingMessage = l10n.practicePreparingSession;
    });

    try {
      final active = await _resolveActiveSession();

      if (!mounted || isStaleScreenLoad(loadId)) return;

      if (active != null) {
        final choice = await showPracticeResumeDialog(
          context,
          summary: active,
        );
        if (!mounted || isStaleScreenLoad(loadId)) return;
        if (choice == null || choice == PracticeResumeChoice.cancel) {
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
        if (!mounted || isStaleScreenLoad(loadId)) return;
      }

      await _start(loadId: loadId);
    } on DioException catch (e) {
      if (!mounted || isStaleScreenLoad(loadId)) return;
      setState(() {
        _error = DioErrorMapper.map(e);
        _loading = false;
        _loadingMessage = null;
      });
    } catch (_) {
      if (!mounted || isStaleScreenLoad(loadId)) return;
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
    _questionCache.clear();

    _questionNav = session.questionNav.isNotEmpty
        ? session.questionNav
        : session.questions
            .map(
              (q) => PracticeQuestionNavModel(
                practiceQuestionSnapshotId: q.practiceQuestionSnapshotId,
                questionId: q.questionId,
                displayOrder: q.displayOrder,
                answerStatus: q.answerStatus,
              ),
            )
            .toList();

    for (final nav in _questionNav) {
      _questionStatuses[nav.practiceQuestionSnapshotId] = nav.answerStatus;
    }
    for (final q in session.questions) {
      _questionCache[q.practiceQuestionSnapshotId] = q;
      _questionStatuses[q.practiceQuestionSnapshotId] = q.answerStatus;
      _hydrateSelections(q);
    }

    final total = session.totalQuestions > 0
        ? session.totalQuestions
        : _questionNav.length;
    final index = session.currentQuestionIndex.clamp(
      0,
      total == 0 ? 0 : total - 1,
    );
    _showTimer = session.showElapsedTimer;
    _elapsedBaseline = Duration(seconds: session.elapsedSecondsBeforePause);
    _currentIndex = index;
    _session = session;
    _precacheAdjacentQuestions();
    unawaited(_prefetchQuestionAt(index + 1));
  }

  int get _totalQuestions {
    if (_questionNav.isNotEmpty) {
      return _questionNav.length;
    }
    return _session?.totalQuestions ?? 0;
  }

  Future<void> _prefetchQuestionAt(int index) async {
    if (index < 0 || index >= _totalQuestions) {
      return;
    }
    final nav = _questionNav[index];
    if (_questionCache.containsKey(nav.practiceQuestionSnapshotId)) {
      return;
    }
    final session = _session;
    if (session == null) {
      return;
    }
    try {
      final question = await _repository.getSessionQuestion(
        visitId: widget.visitId,
        token: widget.token,
        sessionId: session.practiceSessionId,
        practiceQuestionSnapshotId: nav.practiceQuestionSnapshotId,
      );
      if (!mounted) {
        return;
      }
      _questionCache[question.practiceQuestionSnapshotId] = question;
    } catch (_) {
      // Best effort prefetch.
    }
  }

  Future<void> _ensureQuestionAt(int index) async {
    if (index < 0 || index >= _totalQuestions) {
      return;
    }
    final nav = _questionNav[index];
    if (_questionCache.containsKey(nav.practiceQuestionSnapshotId)) {
      return;
    }
    final session = _session;
    if (session == null) {
      return;
    }

    setState(() => _loadingQuestion = true);
    try {
      final question = await _repository.getSessionQuestion(
        visitId: widget.visitId,
        token: widget.token,
        sessionId: session.practiceSessionId,
        practiceQuestionSnapshotId: nav.practiceQuestionSnapshotId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _questionCache[question.practiceQuestionSnapshotId] = question;
        _hydrateSelections(question);
        _loadingQuestion = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingQuestion = false);
      rethrow;
    }
  }

  void _precacheAdjacentQuestions() {
    final session = _session;
    if (session == null || !mounted) {
      return;
    }
    final cachedQuestions = _questionCache.values.toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    if (cachedQuestions.isEmpty) {
      return;
    }
    var adjacentIndex = _currentIndex;
    if (_questionNav.isNotEmpty) {
      final currentId = _questionNav[_currentIndex].practiceQuestionSnapshotId;
      adjacentIndex = cachedQuestions.indexWhere(
        (q) => q.practiceQuestionSnapshotId == currentId,
      );
      if (adjacentIndex < 0) {
        adjacentIndex = 0;
      }
    }
    PracticeImagePrecacher.precacheAdjacentQuestions(
      context,
      apiBaseUrl: getIt<ApiClient>().dio.options.baseUrl,
      questions: cachedQuestions,
      currentIndex: adjacentIndex,
    );
    unawaited(_prefetchQuestionAt(_currentIndex + 1));
    unawaited(_prefetchQuestionAt(_currentIndex - 1));
  }

  Future<void> _start({int? loadId}) async {
    final id = loadId ?? beginScreenLoad();
    final l10n = AppLocalizations.of(context)!;
    if (!mounted) return;
    setState(() {
      if (loadId == null) {
        _loading = true;
      }
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
      if (!mounted || isStaleScreenLoad(id)) return;
      setState(() {
        _applySession(session);
        _loading = false;
        _loadingMessage = null;
      });
      await _ensureQuestionAt(_currentIndex);
      if (!mounted || isStaleScreenLoad(id)) return;
      _beginElapsedTimer();
    } on DioException catch (e) {
      if (!mounted || isStaleScreenLoad(id)) return;
      setState(() {
        _error = DioErrorMapper.map(e);
        _loading = false;
        _loadingMessage = null;
      });
    } catch (_) {
      if (!mounted || isStaleScreenLoad(id)) return;
      setState(() {
        _error = DioErrorMapper.genericMessage();
        _loading = false;
        _loadingMessage = null;
      });
    }
  }

  Future<void> _resumeSession(String sessionId) async {
    final loadId = beginScreenLoad();
    final l10n = AppLocalizations.of(context)!;
    if (!mounted) return;
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
      if (!mounted || isStaleScreenLoad(loadId)) return;
      setState(() {
        _applySession(session);
        _loading = false;
        _loadingMessage = null;
      });
      await _ensureQuestionAt(_currentIndex);
      if (!mounted || isStaleScreenLoad(loadId)) return;
      _beginElapsedTimer();
    } on DioException catch (e) {
      if (!mounted || isStaleScreenLoad(loadId)) return;
      setState(() {
        _error = DioErrorMapper.map(e);
        _loading = false;
        _loadingMessage = null;
      });
    } catch (_) {
      if (!mounted || isStaleScreenLoad(loadId)) return;
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

  void _goToQuestion(int index) async {
    if (index < 0 || index >= _totalQuestions) {
      return;
    }
    try {
      await _ensureQuestionAt(index);
      if (!mounted) {
        return;
      }
      setState(() {
        _currentIndex = index;
        final question = _currentQuestion;
        if (question != null) {
          _hydrateSelections(question);
        }
      });
      _precacheAdjacentQuestions();
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      context.showDioErrorSnackBar(e);
    }
  }

  Set<String> _selectionFor(PracticeQuestionModel question) {
    return _pendingSelections.putIfAbsent(
      question.practiceQuestionSnapshotId,
      () => {},
    );
  }

  String _statusFor(PracticeQuestionModel question) =>
      _questionStatuses[question.practiceQuestionSnapshotId] ?? 'unanswered';

  String _statusForSnapshot(String snapshotId) =>
      _questionStatuses[snapshotId] ?? 'unanswered';

  bool _isNavItemDone(PracticeQuestionNavModel nav) {
    if (_statusForSnapshot(nav.practiceQuestionSnapshotId) == 'answered') {
      return true;
    }
    final cached = _questionCache[nav.practiceQuestionSnapshotId];
    if (cached != null && _selectionFor(cached).isNotEmpty) {
      return true;
    }
    return false;
  }

  int get _completedCount {
    if (_questionNav.isEmpty) {
      return 0;
    }
    return _questionNav.where(_isNavItemDone).length;
  }

  bool get _allCompleted =>
      _completedCount >= _totalQuestions && _totalQuestions > 0;

  bool _isSingleSelect(String questionType) {
    return questionType == 'single_choice' ||
        questionType == 'true_false' ||
        questionType == 'image_choice' ||
        questionType == 'image_based_question';
  }

  List<PracticeQuestionNavStatus> _navStatuses() {
    return _questionNav.map((nav) {
      return _isNavItemDone(nav)
          ? PracticeQuestionNavStatus.answered
          : PracticeQuestionNavStatus.pending;
    }).toList();
  }

  Future<void> _persistSelection(PracticeQuestionModel question) async {
    final session = _session;
    if (session == null) return;

    final questionId = question.practiceQuestionSnapshotId;
    final previous = _persistInFlight.remove(questionId);
    if (previous != null) {
      await previous.catchError((_) {});
    }
    if (!mounted || _session == null) return;

    final selected = _selectionFor(question).toList();
    if (selected.isEmpty) {
      if (_statusFor(question) == 'answered') {
        setState(() => _questionStatuses[questionId] = 'unanswered');
      }
      return;
    }

    late final Future<void> persistFuture;
    persistFuture = _repository
        .submitAnswer(
          visitId: widget.visitId,
          token: widget.token,
          sessionId: session.practiceSessionId,
          snapshotId: questionId,
          selectedAnswerOptionIds: selected,
        )
        .then((_) async {
          if (!mounted) return;
          setState(() => _questionStatuses[questionId] = 'answered');
        })
        .catchError((Object error) {
          if (!mounted) return;
          if (error is DioException) {
            context.showDioErrorSnackBar(error);
          }
          setState(() {
            _questionStatuses.remove(questionId);
          });
        })
        .whenComplete(() {
          if (identical(_persistInFlight[questionId], persistFuture)) {
            _persistInFlight.remove(questionId);
          }
        });

    _persistInFlight[questionId] = persistFuture;
    await persistFuture;
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
    _feedback.onSelectAnswer();
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
    _feedback.onSelectAnswer();
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

    _feedback.onFinish();

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
      _repository.prefetchAttemptReview(
        visitId: widget.visitId,
        token: widget.token,
        sessionId: result.practiceSessionId,
      );
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
    if (session == null || _totalQuestions == 0) return null;

    final isBusy = _finishing || _loadingQuestion;

    return PracticeSessionBottomBar(
      canGoBack: _currentIndex > 0,
      canGoForward: _currentIndex < _totalQuestions - 1,
      allCompleted: _allCompleted,
      isBusy: isBusy,
      onPrevious: () {
        _feedback.onPreviousQuestion();
        _goToQuestion(_currentIndex - 1);
      },
      onNext: () {
        _feedback.onNextQuestion();
        _goToQuestion(_currentIndex + 1);
      },
      onFinish: _finish,
      l10n: l10n,
    );
  }

  PracticeQuestionModel? get _currentQuestion {
    if (_questionNav.isEmpty || _currentIndex >= _questionNav.length) {
      return null;
    }
    final snapshotId = _questionNav[_currentIndex].practiceQuestionSnapshotId;
    return _questionCache[snapshotId];
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
                : session == null
                    ? AppEmptyView(message: l10n.practiceNoQuestions)
                    : question == null
                        ? AppLoadingView(message: _loadingMessage)
                        : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.sm,
                              AppSpacing.md,
                              AppSpacing.xs,
                            ),
                            child: PracticeQuestionNavHeader(
                              currentIndex: _currentIndex,
                              displayOrder: question.displayOrder,
                              totalQuestions: _totalQuestions,
                              statuses: _navStatuses(),
                              onSelected: _goToQuestion,
                              elapsedTime: _showTimer
                                  ? _formatElapsed(_totalElapsed)
                                  : null,
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
