import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/assignment_dates.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_padded_scroll.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/quizzes/data/models/quiz_models.dart';
import 'package:craftquest_app/features/quizzes/data/quiz_repository.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_content_setup_flow.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_flow_anchor.dart';
import 'package:craftquest_app/features/teacher/presentation/assignment_form_draft.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_assignment_models.dart';
import 'package:craftquest_app/features/teacher/data/teacher_assignment_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class TeacherCreateAssignmentPage extends StatefulWidget {
  const TeacherCreateAssignmentPage({
    super.key,
    required this.classId,
    this.assignmentToEdit,
  });

  final String classId;
  final AssignmentDetailModel? assignmentToEdit;

  bool get isEditMode => assignmentToEdit != null;

  @override
  State<TeacherCreateAssignmentPage> createState() =>
      _TeacherCreateAssignmentPageState();
}

class _TeacherCreateAssignmentPageState
    extends State<TeacherCreateAssignmentPage> {
  final _assignRepo = getIt<TeacherAssignmentRepository>();
  final _quizRepo = getIt<QuizRepository>();
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _maxAttemptsCtrl = TextEditingController();

  String? _selectedQuizId;
  String? _lockedQuizTitle;
  DateTime? _startsAt;
  DateTime? _dueAt;
  String _showAnswersMode = 'after_due_date';
  bool _randomizeQuestions = false;
  bool _allowStudentRandomizeQuestions = false;
  bool _forfeitExitCountsAsAttempt = false;
  bool _loading = false;

  bool get _maxAttemptsApplies {
    final text = _maxAttemptsCtrl.text.trim();
    if (text.isEmpty) return false;
    final value = int.tryParse(text);
    return value != null && value > 0;
  }
  AssignmentFormDraft? _draftSnapshot;
  List<QuizModel> _quizzes = [];
  bool _quizzesLoading = true;

  QuizModel? get _selectedQuiz {
    if (_selectedQuizId == null) return null;
    for (final q in _quizzes) {
      if (q.quizId == _selectedQuizId) return q;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.assignmentToEdit;
    if (existing != null) {
      _titleCtrl.text = existing.title;
      _instructionsCtrl.text = existing.instructions ?? '';
      if (existing.maxAttempts != null) {
        _maxAttemptsCtrl.text = existing.maxAttempts.toString();
      }
      _selectedQuizId = existing.quizId;
      _lockedQuizTitle = existing.quizTitle;
      _startsAt = existing.startsAt;
      _dueAt = existing.dueAt;
      _showAnswersMode = _normalizeShowAnswersMode(existing.showCorrectAnswersMode);
      _randomizeQuestions = existing.randomizeQuestions;
      _allowStudentRandomizeQuestions = existing.allowStudentRandomizeQuestions;
      _forfeitExitCountsAsAttempt = existing.forfeitExitCountsAsAttempt;
      _quizzesLoading = false;
    } else {
      _loadQuizzes();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _instructionsCtrl.dispose();
    _maxAttemptsCtrl.dispose();
    super.dispose();
  }

  String _normalizeShowAnswersMode(String mode) =>
      mode == 'never' ? 'teacher_only' : mode;

  Future<void> _loadQuizzes({String? selectQuizId}) async {
    setState(() => _quizzesLoading = true);
    try {
      final all = await _quizRepo.getMyQuizzes();
      final quizzes = all.toList()
        ..sort((a, b) {
          final pubA = a.publicationStatus == 'published' ? 0 : 1;
          final pubB = b.publicationStatus == 'published' ? 0 : 1;
          if (pubA != pubB) return pubA.compareTo(pubB);
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
      if (mounted) {
        setState(() {
          _quizzes = quizzes;
          _quizzesLoading = false;
          if (selectQuizId != null) _selectedQuizId = selectQuizId;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _quizzesLoading = false);
    }
  }

  void _captureDraftSnapshot() {
    _draftSnapshot = AssignmentFormDraft(
      title: _titleCtrl.text,
      instructions: _instructionsCtrl.text,
      maxAttempts: _maxAttemptsCtrl.text,
      startsAt: _startsAt,
      dueAt: _dueAt,
      showAnswersMode: _showAnswersMode,
      selectedQuizId: _selectedQuizId,
    );
  }

  void _applyDraftSnapshot({String? overrideQuizId}) {
    final draft = _draftSnapshot;
    if (draft == null) return;
    _titleCtrl.text = draft.title;
    _instructionsCtrl.text = draft.instructions;
    _maxAttemptsCtrl.text = draft.maxAttempts;
    _startsAt = draft.startsAt;
    _dueAt = draft.dueAt;
    _showAnswersMode = _normalizeShowAnswersMode(draft.showAnswersMode);
    _selectedQuizId = overrideQuizId ?? draft.selectedQuizId;
  }

  Future<void> _createQuiz() async {
    _captureDraftSnapshot();
    QuizFlowAnchor.mark(context);
    final created = await QuizContentSetupFlow.createQuizWithSetup(context);
    if (!mounted) return;

    _applyDraftSnapshot(overrideQuizId: created?.quizId);
    _draftSnapshot = null;

    if (created != null) {
      await _loadQuizzes(selectQuizId: created.quizId);
      if (mounted) {
        context.showSuccessSnackBar(
          AppLocalizations.of(context)!.teacherAssignmentDraftContinued,
        );
      }
    }
  }

  Future<void> _openQuizPicker() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.myQuizzesAction,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _createQuiz();
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(l10n.createQuizAction),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.teacherAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _quizzes.isEmpty
                      ? Center(
                          child: Padding(
                            padding: AppSpacing.page,
                            child: Text(
                              l10n.teacherAssignmentNoQuizzesHint,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.xl,
                          ),
                          itemCount: _quizzes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (context, index) {
                            final quiz = _quizzes[index];
                            final selected = quiz.quizId == _selectedQuizId;
                            return _QuizPickerTile(
                              quiz: quiz,
                              selected: selected,
                              onTap: () => Navigator.pop(ctx, quiz.quizId),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null && mounted) {
      final quiz = _quizzes.firstWhere((q) => q.quizId == picked);
      setState(() {
        _selectedQuizId = picked;
        _randomizeQuestions = quiz.randomizeQuestions;
      });
    }
  }

  DateTime _pickerInitialDate(DateTime? value, {required int defaultDayOffset}) {
    if (value != null) {
      final d = AssignmentDates.calendarUtc(value);
      return DateTime(d.year, d.month, d.day);
    }
    return DateTime.now().add(Duration(days: defaultDayOffset));
  }

  Future<void> _pickDate(bool isDue) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickerInitialDate(
        isDue ? _dueAt : _startsAt,
        defaultDayOffset: isDue ? 7 : 0,
      ),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.teacherAccent),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final calendar = DateTime.utc(picked.year, picked.month, picked.day);
    setState(() {
      if (isDue) {
        _dueAt = calendar;
      } else {
        _startsAt = calendar;
      }
    });
  }

  void _clearDate(bool isDue) {
    setState(() {
      if (isDue) {
        _dueAt = null;
      } else {
        _startsAt = null;
      }
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (!widget.isEditMode && _selectedQuizId == null) {
      context.showErrorSnackBar(l10n.teacherAssignmentQuizRequiredError);
      return;
    }

    setState(() => _loading = true);
    try {
      final maxAttemptsText = _maxAttemptsCtrl.text.trim();
      final maxAttempts = maxAttemptsText.isNotEmpty
          ? int.tryParse(maxAttemptsText)
          : null;

      if (maxAttemptsText.isNotEmpty && maxAttempts == null) {
        if (mounted) {
          context.showErrorSnackBar(l10n.teacherAssignmentMaxAttemptsInvalidError);
          setState(() => _loading = false);
        }
        return;
      }

      final instructions = _instructionsCtrl.text.trim();

      if (widget.isEditMode) {
        await _assignRepo.updateAssignment(
          assignmentId: widget.assignmentToEdit!.assignmentId,
          title: _titleCtrl.text.trim(),
          instructions: instructions.isEmpty ? null : instructions,
          startsAt: _startsAt,
          dueAt: _dueAt,
          maxAttempts: maxAttempts,
          showCorrectAnswersMode: _showAnswersMode,
          randomizeQuestions: _randomizeQuestions,
          allowStudentRandomizeQuestions: _allowStudentRandomizeQuestions,
          forfeitExitCountsAsAttempt:
              _maxAttemptsApplies && _forfeitExitCountsAsAttempt,
        );
      } else {
        await _assignRepo.createAssignment(
          classId: widget.classId,
          quizId: _selectedQuizId!,
          title: _titleCtrl.text.trim(),
          instructions: instructions.isEmpty ? null : instructions,
          startsAt: _startsAt,
          dueAt: _dueAt,
          maxAttempts: maxAttempts,
          showCorrectAnswersMode: _showAnswersMode,
          randomizeQuestions: _randomizeQuestions,
          allowStudentRandomizeQuestions: _allowStudentRandomizeQuestions,
          forfeitExitCountsAsAttempt:
              _maxAttemptsApplies && _forfeitExitCountsAsAttempt,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      if (mounted) context.showDioErrorSnackBar(e);
    } catch (_) {
      if (mounted) {
        context.showErrorSnackBar(DioErrorMapper.genericMessage(l10n));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pageTitle = widget.isEditMode
        ? l10n.teacherAssignmentEditTitle
        : l10n.teacherAssignmentCreateTitle;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: pageTitle),
      bottomBar: AppBottomActionBar(
        children: [
          _TeacherPrimaryButton(
            label: widget.isEditMode
                ? l10n.teacherAssignmentSaveAction
                : l10n.teacherAssignmentCreateAction,
            isLoading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: AppPaddedScrollBody(
          includeBottom: false,
          child: ListView(
          children: [
            Text(
              l10n.teacherAssignmentFormSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  _SectionCard(
                    icon: Icons.edit_note_rounded,
                    title: l10n.teacherAssignmentSectionDetails,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FieldLabel(l10n.teacherAssignmentTitleLabel),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _titleCtrl,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: _inputDecoration(
                            l10n.teacherAssignmentTitleHint,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.teacherAssignmentTitleRequired
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _FieldLabel(l10n.teacherAssignmentInstructionsLabel),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _instructionsCtrl,
                          style: const TextStyle(color: AppColors.textPrimary),
                          maxLines: 3,
                          decoration: _inputDecoration(''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    icon: Icons.quiz_rounded,
                    title: l10n.teacherAssignmentSectionQuiz,
                    child: widget.isEditMode
                        ? _LockedQuizCard(
                            title: _lockedQuizTitle ?? '',
                            hint: l10n.teacherAssignmentQuizLockedHint,
                          )
                        : _QuizSelectionSection(
                            loading: _quizzesLoading,
                            selectedQuiz: _selectedQuiz,
                            onSelectQuiz: _openQuizPicker,
                            selectLabel: l10n.teacherAssignmentSelectQuizAction,
                            changeLabel: l10n.teacherAssignmentChangeQuizAction,
                            draftWarning: l10n.teacherAssignmentQuizDraftWarning,
                            emptyHint: l10n.teacherAssignmentNoQuizzesHint,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    icon: Icons.calendar_month_rounded,
                    title: l10n.teacherAssignmentSectionSchedule,
                    child: Row(
                      children: [
                        Expanded(
                          child: _DateTile(
                            label: l10n.teacherAssignmentStartsAtLabel,
                            value: _startsAt,
                            placeholder: l10n.teacherAssignmentPickDatePlaceholder,
                            onTap: () => _pickDate(false),
                            onClear: _startsAt != null
                                ? () => _clearDate(false)
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _DateTile(
                            label: l10n.teacherAssignmentDueAtLabel,
                            value: _dueAt,
                            placeholder: l10n.teacherAssignmentPickDatePlaceholder,
                            onTap: () => _pickDate(true),
                            onClear:
                                _dueAt != null ? () => _clearDate(true) : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    icon: Icons.tune_rounded,
                    title: l10n.teacherAssignmentSectionRules,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FieldLabel(l10n.teacherAssignmentMaxAttemptsLabel),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _maxAttemptsCtrl,
                          style: const TextStyle(color: AppColors.textPrimary),
                          keyboardType: TextInputType.number,
                          onChanged: (_) {
                            if (!_maxAttemptsApplies && _forfeitExitCountsAsAttempt) {
                              setState(() => _forfeitExitCountsAsAttempt = false);
                            } else {
                              setState(() {});
                            }
                          },
                          decoration: _inputDecoration(
                            l10n.teacherAssignmentMaxAttemptsHint,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l10n.teacherAssignmentRandomizeQuestionsLabel,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            l10n.teacherAssignmentRandomizeQuestionsHint,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          value: _randomizeQuestions,
                          onChanged: (v) =>
                              setState(() => _randomizeQuestions = v),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l10n.teacherAssignmentAllowStudentRandomizeLabel,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            l10n.teacherAssignmentAllowStudentRandomizeHint,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          value: _allowStudentRandomizeQuestions,
                          onChanged: (v) => setState(
                            () => _allowStudentRandomizeQuestions = v,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l10n.teacherAssignmentForfeitExitLabel,
                            style: TextStyle(
                              color: _maxAttemptsApplies
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            _maxAttemptsApplies
                                ? l10n.teacherAssignmentForfeitExitHint
                                : l10n.teacherAssignmentForfeitRequiresMaxAttempts,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          value: _forfeitExitCountsAsAttempt && _maxAttemptsApplies,
                          onChanged: _maxAttemptsApplies
                              ? (v) => setState(
                                    () => _forfeitExitCountsAsAttempt = v,
                                  )
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _FieldLabel(l10n.teacherAssignmentShowAnswersLabel),
                        const SizedBox(height: AppSpacing.sm),
                        _ShowAnswersSelector(
                          value: _showAnswersMode,
                          onChanged: (v) => setState(() => _showAnswersMode = v),
                          options: [
                            _ShowAnswersOption(
                              value: 'after_attempt',
                              label: l10n.teacherAssignmentShowAnswersAfterAttempt,
                              icon: Icons.replay_rounded,
                            ),
                            _ShowAnswersOption(
                              value: 'after_due_date',
                              label: l10n.teacherAssignmentShowAnswersAfterDue,
                              icon: Icons.event_available_rounded,
                            ),
                            _ShowAnswersOption(
                              value: 'teacher_only',
                              label: l10n.teacherAssignmentShowAnswersTeacherOnly,
                              icon: Icons.school_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint.isEmpty ? null : hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          borderSide: const BorderSide(
            color: AppColors.teacherAccent,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      variant: AppCardVariant.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.teacherAccent),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _QuizSelectionSection extends StatelessWidget {
  const _QuizSelectionSection({
    required this.loading,
    required this.selectedQuiz,
    required this.onSelectQuiz,
    required this.selectLabel,
    required this.changeLabel,
    required this.draftWarning,
    required this.emptyHint,
  });

  final bool loading;
  final QuizModel? selectedQuiz;
  final VoidCallback onSelectQuiz;
  final String selectLabel;
  final String changeLabel;
  final String draftWarning;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.teacherAccent),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedQuiz != null) ...[
          _SelectedQuizCard(
            quiz: selectedQuiz!,
            changeLabel: changeLabel,
            onChange: onSelectQuiz,
          ),
          if (selectedQuiz!.publicationStatus != 'published') ...[
            const SizedBox(height: AppSpacing.sm),
            _DraftWarningBanner(message: draftWarning),
          ],
          const SizedBox(height: AppSpacing.sm),
        ] else ...[
          Text(
            emptyHint,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppSecondaryButton(
          label: selectLabel,
          icon: Icons.library_books_outlined,
          accentColor: AppColors.teacherAccent,
          onPressed: onSelectQuiz,
        ),
      ],
    );
  }
}

class _SelectedQuizCard extends StatelessWidget {
  const _SelectedQuizCard({
    required this.quiz,
    required this.changeLabel,
    required this.onChange,
  });

  final QuizModel quiz;
  final String changeLabel;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPublished = quiz.publicationStatus == 'published';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        border: Border.all(
          color: AppColors.teacherAccent.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.teacherAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.teacherAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _StatusChip(
                      label: isPublished
                          ? l10n.quizStatusPublished
                          : l10n.quizStatusDraft,
                      isPublished: isPublished,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.quizQuestionsCount(quiz.questionCount),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.teacherAccent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(changeLabel),
          ),
        ],
      ),
    );
  }
}

class _LockedQuizCard extends StatelessWidget {
  const _LockedQuizCard({
    required this.title,
    required this.hint,
  });

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftWarningBanner extends StatelessWidget {
  const _DraftWarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizPickerTile extends StatelessWidget {
  const _QuizPickerTile({
    required this.quiz,
    required this.selected,
    required this.onTap,
  });

  final QuizModel quiz;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPublished = quiz.publicationStatus == 'published';

    return Material(
      color: selected
          ? AppColors.teacherAccent.withValues(alpha: 0.12)
          : AppColors.background,
      borderRadius: BorderRadius.circular(AppColors.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            border: Border.all(
              color: selected
                  ? AppColors.teacherAccent.withValues(alpha: 0.5)
                  : AppColors.textSecondary.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StatusChip(
                          label: isPublished
                              ? l10n.quizStatusPublished
                              : l10n.quizStatusDraft,
                          isPublished: isPublished,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.quizQuestionsCount(quiz.questionCount),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.teacherAccent,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isPublished,
  });

  final String label;
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    final color =
        isPublished ? AppColors.accentMint : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final String placeholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final display =
        hasValue ? AssignmentDates.format(context, value!) : placeholder;

    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppColors.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            border: Border.all(
              color: hasValue
                  ? AppColors.teacherAccent.withValues(alpha: 0.35)
                  : AppColors.textSecondary.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 14,
                    color: hasValue
                        ? AppColors.teacherAccent
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (onClear != null)
                    GestureDetector(
                      onTap: onClear,
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                display,
                style: TextStyle(
                  color: hasValue
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _ShowAnswersOption {
  const _ShowAnswersOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

class _ShowAnswersSelector extends StatelessWidget {
  const _ShowAnswersSelector({
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final List<_ShowAnswersOption> options;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          _ShowAnswersTile(
            option: options[i],
            selected: value == options[i].value,
            onTap: () => onChanged(options[i].value),
          ),
        ],
      ],
    );
  }
}

class _ShowAnswersTile extends StatelessWidget {
  const _ShowAnswersTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ShowAnswersOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.teacherAccent.withValues(alpha: 0.12)
          : AppColors.background,
      borderRadius: BorderRadius.circular(AppColors.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            border: Border.all(
              color: selected
                  ? AppColors.teacherAccent.withValues(alpha: 0.45)
                  : AppColors.textSecondary.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                option.icon,
                size: 18,
                color: selected
                    ? AppColors.teacherAccent
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: selected
                    ? AppColors.teacherAccent
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherPrimaryButton extends StatelessWidget {
  const _TeacherPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && onPressed != null;

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          gradient: LinearGradient(
            colors: enabled
                ? [
                    AppColors.teacherAccent,
                    const Color(0xFF9B8FFF),
                  ]
                : [
                    AppColors.teacherAccent.withValues(alpha: 0.45),
                    const Color(0xFF9B8FFF).withValues(alpha: 0.45),
                  ],
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.teacherAccent.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.background,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.background,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
