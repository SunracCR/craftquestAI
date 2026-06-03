import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/features/quizzes/data/models/quiz_models.dart';
import 'package:craftquest_app/features/quizzes/data/quiz_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

Future<List<String>?> showPrepSamplePickerSheet(
  BuildContext context, {
  required String quizId,
  required List<String> initialSelectedIds,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PrepSamplePickerSheet(
      quizId: quizId,
      initialSelectedIds: initialSelectedIds,
    ),
  );
}

class _PrepSamplePickerSheet extends StatefulWidget {
  const _PrepSamplePickerSheet({
    required this.quizId,
    required this.initialSelectedIds,
  });

  final String quizId;
  final List<String> initialSelectedIds;

  @override
  State<_PrepSamplePickerSheet> createState() => _PrepSamplePickerSheetState();
}

class _PrepSamplePickerSheetState extends State<_PrepSamplePickerSheet> {
  final _quizRepo = getIt<QuizRepository>();
  List<QuestionModel> _questions = [];
  late Set<String> _selected;
  bool _loading = true;
  String? _error;

  static const requiredCount = 3;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelectedIds.toSet();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final questions = await _quizRepo.getQuestions(widget.quizId);
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loading = false;
      });
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.prepAdminSamplesLoadError;
        _loading = false;
      });
    }
  }

  void _toggle(String questionId, bool? checked) {
    setState(() {
      if (checked == true) {
        if (_selected.length >= requiredCount) return;
        _selected.add(questionId);
      } else {
        _selected.remove(questionId);
      }
    });
  }

  void _confirm() {
    final l10n = AppLocalizations.of(context)!;
    if (_selected.length != requiredCount) {
      context.showErrorSnackBar(l10n.prepAdminSamplesCountError);
      return;
    }
    Navigator.pop(context, _selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.prepAdminSamplesPickerTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.prepAdminSamplesPickerSubtitle(
                      _selected.length,
                      requiredCount,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const AppLoadingView()
                  : _error != null
                      ? AppErrorView(
                          message: _error!,
                          retryLabel: l10n.retry,
                          onRetry: _load,
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            final q = _questions[index];
                            final checked = _selected.contains(q.questionId);
                            final disabled =
                                !checked && _selected.length >= requiredCount;
                            return CheckboxListTile(
                              value: checked,
                              onChanged: disabled
                                  ? null
                                  : (v) => _toggle(q.questionId, v),
                              title: Text(
                                q.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                l10n.prepPlusPreviewQuestionLabel(index + 1),
                              ),
                            );
                          },
                        ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: _confirm,
                        child: Text(l10n.profileSaveAction),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
