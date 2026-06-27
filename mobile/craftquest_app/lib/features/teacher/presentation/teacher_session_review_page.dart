import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/widgets/app_zoomable_network_image.dart';
import 'package:dio/dio.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_media_display.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/core/widgets/app_padded_scroll.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/guest/data/guest_repository.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_review_models.dart';
import 'package:craftquest_app/features/practice/data/practice_repository.dart';
import 'package:craftquest_app/features/teacher/data/teacher_review_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class TeacherSessionReviewPage extends StatefulWidget {
  const TeacherSessionReviewPage({
    super.key,
    required this.sessionId,
    required this.quizTitle,
    this.isMyReview = false,
    this.isGuestMode = false,
    this.guestVisitId,
    this.guestToken,
    this.initialQuestionSnapshotId,
  });

  final String sessionId;
  final String quizTitle;
  final bool isMyReview;
  final bool isGuestMode;
  final String? guestVisitId;
  final String? guestToken;
  final String? initialQuestionSnapshotId;

  @override
  State<TeacherSessionReviewPage> createState() =>
      _TeacherSessionReviewPageState();
}

class _TeacherSessionReviewPageState extends State<TeacherSessionReviewPage> {
  final _teacherRepository = getIt<TeacherReviewRepository>();
  final _practiceRepository = getIt<PracticeRepository>();
  final _questionAnchorKeys = <String, GlobalKey>{};
  TeacherPracticeReviewModel? _review;
  bool _loading = true;
  String? _error;
  bool _didScrollToInitialQuestion = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final TeacherPracticeReviewModel review;
      if (widget.isGuestMode &&
          widget.guestVisitId != null &&
          widget.guestToken != null) {
        final guestRepo = getIt<GuestRepository>();
        review = await guestRepo.getAttemptReview(
          visitId: widget.guestVisitId!,
          token: widget.guestToken!,
          sessionId: widget.sessionId,
          forceRefresh: forceRefresh,
        );
      } else if (widget.isMyReview) {
        review = await _practiceRepository.getMySessionReview(
          widget.sessionId,
          forceRefresh: forceRefresh,
        );
      } else {
        review = await _teacherRepository.getSessionReview(widget.sessionId);
      }
      if (!mounted) return;
      setState(() {
        _review = review;
        _loading = false;
      });
      _scheduleScrollToInitialQuestion();
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

  bool _showStudentCorrectSelection(TeacherAnswerReviewModel answer) {
    if (_review?.revealCorrectAnswers == false) return false;
    return answer.wasSelected && answer.isCorrect;
  }

  bool _showStudentWrongSelection(TeacherAnswerReviewModel answer) {
    if (_review?.revealCorrectAnswers == false) return false;
    return answer.wasSelected && !answer.isCorrect;
  }

  bool _showRevealedCorrectAnswer(
    TeacherQuestionReviewModel question,
    TeacherAnswerReviewModel answer,
  ) {
    if (_review?.revealCorrectAnswers == false) return false;
    if (!answer.isCorrect || answer.wasSelected) return false;
    return question.isCorrect != true;
  }

  bool _showSelectionOnly(TeacherAnswerReviewModel answer) =>
      _review?.revealCorrectAnswers == false && answer.wasSelected;

  Color _answerBorderColor(
    TeacherQuestionReviewModel question,
    TeacherAnswerReviewModel answer,
  ) {
    if (_showSelectionOnly(answer)) {
      return AppColors.accentViolet.withValues(alpha: 0.55);
    }
    if (_showStudentWrongSelection(answer)) {
      return AppColors.error;
    }
    if (_showStudentCorrectSelection(answer)) {
      return AppColors.accentMint;
    }
    if (_showRevealedCorrectAnswer(question, answer)) {
      return AppColors.accentMint.withValues(alpha: 0.45);
    }
    return AppColors.textSecondary.withValues(alpha: 0.3);
  }

