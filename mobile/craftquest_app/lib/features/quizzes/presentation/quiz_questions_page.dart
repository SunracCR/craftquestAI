import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_page_header.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/core/widgets/app_question_accordion_tile.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/quizzes/data/models/quiz_models.dart';
import 'package:craftquest_app/features/quizzes/data/quiz_repository.dart';
import 'package:craftquest_app/features/quizzes/presentation/add_question_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class QuizQuestionsPage extends StatefulWidget {
  const QuizQuestionsPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  final String quizId;
  final String quizTitle;

  @override
  State<QuizQuestionsPage> createState() => _QuizQuestionsPageState();
}

class _QuizQuestionsPageState extends State<QuizQuestionsPage> {
  final _repository = getIt<QuizRepository>();
  List<QuestionModel>? _questions;
  bool _loading = true;
  String? _error;
  bool _dataChanged = false;
  final Set<int> _expandedIndices = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final questions = await _repository.getQuestions(widget.quizId);
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loading = false;
        _expandedIndices.removeWhere((i) => i >= questions.length);
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.map(e);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.genericMessage();
        _loading = false;
      });
    }
  }

  Future<void> _addQuestion() async {
    final l10n = AppLocalizations.of(context)!;
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddQuestionPage(quizId: widget.quizId),
      ),
    );
    if (added == true) {
      _dataChanged = true;
      if (mounted) {
        context.showSuccessSnackBar(l10n.questionSavedMessage);
      }
      await _load();
    }
  }

  Future<void> _editQuestion(QuestionModel question) async {
    final l10n = AppLocalizations.of(context)!;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddQuestionPage(
          quizId: widget.quizId,
          existingQuestion: question,
        ),
      ),
    );
    if (updated == true) {
      _dataChanged = true;
      if (mounted) {
        context.showSuccessSnackBar(l10n.questionSavedMessage);
      }
      await _load();
    }
  }

  Future<void> _confirmDelete(QuestionModel question) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteQuestionConfirmTitle),
        content: Text(l10n.deleteQuestionConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteQuestionAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _repository.deleteQuestion(
        quizId: widget.quizId,
        questionId: question.questionId,
      );
      if (!mounted) return;
      _dataChanged = true;
      context.showSuccessSnackBar(l10n.questionDeletedMessage);
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    }
  }

  void _toggleExpanded(int index, bool expanded) {
    setState(() {
      if (expanded) {
        _expandedIndices.add(index);
      } else {
        _expandedIndices.remove(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final questionCount = _questions?.length ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_dataChanged);
      },
      child: EdgeAwareScaffold(
        appBar: craftQuestAppBar(title: l10n.quizDetailQuestionsSection),
        bottomBar: _loading
            ? null
            : AppBottomActionBar(
                children: [
                  AppGradientPrimaryButton(
                    label: l10n.addQuestionAction,
                    icon: Icons.add_rounded,
                    onPressed: _addQuestion,
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
                : RefreshIndicator(
                    onRefresh: _load,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: AppPageHeader(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.md,
                                AppSpacing.md,
                                AppSpacing.sm,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.quizTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  AppMetaText(
                                    text: l10n.quizQuestionsCount(questionCount),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_questions == null || _questions!.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: AppEmptyView(message: l10n.questionsEmpty),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.xs,
                              AppSpacing.md,
                              AppSpacing.sm,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final question = _questions![index];
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: AppQuestionAccordionTile(
                                      index: index + 1,
                                      question: question,
                                      l10n: l10n,
                                      expanded: _expandedIndices.contains(index),
                                      onExpansionChanged: (v) =>
                                          _toggleExpanded(index, v),
                                      onEdit: () => _editQuestion(question),
                                      onDelete: () =>
                                          _confirmDelete(question),
                                    ),
                                  );
                                },
                                childCount: _questions!.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
