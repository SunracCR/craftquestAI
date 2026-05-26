import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/ai/data/ai_repository.dart';
import 'package:craftquest_app/features/ai/data/models/ai_job_summary_model.dart';
import 'package:craftquest_app/features/ai_generation/presentation/ai_generation_progress_page.dart';
import 'package:craftquest_app/features/ai_generation/presentation/widgets/ai_activity_tile.dart';
import 'package:craftquest_app/features/imports/data/models/import_models.dart';
import 'package:craftquest_app/features/imports/presentation/import_preview_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class AiActivityPage extends StatefulWidget {
  const AiActivityPage({super.key});

  @override
  State<AiActivityPage> createState() => _AiActivityPageState();
}

class _AiActivityPageState extends State<AiActivityPage> {
  final _repository = getIt<AiRepository>();
  List<AiJobSummaryModel>? _jobs;
  bool _loading = true;
  bool _clearing = false;
  String? _error;

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
      final jobs = await _repository.listJobs(filter: 'inbox');
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.map(e, AppLocalizations.of(context)!);
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

  bool get _hasClearableHistory {
    final jobs = _jobs ?? [];
    return jobs.any((j) => !j.isActive && !j.canOpenPreview);
  }

  Future<void> _confirmClearHistory() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHighlight,
        title: Text(l10n.aiActivityClearHistoryTitle),
        content: Text(l10n.aiActivityClearHistoryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.aiActivityClearHistoryAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _clearing = true);
    try {
      final removed = await _repository.clearInboxHistory();
      if (!mounted) return;
      context.showSuccessSnackBar(
        removed > 0
            ? l10n.aiActivityClearHistoryDone(removed)
            : l10n.aiActivityClearHistoryNothing,
      );
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } catch (_) {
      if (!mounted) return;
      context.showErrorSnackBar(DioErrorMapper.genericMessage());
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  void _openJob(AiJobSummaryModel job) {
    final l10n = AppLocalizations.of(context)!;

    if (job.canOpenPreview) {
      final importId = job.questionImportBatchId!;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ImportPreviewPage(
            importId: importId,
            quizTitle: job.studyMaterialTitle ?? l10n.aiGenerationUploadTitle,
            initialStatus: ImportStatusModel(
              importId: importId,
              status: 'ready_for_review',
              totalQuestionsDetected: 0,
              validQuestions: 0,
              questionsWithWarnings: 0,
              questionsWithErrors: 0,
            ),
            fromAiGeneration: true,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AiGenerationProgressPage(
          aiJobId: job.aiJobId,
          targetQuizId: job.targetQuizId,
          quizTitle: job.studyMaterialTitle ?? l10n.aiGenerationUploadTitle,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(
        title: l10n.aiActivityTitle,
        actions: [
          if (!_loading && _error == null && _hasClearableHistory)
            IconButton(
              tooltip: l10n.aiActivityClearHistoryAction,
              onPressed: _clearing ? null : _confirmClearHistory,
              icon: _clearing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: AppLoadingView())
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : _buildList(l10n),
    );
  }

  Widget _buildList(AppLocalizations l10n) {
    final jobs = _jobs ?? [];
    if (jobs.isEmpty) {
      return AppEmptyView(
        message: l10n.aiActivityEmpty,
        icon: Icons.inbox_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final job = jobs[index];
          return AiActivityTile(
            job: job,
            onTap: () => _openJob(job),
          );
        },
      ),
    );
  }
}
