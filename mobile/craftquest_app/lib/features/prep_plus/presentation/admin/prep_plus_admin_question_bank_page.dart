import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_question_bank_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_admin_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class PrepPlusAdminQuestionBankPage extends StatefulWidget {
  const PrepPlusAdminQuestionBankPage({
    super.key,
    required this.catalogItemId,
    required this.displayTitle,
  });

  final String catalogItemId;
  final String displayTitle;

  @override
  State<PrepPlusAdminQuestionBankPage> createState() =>
      _PrepPlusAdminQuestionBankPageState();
}

class _PrepPlusAdminQuestionBankPageState
    extends State<PrepPlusAdminQuestionBankPage> {
  final _repo = getIt<PrepPlusAdminRepository>();
  PrepAdminQuestionBankModel? _bank;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bank = await _repo.getQuestionBank(widget.catalogItemId);
      if (!mounted) return;
      setState(() {
        _bank = bank;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _repo.mapError(e, AppLocalizations.of(context));
        _loading = false;
      });
    }
  }

  Future<void> _createSection() async {
    final l10n = AppLocalizations.of(context)!;
    final name = await _promptText(l10n.prepAdminQuestionBankSectionName);
    if (name == null || name.trim().isEmpty) return;
    await _runSaving(() async {
      await _repo.createSection(widget.catalogItemId, {
        'name': name.trim(),
        'sortOrder': (_bank?.sections.length ?? 0) + 1,
      });
    });
  }

  Future<void> _createTopic(PrepAdminQuizSectionModel section) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await _promptText(l10n.prepAdminQuestionBankTopicName);
    if (name == null || name.trim().isEmpty) return;
    await _runSaving(() async {
      await _repo.createTopic(widget.catalogItemId, {
        'sectionId': section.sectionId,
        'name': name.trim(),
        'sortOrder': section.topics.length + 1,
      });
    });
  }

  Future<void> _toggleCustomPractice(bool value) async {
    await _runSaving(() async {
      await _repo.setCustomPractice(widget.catalogItemId, value);
    });
  }

  Future<void> _assignQuestion(PrepAdminQuestionBankQuestionModel question) async {
    final bank = _bank;
    if (bank == null) return;
    final l10n = AppLocalizations.of(context)!;

    String? sectionId = question.sectionId;
    String? topicId = question.topicId;
    String? difficulty = question.difficulty;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedSection = bank.sections
                .where((s) => s.sectionId == sectionId)
                .cast<PrepAdminQuizSectionModel?>()
                .firstOrNull;
            final topics = selectedSection?.topics ?? const [];

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.prepAdminQuestionBankAssignTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String?>(
                    value: sectionId,
                    decoration: InputDecoration(
                      labelText: l10n.prepAdminQuestionBankSectionLabel,
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.prepAdminQuestionBankUnassigned),
                      ),
                      ...bank.sections.map(
                        (s) => DropdownMenuItem(
                          value: s.sectionId,
                          child: Text(s.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        sectionId = value;
                        topicId = null;
                      });
                    },
                  ),
                  if (topics.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String?>(
                      value: topicId,
                      decoration: InputDecoration(
                        labelText: l10n.prepAdminQuestionBankTopicLabel,
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(l10n.prepAdminQuestionBankNoTopic),
                        ),
                        ...topics.map(
                          (t) => DropdownMenuItem(
                            value: t.topicId,
                            child: Text(t.name),
                          ),
                        ),
                      ],
                      onChanged: sectionId == null
                          ? null
                          : (value) => setModalState(() => topicId = value),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String?>(
                    value: difficulty,
                    decoration: InputDecoration(
                      labelText: l10n.prepAdminQuestionBankDifficultyLabel,
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.prepAdminQuestionBankNoDifficulty),
                      ),
                      DropdownMenuItem(
                        value: 'easy',
                        child: Text(l10n.prepPlusCustomPracticeDifficultyEasy),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text(l10n.prepPlusCustomPracticeDifficultyMedium),
                      ),
                      DropdownMenuItem(
                        value: 'hard',
                        child: Text(l10n.prepPlusCustomPracticeDifficultyHard),
                      ),
                    ],
                    onChanged: (value) =>
                        setModalState(() => difficulty = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.prepAdminQuestionBankSaveAssignment),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (saved != true) return;

    await _runSaving(() async {
      await _repo.bulkTagQuestions(widget.catalogItemId, [
        {
          'questionId': question.questionId,
          'sectionId': sectionId,
          'topicId': topicId,
          'difficulty': difficulty,
        },
      ]);
    });
  }

  Future<void> _runSaving(Future<void> Function() action) async {
    setState(() => _saving = true);
    try {
      await action();
      await _load();
      if (mounted) {
        context.showSuccessSnackBar(
          AppLocalizations.of(context)!.prepAdminQuestionBankSaved,
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        context.showErrorSnackBar(_repo.mapError(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _promptText(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.prepAdminQuestionBankNameHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(l10n.prepAdminQuestionBankSaveAction),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bank = _bank;

    return EdgeAwareScaffold(
      appBar: AppBar(
        title: Text(l10n.prepAdminQuestionBankTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  onRetry: _load,
                  retryLabel: l10n.retry,
                )
              : bank == null
                  ? const SizedBox.shrink()
                  : Stack(
                      children: [
                        ListView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          children: [
                            Text(
                              widget.displayTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SwitchListTile(
                              title: Text(l10n.prepAdminQuestionBankEnableCustom),
                              subtitle: Text(
                                l10n.prepAdminQuestionBankEnableCustomHint,
                              ),
                              value: bank.supportsCustomPractice,
                              onChanged: _saving ? null : _toggleCustomPractice,
                            ),
                            if (bank.untaggedQuestionCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Text(
                                  l10n.prepAdminQuestionBankUntaggedCount(
                                    bank.untaggedQuestionCount,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.prepAdminQuestionBankSectionsTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _saving ? null : _createSection,
                                  icon: const Icon(Icons.add),
                                  label: Text(l10n.prepAdminQuestionBankAddSection),
                                ),
                              ],
                            ),
                            ...bank.sections.map((section) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: AppSectionCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ListTile(
                                      title: Text(section.name),
                                      subtitle: Text(
                                        l10n.prepPlusCustomPracticeSectionCount(
                                          section.questionCount,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: _saving
                                            ? null
                                            : () async {
                                                await _runSaving(() async {
                                                  await _repo.deleteSection(
                                                    widget.catalogItemId,
                                                    section.sectionId,
                                                  );
                                                });
                                              },
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: _saving
                                            ? null
                                            : () => _createTopic(section),
                                        icon: const Icon(Icons.add),
                                        label: Text(
                                          l10n.prepAdminQuestionBankAddTopic,
                                        ),
                                      ),
                                    ),
                                    ...section.topics.map(
                                      (topic) => ListTile(
                                        dense: true,
                                        title: Text('  ${topic.name}'),
                                        subtitle: Text(
                                          l10n.prepPlusCustomPracticeTopicCount(
                                            topic.questionCount,
                                          ),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          onPressed: _saving
                                              ? null
                                              : () async {
                                                  await _runSaving(() async {
                                                    await _repo.deleteTopic(
                                                      widget.catalogItemId,
                                                      topic.topicId,
                                                    );
                                                  });
                                                },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              );
                            }),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.prepAdminQuestionBankQuestionsTitle,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...bank.questions.map((question) {
                              final sectionName = bank.sections
                                  .where((s) => s.sectionId == question.sectionId)
                                  .map((s) => s.name)
                                  .firstOrNull;
                              return ListTile(
                                title: Text(question.promptPreview),
                                subtitle: Text(
                                  [
                                    if (sectionName != null) sectionName,
                                    if (question.difficulty != null)
                                      question.difficulty!,
                                  ].join(' · '),
                                ),
                                trailing: const Icon(Icons.label_outline),
                                onTap: _saving ? null : () => _assignQuestion(question),
                              );
                            }),
                          ],
                        ),
                        if (_saving)
                          const ColoredBox(
                            color: Color(0x33FFFFFF),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
    );
  }
}
