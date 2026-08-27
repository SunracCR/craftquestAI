import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_package_repository.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_session_checkpoint_repository.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_sync_repository.dart';
import 'package:craftquest_app/features/offline_practice/domain/offline_sync_manager.dart';
import 'package:craftquest_app/features/offline_practice/presentation/cubit/offline_practice_session_cubit.dart';
import 'package:craftquest_app/features/offline_practice/presentation/offline_practice_session_page.dart';
import 'package:craftquest_app/features/practice/data/practice_preferences_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OfflineDownloadsPage extends StatefulWidget {
  const OfflineDownloadsPage({super.key});

  @override
  State<OfflineDownloadsPage> createState() => _OfflineDownloadsPageState();
}

class _OfflineDownloadsPageState extends State<OfflineDownloadsPage> {
  final _repository = getIt<OfflinePackageRepository>();
  final _syncRepository = getIt<OfflineSyncRepository>();

  bool _loading = true;
  String? _error;
  List<OfflineDownloadedQuizSummaryModel> _items = const [];
  int _pendingSyncCount = 0;

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
      final items = await _repository.listDownloadedQuizzes();
      final pending = await _syncRepository.countPendingSessions();
      if (!mounted) return;
      setState(() {
        _items = items;
        _pendingSyncCount = pending;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteQuiz(String quizId) async {
    await _repository.deleteDownloadedQuiz(quizId);
    await _load();
  }

  Future<void> _syncNow() async {
    await getIt<OfflineSyncManager>().syncPendingSessions();
    await _load();
  }

  Future<void> _handleItemTap(OfflineDownloadedQuizSummaryModel item) async {
    if (_isExpired(item)) {
      await _showExpiredDialog(item);
      return;
    }
    await _openOfflineQuiz(item);
  }

  bool _isExpired(OfflineDownloadedQuizSummaryModel item) =>
      item.expiresAt.isBefore(DateTime.now().toUtc());

  Future<void> _showExpiredDialog(OfflineDownloadedQuizSummaryModel item) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Text(l10n.offlineDownloadsExpiredDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.offlineDownloadsDeleteAction),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteQuiz(item.quizId);
    }
  }

  Future<void> _openOfflineQuiz(OfflineDownloadedQuizSummaryModel item) async {
    bool? randomizeQuestions;
    try {
      final prefs =
          await getIt<PracticePreferencesRepository>().loadLaunchOptions(
        item.quizId,
      );
      randomizeQuestions = prefs.randomizeQuestions;
    } catch (_) {
      try {
        final package = await _repository.loadStoredQuizContent(item.quizId);
        randomizeQuestions = package?.randomizeQuestions;
      } catch (_) {}
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => OfflinePracticeSessionCubit(
            packageRepository: _repository,
            syncRepository: _syncRepository,
            checkpointRepository: getIt<OfflineSessionCheckpointRepository>(),
            quizId: item.quizId,
            randomizeQuestions: randomizeQuestions,
          )..load(),
          child: OfflinePracticeSessionPage(
            quizTitle: item.title,
          ),
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: AppBar(
        title: Text(l10n.offlineDownloadsAction),
        actions: [
          IconButton(
            onPressed: _syncNow,
            tooltip: l10n.offlineDownloadsSyncTooltip,
            icon: Badge(
              isLabelVisible: _pendingSyncCount > 0,
              label: Text('$_pendingSyncCount'),
              child: const Icon(Icons.sync),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : _items.isEmpty
                  ? AppEmptyView(
                      icon: Icons.download_for_offline_outlined,
                      message: l10n.offlineDownloadsEmptyMessage,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final expired = _isExpired(item);
                          return Card(
                            child: ListTile(
                              title: Text(item.title),
                              subtitle: Text(
                                l10n.offlineDownloadsItemSummary(
                                  item.questionCount,
                                  _formatBytes(item.totalBytes),
                                  item.mediaReady,
                                  item.mediaTotal,
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'play') {
                                    await _openOfflineQuiz(item);
                                  } else if (value == 'delete') {
                                    await _deleteQuiz(item.quizId);
                                  }
                                },
                                itemBuilder: (_) => [
                                  if (!expired)
                                    PopupMenuItem(
                                      value: 'play',
                                      child: Text(l10n.offlineDownloadsPlayAction),
                                    ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(l10n.offlineDownloadsDeleteAction),
                                  ),
                                ],
                              ),
                              onTap: () => _handleItemTap(item),
                              leading: Icon(
                                expired
                                    ? Icons.warning_amber_rounded
                                    : Icons.offline_pin,
                                color: expired
                                    ? AppColors.warning
                                    : AppColors.accent,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
