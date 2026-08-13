import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/utils/deferred_screen_load.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/offline_practice/presentation/offline_downloads_page.dart';
import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:craftquest_app/features/practice/data/practice_repository.dart';
import 'package:craftquest_app/features/quizzes/data/models/quiz_models.dart';
import 'package:craftquest_app/features/quizzes/data/quiz_repository.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_flow_anchor.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_content_setup_flow.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_detail_page.dart';
import 'package:craftquest_app/features/quizzes/presentation/utils/quiz_folder_actions.dart';
import 'package:craftquest_app/features/quizzes/presentation/utils/quiz_folder_tree.dart';
import 'package:craftquest_app/features/quizzes/presentation/widgets/quiz_folder_grouped_list.dart';
import 'package:craftquest_app/features/quizzes/presentation/widgets/quiz_search_field.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class QuizListPage extends StatefulWidget {
  const QuizListPage({super.key});

  @override
  State<QuizListPage> createState() => _QuizListPageState();
}

class _QuizListPageState extends State<QuizListPage> with ScreenLoadGeneration {
  late final QuizRepository _repository = getIt<QuizRepository>();
  late final PracticeRepository _practiceRepository = getIt<PracticeRepository>();
  final _searchController = TextEditingController();
  List<QuizModel>? _quizzes;
  List<QuizFolderModel> _folders = [];
  Map<String, PracticeActiveSessionModel> _inProgressByQuizId = {};
  String? _error;
  bool _loading = true;
  bool _isConnectivityError = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    scheduleInitialScreenLoad(_load);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    final loadId = beginScreenLoad();
    if (!mounted) return;
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
        _isConnectivityError = false;
      });
    }
    try {
      final results = await Future.wait([
        _repository.getMyQuizzes(),
        _repository.getFolders(),
      ]);
      if (!mounted || isStaleScreenLoad(loadId)) return;
      setState(() {
        _quizzes = results[0] as List<QuizModel>;
        _folders = results[1] as List<QuizFolderModel>;
        _loading = false;
        _isConnectivityError = false;
      });
      unawaited(_loadInProgressSessions());
    } on DioException catch (e) {
      if (!mounted || isStaleScreenLoad(loadId)) return;
      setState(() {
        _error = DioErrorMapper.map(e);
        _loading = false;
        _isConnectivityError = DioErrorMapper.isConnectivityFailure(e) ||
            DioErrorMapper.isTimeoutFailure(e);
      });
    } catch (_) {
      if (!mounted || isStaleScreenLoad(loadId)) return;
      setState(() {
        _error = DioErrorMapper.genericMessage();
        _loading = false;
        _isConnectivityError = false;
      });
    }
  }

  Future<void> _openOfflineDownloads() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const OfflineDownloadsPage(),
      ),
    );
  }

  Future<void> _loadInProgressSessions() async {
    try {
      final inProgress = await _practiceRepository.getInProgressSessions();
      if (!mounted) return;
      setState(() {
        _inProgressByQuizId = {
          for (final s in inProgress) s.quizId: s,
        };
      });
    } catch (_) {
      // No bloquea la lista de cuestionarios si falla o tarda la práctica en curso.
    }
  }

  Future<void> _openCreate() async {
    QuizFlowAnchor.mark(context);
    final created = await QuizContentSetupFlow.createQuizWithSetup(context);
    if (created == null || !mounted) return;

    await _load();
  }

  List<QuizFolderNode> get _folderTree => buildQuizFolderTree(
        folders: _folders,
        quizzes: _quizzes ?? const [],
      );

  Future<void> _createFolder({String? parentFolderId}) async {
    await createQuizFolderFlow(
      context: context,
      repository: _repository,
      parentFolderId: parentFolderId,
      onSuccess: _load,
    );
  }

  Future<void> _showFolderMenu(QuizFolderNode node) async {
    await showQuizFolderOptionsSheet(
      context: context,
      node: node,
      onRename: () => renameQuizFolderFlow(
        context: context,
        repository: _repository,
        folder: node.folder,
        onSuccess: _load,
      ),
      onMove: () => moveFolderToFolderFlow(
        context: context,
        repository: _repository,
        folder: node.folder,
        folders: _folders,
        folderTree: _folderTree,
        onSuccess: _load,
      ),
      onDelete: () => deleteQuizFolderFlow(
        context: context,
        repository: _repository,
        node: node,
        onSuccess: _load,
      ),
      onCreateSubfolder: () => _createFolder(parentFolderId: node.folder.quizFolderId),
    );
  }

  Future<void> _moveQuiz(QuizModel quiz) async {
    await moveQuizToFolderFlow(
      context: context,
      repository: _repository,
      quiz: quiz,
      folders: _folders,
      folderTree: _folderTree,
      onSuccess: _load,
    );
  }

  Future<void> _reparentFolder(QuizFolderModel folder, String? newParentId) async {
    await moveFolderFlow(
      context: context,
      repository: _repository,
      folder: folder,
      newParentId: newParentId,
      onSuccess: _load,
    );
  }

  Future<void> _reassignQuiz(QuizModel quiz, String? folderId) async {
    await reassignQuizFromDrag(
      context: context,
      repository: _repository,
      quiz: quiz,
      folderId: folderId,
      onSuccess: _load,
    );
  }

  Widget _buildQuizCard(QuizModel quiz) {
    final l10n = AppLocalizations.of(context)!;
    final activePractice = _inProgressByQuizId[quiz.quizId];
    final isPublished = quiz.publicationStatus == 'published';
    final accent =
        isPublished ? AppColors.accentMint : AppColors.accentGold;
    var subtitle = l10n.quizListSubtitle(
      quiz.publicationStatus,
      quiz.questionCount,
    );
    if (quiz.hasPendingAiDraft) {
      subtitle = '$subtitle · ${l10n.quizListPendingAiDraft}';
    }
    if (activePractice != null) {
      subtitle =
          '$subtitle · ${l10n.practiceInProgressSubtitle(activePractice.answeredCount, activePractice.totalQuestions)}';
    }

    return _CompactQuizListTile(
      title: quiz.title,
      subtitle: subtitle,
      accentColor: accent,
      leadingIcon:
          isPublished ? Icons.check_circle_rounded : Icons.edit_note_rounded,
      onMove: _folders.isEmpty ? null : () => _moveQuiz(quiz),
      moveTooltip: l10n.quizFolderMoveQuizAction,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => QuizDetailPage(
              quizId: quiz.quizId,
              quizTitle: quiz.title,
              publicationStatus: quiz.publicationStatus,
            ),
          ),
        );
        if (!mounted) return;
        scheduleReturnRefresh(() => _load(showLoading: false));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(
        title: l10n.quizzesTitle,
        actions: [
          IconButton(
            onPressed: () => _createFolder(),
            tooltip: l10n.quizFolderNewFolderAction,
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
        ],
      ),
      bottomBar: _loading
          ? null
          : AppBottomActionBar(
              children: [
                AppGradientPrimaryButton(
                  label: l10n.createQuizAction,
                  icon: Icons.add_rounded,
                  onPressed: _openCreate,
                ),
              ],
            ),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  title: l10n.quizzesLoadError,
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                  secondaryActionLabel: _isConnectivityError
                      ? l10n.offlineDownloadsViewAction
                      : null,
                  onSecondaryAction: _isConnectivityError
                      ? _openOfflineDownloads
                      : null,
                )
              : (_quizzes == null || _quizzes!.isEmpty)
                  ? AppEmptyView(message: l10n.quizzesEmpty)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        QuizSearchField(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _load,
                            child: QuizFolderGroupedList(
                              folders: _folders,
                              quizzes: _quizzes!,
                              searchQuery: _searchQuery,
                              initiallyExpandFolders: false,
                              enableDrag: _searchQuery.trim().isEmpty,
                              quizBuilder: _buildQuizCard,
                              onFolderMenu: _showFolderMenu,
                              onQuizMove: _folders.isEmpty ? null : _moveQuiz,
                              onReparentFolder: _reparentFolder,
                              onReassignQuiz: _reassignQuiz,
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _CompactQuizListTile extends StatelessWidget {
  const _CompactQuizListTile({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.leadingIcon,
    required this.onTap,
    this.onMove,
    this.moveTooltip,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData leadingIcon;
  final VoidCallback onTap;
  final VoidCallback? onMove;
  final String? moveTooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHighlight,
      borderRadius: BorderRadius.circular(AppColors.radiusSm),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      leadingIcon,
                      size: 18,
                      color: accentColor,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: accentColor.withValues(alpha: 0.75),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onMove != null)
            IconButton(
              tooltip: moveTooltip,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.drive_file_move_outline_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: onMove,
            ),
        ],
      ),
    );
  }
}