  Color? _answerFillColor(
    TeacherQuestionReviewModel question,
    TeacherAnswerReviewModel answer,
  ) {
    if (_showSelectionOnly(answer)) {
      return AppColors.accentViolet.withValues(alpha: 0.1);
    }
    if (_showStudentWrongSelection(answer)) {
      return AppColors.error.withValues(alpha: 0.12);
    }
    if (_showStudentCorrectSelection(answer)) {
      return AppColors.accentMint.withValues(alpha: 0.12);
    }
    if (_showRevealedCorrectAnswer(question, answer)) {
      return AppColors.accentMint.withValues(alpha: 0.05);
    }
    return null;
  }

  Widget? _answerTrailingIcon(
    TeacherQuestionReviewModel question,
    TeacherAnswerReviewModel answer,
  ) {
    if (_showSelectionOnly(answer)) {
      return const Icon(
        Icons.radio_button_checked,
        size: 20,
        color: AppColors.accentViolet,
      );
    }
    if (_showStudentWrongSelection(answer)) {
      return const Icon(
        Icons.cancel_outlined,
        size: 20,
        color: AppColors.error,
      );
    }
    if (_showStudentCorrectSelection(answer)) {
      return const Icon(
        Icons.check_circle_outline,
        size: 20,
        color: AppColors.accentMint,
      );
    }
    if (_showRevealedCorrectAnswer(question, answer)) {
      return const Icon(
        Icons.lightbulb_outline,
        size: 20,
        color: AppColors.accentMint,
      );
    }
    return null;
  }

  String? _answerTagLabel(AppLocalizations l10n, TeacherQuestionReviewModel question, TeacherAnswerReviewModel answer) {
    if (_showStudentCorrectSelection(answer)) {
      return l10n.teacherReviewYourAnswerTag;
    }
    if (_showStudentWrongSelection(answer)) {
      return l10n.teacherReviewYourAnswerTag;
    }
    if (_showRevealedCorrectAnswer(question, answer)) {
      return l10n.teacherReviewCorrectAnswerTag;
    }
    return null;
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

  Widget? _buildCollapsibleJustification(
    BuildContext context,
    AppLocalizations l10n,
    TeacherQuestionReviewModel question,
  ) {
    final text = question.justificationText?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }

    return _PracticeReviewJustificationPanel(
      title: l10n.practiceReviewJustificationTitle,
      expandHint: l10n.practiceReviewJustificationTapToExpand,
      text: text,
      sources: question.justificationSources,
      pageLabel: l10n.practiceReviewSourcePage,
    );
  }

  GlobalKey _anchorKeyFor(String practiceQuestionSnapshotId) =>
      _questionAnchorKeys.putIfAbsent(practiceQuestionSnapshotId, GlobalKey.new);

