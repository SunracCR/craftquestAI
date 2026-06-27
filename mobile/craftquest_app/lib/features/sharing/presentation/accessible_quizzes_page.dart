import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/utils/deferred_screen_load.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_list_entry_card.dart';
import 'package:craftquest_app/core/widgets/app_notice_banner.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_detail_page.dart';
import 'package:craftquest_app/features/sharing/data/models/sharing_models.dart';
import 'package:craftquest_app/features/sharing/data/sharing_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class _SharerGroup {
  _SharerGroup({
    required this.userId,
    required this.displayName,
    required this.quizzes,
  });

  final String userId;
  final String displayName;
  final List<AccessibleQuizModel> quizzes;
}

class AccessibleQuizzesPage extends StatefulWidget {
  const AccessibleQuizzesPage({super.key});

  @override
  State<AccessibleQuizzesPage> createState() => _AccessibleQuizzesPageState();
}

class _AccessibleQuizzesPageState extends State<AccessibleQuizzesPage>
    with ScreenLoadGeneration {
  final _repository = getIt<SharingRepository>();
  final _billingRepository = getIt<BillingRepository>();
  List<AccessibleQuizModel> _quizzes = [];
  UserBillingModel? _billing;
  bool _loading = true;
  String? _error;
  final Set<String> _expandedSharers = {};

  @override
  void initState() {
    super.initState();
    scheduleInitialScreenLoad(_load);
  }

  Future<void> _load() async {
    final loadId = beginScreenLoad();
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getAccessibleQuizzes(),
        _billingRepository.getMyBilling(),
      ]);
      if (!mounted || isStaleScreenLoad(loadId)) return;
      setState(() {
        _quizzes = results[0] as List<AccessibleQuizModel>;
        _billing = results[1] as UserBillingModel;
        _loading = false;
        if (_expandedSharers.isEmpty) {
          _expandedSharers.addAll(
            _quizzes.map((q) => q.sharedByUserId).toSet(),
          );
        }
      });
    } on DioException catch (e) {
      if (!mounted || isStaleScreenLoad(loadId)) return;
      setState(() {
        _error = DioErrorMapper.map(e);
        _loading = false;
      });
    } catch (_) {
      if (!mounted || isStaleScreenLoad(loadId)) return;
      setState(() {
        _error = DioErrorMapper.genericMessage();
        _loading = false;
      });
    }
  }

  List<_SharerGroup> _groupBySharer(AppLocalizations l10n) {
    final byUser = <String, List<AccessibleQuizModel>>{};
    for (final quiz in _quizzes) {
      byUser.putIfAbsent(quiz.sharedByUserId, () => []).add(quiz);
    }

    return byUser.entries
        .map((entry) {
          final displayName = entry.value.first.sharedByDisplayName?.trim();
          return _SharerGroup(
            userId: entry.key,
            displayName: displayName != null && displayName.isNotEmpty
                ? displayName
                : l10n.roleUnknown,
            quizzes: entry.value
              ..sort((a, b) => a.title.compareTo(b.title)),
          );
        })
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  Future<void> _openQuiz(AccessibleQuizModel quiz) async {
    final removed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => QuizDetailPage(
          quizId: quiz.quizId,
          quizTitle: quiz.title,
          publicationStatus: 'published',
          isOwner: false,
        ),
      ),
    );
    if (mounted && removed == true) {
      await _load();
    }
  }

  Future<void> _confirmRemoveQuiz(AccessibleQuizModel quiz) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accessibleQuizzesRemoveConfirmTitle),
        content: Text(l10n.accessibleQuizzesRemoveConfirmMessage(quiz.title)),
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
      await _repository.removeAccessibleQuiz(quiz.quizId);
      if (!mounted) return;
      context.showSuccessSnackBar(l10n.accessibleQuizzesRemovedMessage);
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(DioErrorMapper.map(e));
    }
  }

  Widget _buildSharerAccordion(
    AppLocalizations l10n,
    _SharerGroup group,
  ) {
    final expanded = _expandedSharers.contains(group.userId);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: PageStorageKey<String>('sharer-${group.userId}'),
          initiallyExpanded: expanded,
          onExpansionChanged: (value) {
            setState(() {
              if (value) {
                _expandedSharers.add(group.userId);
              } else {
                _expandedSharers.remove(group.userId);
              }
            });
          },
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            0,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.accentViolet.withValues(alpha: 0.2),
            child: Icon(
              Icons.person_rounded,
              color: AppColors.accentViolet.withValues(alpha: 0.95),
            ),
          ),
          title: Text(
            l10n.accessibleQuizzesSharedBy(group.displayName),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          subtitle: Text(
            l10n.accessibleQuizzesGroupCount(group.quizzes.length),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          children: group.quizzes
              .map(
                (quiz) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: AppListEntryCard(
                    title: quiz.title,
                    subtitle: l10n.quizListSubtitle(
                      'published',
                      quiz.questionCount,
                    ),
                    accentColor: AppColors.accent,
                    leadingIcon: Icons.quiz_rounded,
                    onTap: () => _openQuiz(quiz),
                    trailing: IconButton(
                      tooltip: l10n.accessibleQuizzesRemoveAction,
                      icon: Icon(
                        Icons.link_off_rounded,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                      onPressed: () => _confirmRemoveQuiz(quiz),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget? _buildSlotBanner(AppLocalizations l10n) {
    final billing = _billing;
    final max = billing?.entitlements.maxRedeemedSharedQuizzes;
    if (max == null) return null;

    final current = billing!.entitlements.currentRedeemedSharedQuizzes;
    final full = current >= max;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppNoticeBanner(
        message: full
            ? l10n.accessibleQuizzesSlotFull
            : l10n.accessibleQuizzesSlotBanner(current, max),
        icon: full ? Icons.info_outline_rounded : Icons.library_books_outlined,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groups = _groupBySharer(l10n);
    final slotBanner = _buildSlotBanner(l10n);

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.accessibleQuizzesTitle),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : _quizzes.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: AppSpacing.listBottom,
                        children: [
                          if (slotBanner != null) slotBanner,
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.45,
                            child: AppEmptyView(
                              message: l10n.accessibleQuizzesEmpty,
                              icon: Icons.library_books_outlined,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: AppSpacing.listBottom,
                        children: [
                          if (slotBanner != null) slotBanner,
                          for (final group in groups)
                            _buildSharerAccordion(l10n, group),
                        ],
                      ),
                    ),
    );
  }
}
