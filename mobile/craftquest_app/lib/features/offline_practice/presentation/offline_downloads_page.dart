import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_package_repository.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_sync_repository.dart';
import 'package:craftquest_app/features/offline_practice/domain/offline_sync_manager.dart';
import 'package:craftquest_app/features/offline_practice/presentation/cubit/offline_practice_session_cubit.dart';
import 'package:craftquest_app/features/offline_practice/presentation/offline_practice_session_page.dart';
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

  Future<void> _openOfflineQuiz(OfflineDownloadedQuizSummaryModel item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => OfflinePracticeSessionCubit(
            packageRepository: _repository,
            syncRepository: _syncRepository,
            quizId: item.quizId,
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
    return EdgeAwareScaffold(
      appBar: AppBar(
        title: const Text('Descargas offline'),
        actions: [
          IconButton(
            onPressed: _syncNow,
            tooltip: 'Sincronizar resultados',
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
                  retryLabel: 'Reintentar',
                  onRetry: _load,
                )
              : _items.isEmpty
                  ? const AppEmptyView(
                      icon: Icons.download_for_offline_outlined,
                      message:
                          'Sin descargas offline. Descarga cuestionarios desde el detalle del quiz (plan pago).',
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
                          final expired =
                              item.expiresAt.isBefore(DateTime.now().toUtc());
                          return Card(
                            child: ListTile(
                              title: Text(item.title),
                              subtitle: Text(
                                '${item.questionCount} preguntas · '
                                '${_formatBytes(item.totalBytes)} · '
                                'Media ${item.mediaReady}/${item.mediaTotal}',
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
                                  const PopupMenuItem(
                                    value: 'play',
                                    child: Text('Practicar offline'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Eliminar descarga'),
                                  ),
                                ],
                              ),
                              onTap: () => _openOfflineQuiz(item),
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
