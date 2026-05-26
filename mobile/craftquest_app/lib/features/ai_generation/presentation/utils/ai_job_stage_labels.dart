import 'package:craftquest_app/features/ai/data/models/ai_job_model.dart';
import 'package:craftquest_app/features/ai/data/models/ai_job_summary_model.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';

abstract final class AiJobStageLabels {
  static String stageLabel(AppLocalizations l10n, String? stage, String status) {
    if (status == 'failed') {
      return l10n.aiJobStageFailed;
    }
    if (status == 'completed') {
      return l10n.aiJobStageCompleted;
    }
    if (status == 'pending_retry') {
      return l10n.aiJobStageQueued;
    }

    return switch (stage) {
      'preparing' => l10n.aiJobStagePreparing,
      'outlining' => l10n.aiJobStageOutlining,
      'generating' => l10n.aiJobStageGenerating,
      'merging' => l10n.aiJobStageMerging,
      'validating' => l10n.aiJobStageValidating,
      'importing' => l10n.aiJobStageImporting,
      'queued' => l10n.aiJobStageQueued,
      _ => l10n.aiJobStageGenerating,
    };
  }

  static String inboxStatusLabel(AppLocalizations l10n, AiJobSummaryModel job) {
    if (job.isFailed) {
      return l10n.aiActivityStatusFailed;
    }
    if (job.canOpenPreview) {
      return l10n.aiActivityStatusDraftReady;
    }
    if (job.isActive) {
      return stageLabel(l10n, job.stage, job.status);
    }
    return l10n.aiActivityStatusCompleted;
  }

  static String? pageRangeLabel(AppLocalizations l10n, int? from, int? to) {
    if (from == null || to == null || from <= 0 || to < from) {
      return null;
    }
    return l10n.aiActivityPagesRange(from, to);
  }
}

extension AiJobModelStage on AiJobModel {
  String stageLabel(AppLocalizations l10n) =>
      AiJobStageLabels.stageLabel(l10n, stage, status);
}
