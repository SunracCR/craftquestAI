import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/utils/publication_status_labels.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/quizzes/data/models/quiz_models.dart';
import 'package:craftquest_app/features/quizzes/data/quiz_repository.dart';
import 'package:craftquest_app/features/ai_generation/presentation/ai_generation_hub_page.dart';
import 'package:craftquest_app/features/imports/data/models/import_models.dart';
import 'package:craftquest_app/features/imports/presentation/excel_import_page.dart';
import 'package:craftquest_app/features/imports/presentation/import_preview_page.dart';
import 'package:craftquest_app/features/imports/presentation/import_questions_page.dart';
import 'package:craftquest_app/features/analytics/presentation/quiz_analytics_page.dart';
import 'package:craftquest_app/features/practice/presentation/my_practice_attempts_page.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_attempts_page.dart';
import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:craftquest_app/features/practice/data/practice_preferences_repository.dart';
import 'package:craftquest_app/features/practice/data/practice_repository.dart';
import 'package:craftquest_app/features/practice/presentation/practice_navigation.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_launch_options_card.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/sharing/data/sharing_repository.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/sharing/presentation/invite_quiz_users_sheet.dart';
import 'package:craftquest_app/features/sharing/presentation/create_share_code_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_questions_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class QuizDetailPage extends StatefulWidget {
  const QuizDetailPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
    this.publicationStatus = 'draft',
    this.isOwner = true,
  });

  final String quizId;
  final String quizTitle;
  final String publicationStatus;
  final bool isOwner;

  @override
  State<QuizDetailPage> createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends State<QuizDetailPage> {
  final _repository = getIt<QuizRepository>();
  final _sharingRepository = getIt<SharingRepository>();
  final _billingRepository = getIt<BillingRepository>();
  final _practiceRepository = getIt<PracticeRepository>();
  final _preferencesRepository = getIt<PracticePreferencesRepository>();
  int _questionCount = 0;
  String? _pendingReviewImportId;
  int? _pendingReviewValidQuestions;
  bool _loading = true;
  bool _loadingPreferences = false;
  String? _error;
  String _publicationStatus = 'draft';
  bool _randomizeQuestions = false;
  bool _showTimer = true;
  late String _quizTitle;
  late final TextEditingController _titleController;
  late final FocusNode _titleFocusNode;
  bool _isEditingTitle = false;
  bool _savingTitle = false;
  PracticeActiveSessionModel? _activePractice;
  bool _canInviteDirect = false;

  @override
  void initState() {
    super.initState();
    _quizTitle = widget.quizTitle;
    _titleController = TextEditingController(text: _quizTitle);
    _titleFocusNode = FocusNode();
    _titleFocusNode.addListener(_onTitleFocusChange);
    _publicationStatus = widget.publicationStatus;
    _refreshQuestionCount();
    _loadPracticePreferences();
    _loadActivePractice();
    if (widget.isOwner) {
      _loadInviteEligibility();
    }
  }

  @override
  void dispose() {
    _titleFocusNode.removeListener(_onTitleFocusChange);
    _titleFocusNode.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _onTitleFocusChange() {
    if (!_titleFocusNode.hasFocus && _isEditingTitle) {
      _commitTitleEdit();
    }
  }

  Future<void> _commitTitleEdit() async {
    final trimmed = _titleController.text.trim();
    if (trimmed.isEmpty) {
      _titleController.text = _quizTitle;
      setState(() => _isEditingTitle = false);
      return;
    }

    if (trimmed == _quizTitle) {
      setState(() => _isEditingTitle = false);
      return;
    }

    setState(() {
      _isEditingTitle = false;
      _savingTitle = true;
    });

    try {
      final updated = await _repository.updateQuiz(
        quizId: widget.quizId,
        title: trimmed,
      );
      if (!mounted) return;
      setState(() {
        _quizTitle = updated.title;
        _titleController.text = updated.title;
        _savingTitle = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      _titleController.text = _quizTitle;
      setState(() => _savingTitle = false);
      context.showDioErrorSnackBar(e);
    }
  }

  void _startEditingTitle() {
    if (!widget.isOwner) return;
    setState(() => _isEditingTitle = true);
    _titleController.text = _quizTitle;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _titleFocusNode.requestFocus();
      _titleController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _titleController.text.length,
      );
    });
  }

  Widget _buildEditableTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        );

    if (_isEditingTitle) {
      return TextField(
        controller: _titleController,
        focusNode: _titleFocusNode,
        style: titleStyle,
        maxLength: 220,
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          counterText: '',
        ),
        onSubmitted: (_) => _commitTitleEdit(),
      );
    }

    if (!widget.isOwner) {
      return Text(
        _quizTitle,
        style: titleStyle,
      );
    }

    return Tooltip(
      message: l10n.quizTitleTapToEdit,
      child: InkWell(
        onTap: _savingTitle ? null : _startEditingTitle,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _quizTitle,
                  style: titleStyle,
                ),
              ),
              if (_savingTitle)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.edit_rounded,
                  size: 20,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadPracticePreferences() async {
    setState(() => _loadingPreferences = true);
    try {
      final prefs =
          await _preferencesRepository.getPreferences(widget.quizId);
      if (!mounted) return;
      setState(() {
        _randomizeQuestions = prefs.randomizeQuestions;
        _showTimer = prefs.showElapsedTimer;
        _loadingPreferences = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPreferences = false);
    }
  }

  Future<void> _persistPracticePreferences() async {
    try {
      await _preferencesRepository.savePreferences(
        quizId: widget.quizId,
        randomizeQuestions: _randomizeQuestions,
        showElapsedTimer: _showTimer,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    }
  }

  void _updateRandomizeQuestions(bool value) {
    setState(() => _randomizeQuestions = value);
    _persistPracticePreferences();
  }

  void _updateShowTimer(bool value) {
    setState(() => _showTimer = value);
    _persistPracticePreferences();
  }

  Future<void> _openPendingAiImport() async {
    final importId = _pendingReviewImportId;
    if (importId == null) return;

    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ImportPreviewPage(
          importId: importId,
          quizTitle: _quizTitle,
          initialStatus: ImportStatusModel(
            importId: importId,
            status: 'ready_for_review',
            totalQuestionsDetected: _pendingReviewValidQuestions ?? 0,
            validQuestions: _pendingReviewValidQuestions ?? 0,
            questionsWithWarnings: 0,
            questionsWithErrors: 0,
          ),
          fromAiGeneration: true,
        ),
      ),
    );

    if (!mounted) return;
    await _refreshQuestionCount();
    if (confirmed == true && mounted) {
      final l10n = AppLocalizations.of(context)!;
      context.showSuccessSnackBar(l10n.importConfirmSuccess(_questionCount));
    }
  }

  Future<void> _refreshQuestionCount({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final QuizModel quiz = await _repository.getQuiz(widget.quizId);
      if (!mounted) return;
      if (widget.isOwner) {
        final questions = await _repository.getQuestions(widget.quizId);
        if (!mounted) return;
        setState(() {
          _questionCount = questions.length;
          _publicationStatus = quiz.publicationStatus;
          _pendingReviewImportId = quiz.pendingReviewImportId;
          _pendingReviewValidQuestions = quiz.pendingReviewValidQuestions;
          if (showLoading) {
            _loading = false;
          }
        });
      } else {
        setState(() {
          _questionCount = quiz.questionCount;
          _publicationStatus = quiz.publicationStatus;
          _pendingReviewImportId = null;
          _pendingReviewValidQuestions = null;
          if (showLoading) {
            _loading = false;
          }
        });
      }
      await _syncPracticeUiIfNeeded();
    } on DioException catch (e) {
      if (!mounted) return;
      if (showLoading) {
        setState(() {
          _error = DioErrorMapper.map(e);
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      if (showLoading) {
        setState(() {
          _error = DioErrorMapper.genericMessage();
          _loading = false;
        });
      }
    }
  }

  Future<void> _syncPracticeUiIfNeeded() async {
    if (!_canPractice) {
      if (_activePractice != null && mounted) {
        setState(() => _activePractice = null);
      }
      return;
    }
    await Future.wait([
      _loadPracticePreferences(),
      _loadActivePractice(),
    ]);
  }

  Future<void> _loadActivePractice() async {
    if (!_canPractice) {
      if (mounted && _activePractice != null) {
        setState(() => _activePractice = null);
      }
      return;
    }
    try {
      final active =
          await _practiceRepository.getActiveSessionForQuiz(widget.quizId);
      if (!mounted) return;
      setState(() => _activePractice = active);
    } catch (_) {
      // Ignore; practice can still be started.
    }
  }

  bool get _canPractice =>
      _publicationStatus == 'published' && _questionCount > 0;

  bool get _canPublish => _publicationStatus != 'published';

  bool get _canCreateShareCode => _publicationStatus == 'published';

  Future<void> _loadInviteEligibility() async {
    try {
      final billing = await _billingRepository.getMyBilling();
      if (!mounted) return;
      setState(() {
        _canInviteDirect = billing.entitlements.canInviteUsersDirectly;
      });
    } catch (_) {
      // Non-blocking: invite button stays hidden.
    }
  }

  Future<void> _inviteUsersDirectly() async {
    await InviteQuizUsersSheet.show(context, quizId: widget.quizId);
  }

  Future<void> _viewQuestions() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => QuizQuestionsPage(
          quizId: widget.quizId,
          quizTitle: _quizTitle,
        ),
      ),
    );
    if (!mounted) return;
    await _refreshQuestionCount(showLoading: false);
  }

  Future<void> _viewAnalytics() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizAnalyticsPage(
          quizId: widget.quizId,
          quizTitle: _quizTitle,
          personalMode: !widget.isOwner,
        ),
      ),
    );
  }

  Future<void> _viewAttempts() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.isOwner
            ? TeacherAttemptsPage(
                quizId: widget.quizId,
                quizTitle: _quizTitle,
              )
            : MyPracticeAttemptsPage(
                quizId: widget.quizId,
                quizTitle: _quizTitle,
              ),
      ),
    );
  }

  Future<void> _importQuestions() async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_awesome_rounded),
              title: Text(l10n.aiGenerationFromQuizAction),
              onTap: () => Navigator.pop(ctx, 'ai'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(l10n.importExcelAction),
              onTap: () => Navigator.pop(ctx, 'excel'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.importQuestionsTitle),
              subtitle: Text('${l10n.importFormatJson} / ${l10n.importFormatTxt}'),
              onTap: () => Navigator.pop(ctx, 'text'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;

    if (choice == 'ai') {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => AiGenerationHubPage(
            targetQuizId: widget.quizId,
            targetQuizTitle: _quizTitle,
          ),
        ),
      );
    } else {
      final page = choice == 'excel'
          ? ExcelImportPage(quizId: widget.quizId, quizTitle: _quizTitle)
          : ImportQuestionsPage(quizId: widget.quizId, quizTitle: _quizTitle);

      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => page),
      );
    }
    if (!mounted) return;
    await _refreshQuestionCount(showLoading: false);
  }

  Future<void> _createShareCode() async {
    final authState = context.read<AuthBloc>().state;
    final isTeacher = authState is AuthAuthenticated &&
        authState.user.roles.contains('teacher');

    final existing = await _sharingRepository.getQuizShareCode(widget.quizId);
    if (!mounted) return;

    if (existing != null) {
      await showShareCodeResultDialog(context, existing);
      return;
    }

    final shareCode = await CreateShareCodeSheet.show(
      context,
      quizId: widget.quizId,
      isTeacher: isTeacher,
    );
    if (!mounted || shareCode == null) return;
    await showShareCodeResultDialog(context, shareCode);
  }

  Future<void> _continuePractice() async {
    await openPracticeSession(
      context,
      quizId: widget.quizId,
      quizTitle: _quizTitle,
      resumeSessionId: _activePractice?.practiceSessionId,
    );
    if (!mounted) return;
    await _loadActivePractice();
  }

  Future<void> _startPractice() async {
    await openPracticeSession(
      context,
      quizId: widget.quizId,
      quizTitle: _quizTitle,
    );
    if (!mounted) return;
    await _loadActivePractice();
  }

  Future<void> _restartPractice() async {
    final active = _activePractice;
    if (active == null) return;

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.practiceStartNewAction),
        content: Text(
          l10n.practiceResumeMessage(
            active.answeredCount,
            active.totalQuestions,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.practiceStartNewAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _practiceRepository.abandonSession(active.practiceSessionId);
      if (!mounted) return;
      setState(() => _activePractice = null);
      await _startPractice();
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    }
  }

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _repository.publishQuiz(widget.quizId);
      if (!mounted) return;
      setState(() => _publicationStatus = 'published');
      await _syncPracticeUiIfNeeded();
      if (!mounted) return;
      context.showSuccessSnackBar(l10n.quizPublishedMessage);
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    }
  }

  Future<void> _confirmRemoveFromShared() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accessibleQuizzesRemoveConfirmTitle),
        content: Text(l10n.accessibleQuizzesRemoveConfirmMessage(_quizTitle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.accessibleQuizzesRemoveAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _sharingRepository.removeAccessibleQuiz(widget.quizId);
      if (!mounted) return;
      context.showSuccessSnackBar(l10n.accessibleQuizzesRemovedMessage);
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    }
  }

  Future<void> _confirmDeleteQuiz() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteQuizConfirmTitle),
        content: Text(
          l10n.deleteQuizConfirmMessage(_quizTitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteQuizAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _repository.deleteQuiz(widget.quizId);
      if (!mounted) return;
      context.showSuccessSnackBar(l10n.quizDeletedMessage);
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    }
  }

  Widget? _buildBottomBar(AppLocalizations l10n) {
    if (_loading || !_canPractice) return null;

    final hasActivePractice = _activePractice != null;

    if (!hasActivePractice) {
      return AppBottomActionBar(
        children: [
          AppGradientPrimaryButton(
            label: l10n.practiceQuizAction,
            icon: Icons.play_arrow_rounded,
            onPressed: _startPractice,
          ),
        ],
      );
    }

    return AppBottomActionBar(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppGradientPrimaryButton(
                label: l10n.practiceContinueAction,
                icon: Icons.play_circle_outline_rounded,
                onPressed: _continuePractice,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppSecondaryButton(
                label: l10n.practiceStartNewAction,
                icon: Icons.refresh_rounded,
                accentColor: AppColors.accentViolet,
                onPressed: _restartPractice,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _menuDivider() => Divider(
        height: 1,
        indent: AppSpacing.md,
        endIndent: AppSpacing.md,
        color: AppColors.textSecondary.withValues(alpha: 0.12),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = AppColors.publicationStatusColor(_publicationStatus);
    final statusLabel = _publicationStatus.publicationStatusLabel(l10n);

    final hasPendingAiDraft = widget.isOwner && _pendingReviewImportId != null;
    final isOwner = widget.isOwner;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(
        title: l10n.quizDetailTitle,
        actions: [
          if (hasPendingAiDraft)
            IconButton(
              onPressed: _openPendingAiImport,
              tooltip: l10n.quizDetailImportAiDraftAction,
              icon: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.accentViolet.withValues(alpha: 0.95),
              ),
            ),
        ],
      ),
      bottomBar: _buildBottomBar(l10n),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _refreshQuestionCount,
                )
              : RefreshIndicator(
                  onRefresh: _refreshQuestionCount,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accent.withValues(alpha: 0.12),
                            AppColors.accentCool.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.xl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildEditableTitle(context),
                                ),
                                if (isOwner) ...[
                                  Tooltip(
                                    message: l10n.publishQuizAction,
                                    child: IconButton(
                                      onPressed: () {
                                        if (_canPublish) _publish();
                                      },
                                      icon: Icon(
                                        Icons.publish_rounded,
                                        color: _canPublish
                                            ? AppColors.accentMint
                                            : Theme.of(context).disabledColor,
                                      ),
                                    ),
                                  ),
                                  Tooltip(
                                    message: l10n.createShareCodeAction,
                                    child: IconButton(
                                      onPressed: () {
                                        if (_canCreateShareCode) {
                                          _createShareCode();
                                        }
                                      },
                                      icon: Icon(
                                        Icons.vpn_key_rounded,
                                        color: _canCreateShareCode
                                            ? AppColors.accentViolet
                                            : Theme.of(context).disabledColor,
                                      ),
                                    ),
                                  ),
                                  if (_canInviteDirect)
                                    Tooltip(
                                      message: l10n.quizInviteAction,
                                      child: IconButton(
                                        onPressed: () {
                                          if (_canCreateShareCode) {
                                            _inviteUsersDirectly();
                                          }
                                        },
                                        icon: Icon(
                                          Icons.person_add_alt_1_rounded,
                                          color: _canCreateShareCode
                                              ? AppColors.accentSky
                                              : Theme.of(context).disabledColor,
                                        ),
                                      ),
                                    ),
                                  Tooltip(
                                    message: l10n.deleteQuizAction,
                                    child: IconButton(
                                      onPressed: _confirmDeleteQuiz,
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                AppStatusChip(
                                  label: statusLabel,
                                  color: statusColor,
                                ),
                                if (hasPendingAiDraft) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  AppStatusChip(
                                    label: l10n.aiActivityStatusDraftReady,
                                    color: AppColors.accentViolet,
                                  ),
                                ],
                                if (_activePractice != null) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  AppStatusChip(
                                    label: l10n.practiceInProgressChip,
                                    color: AppColors.accent,
                                  ),
                                ],
                              ],
                            ),
                            if (_activePractice != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                l10n.practiceInProgressSubtitle(
                                  _activePractice!.answeredCount,
                                  _activePractice!.totalQuestions,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.accent),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.quizListSubtitle(
                                statusLabel,
                                _questionCount,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            if (hasPendingAiDraft) ...[
                              const SizedBox(height: AppSpacing.md),
                              Material(
                                color: AppColors.accentViolet.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusMd),
                                child: InkWell(
                                  onTap: _openPendingAiImport,
                                  borderRadius:
                                      BorderRadius.circular(AppColors.radiusMd),
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.auto_awesome_rounded,
                                          color: AppColors.accentViolet
                                              .withValues(alpha: 0.95),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            l10n.quizDetailImportAiDraftBanner(
                                              _pendingReviewValidQuestions ??
                                                  _questionCount,
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppColors.textSecondary
                                              .withValues(alpha: 0.8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            AppSectionCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  AppActionTile(
                                    icon: Icons.analytics_rounded,
                                    label: isOwner
                                        ? l10n.quizAnalyticsAction
                                        : l10n.myQuizAnalyticsAction,
                                    iconColor: AppColors.accentCool,
                                    iconBackgroundColor: AppColors.accentCool
                                        .withValues(alpha: 0.2),
                                    onTap: _viewAnalytics,
                                  ),
                                  _menuDivider(),
                                  AppActionTile(
                                    icon: Icons.fact_check_rounded,
                                    label: isOwner
                                        ? l10n.teacherAttemptsAction
                                        : l10n.myPracticeAttemptsAction,
                                    iconColor: AppColors.accentSky,
                                    iconBackgroundColor: AppColors.accentSky
                                        .withValues(alpha: 0.2),
                                    onTap: _viewAttempts,
                                  ),
                                  if (!isOwner) ...[
                                    _menuDivider(),
                                    AppActionTile(
                                      icon: Icons.link_off_rounded,
                                      label: l10n.accessibleQuizzesRemoveAction,
                                      iconColor: AppColors.error,
                                      iconBackgroundColor: AppColors.error
                                          .withValues(alpha: 0.15),
                                      onTap: _confirmRemoveFromShared,
                                    ),
                                  ],
                                  if (isOwner) ...[
                                    _menuDivider(),
                                    AppActionTile(
                                      icon: Icons.upload_file_rounded,
                                      label: l10n.importQuestionsAction,
                                      iconColor: AppColors.accentGold,
                                      iconBackgroundColor: AppColors.accentGold
                                          .withValues(alpha: 0.22),
                                      onTap: _importQuestions,
                                    ),
                                    _menuDivider(),
                                    AppActionTile(
                                      icon: Icons.quiz_rounded,
                                      label: l10n.viewQuizQuestionsAction,
                                      iconColor: AppColors.accent,
                                      iconBackgroundColor: AppColors.accent
                                          .withValues(alpha: 0.2),
                                      onTap: _viewQuestions,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (_canPractice) ...[
                              const SizedBox(height: AppSpacing.lg),
                              _loadingPreferences
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: AppSpacing.md,
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    )
                                  : PracticeLaunchOptionsCard(
                                      randomizeQuestions: _randomizeQuestions,
                                      showTimer: _showTimer,
                                      onRandomizeQuestionsChanged:
                                          _updateRandomizeQuestions,
                                      onShowTimerChanged: _updateShowTimer,
                                    ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