  void _scheduleScrollToInitialQuestion() {
    final targetId = widget.initialQuestionSnapshotId;
    if (targetId == null || _didScrollToInitialQuestion) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didScrollToInitialQuestion) {
          return;
        }
        final context = _questionAnchorKeys[targetId]?.currentContext;
        if (context == null) {
          return;
        }
        _didScrollToInitialQuestion = true;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: 0.08,
        );
      });
    });
  }

  Widget? _buildMediaPreview(
    String? mediaUrl, {
    double height = AppMediaDisplay.optionImageHeight,
  }) {
    final resolved = _resolveMediaUrl(mediaUrl);
    if (resolved == null) {
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AppZoomableNetworkImage(
        imageUrl: resolved,
        height: height,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final review = _review;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(
        title: widget.isMyReview
            ? l10n.myPracticeReviewTitle
            : l10n.teacherReviewTitle,
      ),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: () => _load(forceRefresh: true),
                )
              : review == null
                  ? const SizedBox.shrink()
                  : AppPaddedScrollBody(
                      child: ListView(
                      children: [
                        Text(
                          widget.quizTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (!widget.isMyReview)
                          AppMetaText(
                            text: l10n.teacherReviewStudentLabel(
                              review.student.displayName ??
                                  review.student.userId,
                            ),
                          ),
                        AppMetaText(
                          text: l10n.teacherReviewScoreLabel(
                            review.scoreObtained,
                            review.scorePossible,
                          ),
                        ),
                        if (review.revealCorrectAnswers) ...[
                          const SizedBox(height: 8),
                          AppMetaText(text: l10n.teacherReviewLegend),
                        ],
                        const SizedBox(height: 16),
                        ...review.questions.map((q) {
                          final highlightTarget =
                              widget.initialQuestionSnapshotId ==
                                  q.practiceQuestionSnapshotId;
                          return Padding(
                            key: _anchorKeyFor(q.practiceQuestionSnapshotId),
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DecoratedBox(
                              decoration: highlightTarget
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        AppColors.radiusSm,
                                      ),
                                      border: Border.all(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.85),
                                        width: 2,
                                      ),
                                    )
                                  : const BoxDecoration(),
                              child: AppSectionCard(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.teacherReviewQuestionLabel(
                                      q.displayOrder,
                                      q.questionText,
                                    ),
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  if (_buildMediaPreview(
                                        q.questionMediaUrl,
                                        height: AppMediaDisplay.questionImageHeight,
                                      )
                                      case final questionImage?)
                                    questionImage,
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.teacherReviewAnswerStatus(
                                      q.answerStatus,
                                      q.pointsAwarded,
                                      q.pointsPossible,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: q.isCorrect == true
                                              ? AppColors.accentMint
                                              : q.isCorrect == false
                                                  ? AppColors.error
                                                  : AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...q.answersAsDisplayedToStudent.map((a) {
                                    final optionText = a.text?.trim() ?? '';
                                    final optionImage =
                                        _buildMediaPreview(a.mediaUrl);
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          AppColors.radiusSm,
                                        ),
                                        border: Border.all(
                                          color: _answerBorderColor(q, a),
                                        ),
                                        color: _answerFillColor(q, a),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (a.displayLabel.isNotEmpty)
                                            Text(
                                              '${a.displayLabel}.',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge,
                                            ),
                                          if (a.displayLabel.isNotEmpty)
                                            const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (_answerTagLabel(l10n, q, a)
                                                    case final tag?)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      bottom: 4,
                                                    ),
                                                    child: Text(
                                                      tag,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color: AppColors
                                                                .textSecondary,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                  ),
                                                if (optionText.isNotEmpty)
                                                  Text(optionText),
                                                if (optionImage != null)
                                                  optionImage,
                                              ],
                                            ),
                                          ),
                                          if (_answerTrailingIcon(q, a)
                                              case final icon?)
                                            icon,
                                        ],
                                      ),
                                    );
                                  }),
                                  if (_buildCollapsibleJustification(
                                        context,
                                        l10n,
                                        q,
                                      )
                                      case final justificationPanel?) ...[
                                    const SizedBox(height: 12),
                                    justificationPanel,
                                  ],
                                ],
                              ),
                            ),
                            ),
                          );
                        }),
                      ],
                    ),
                    ),
    );
  }
}

class _PracticeReviewJustificationPanel extends StatefulWidget {
  const _PracticeReviewJustificationPanel({
    required this.title,
    required this.expandHint,
    required this.text,
    required this.sources,
    required this.pageLabel,
  });

  final String title;
  final String expandHint;
  final String text;
  final List<TeacherJustificationSourceReviewModel> sources;
  final String Function(int page) pageLabel;

  @override
  State<_PracticeReviewJustificationPanel> createState() =>
      _PracticeReviewJustificationPanelState();
}

class _PracticeReviewJustificationPanelState
    extends State<_PracticeReviewJustificationPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.accentGold,
          fontWeight: FontWeight.w800,
        );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.35),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: titleStyle),
                          if (!_expanded) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.expandHint,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.accentGold,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.35),
                  ),
                  ...widget.sources.map((s) {
                    if (s.pageNumber == null &&
                        (s.snippet == null || s.snippet!.isEmpty)) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        s.pageNumber != null
                            ? widget.pageLabel(s.pageNumber!)
                            : s.snippet!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
