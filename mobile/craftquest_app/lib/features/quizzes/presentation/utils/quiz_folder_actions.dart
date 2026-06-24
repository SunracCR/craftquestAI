import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/features/quizzes/data/models/quiz_models.dart';
import 'package:craftquest_app/features/quizzes/data/quiz_repository.dart';
import 'package:craftquest_app/features/quizzes/presentation/utils/quiz_folder_tree.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

Future<String?> showQuizFolderNameDialog({
  required BuildContext context,
  required String title,
  String? initialValue,
  String? hint,
}) async {
  final controller = TextEditingController(text: initialValue ?? '');
  final l10n = AppLocalizations.of(context)!;

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 160,
        decoration: InputDecoration(
          hintText: hint ?? l10n.quizFolderNameHint,
        ),
        onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: Text(l10n.profileSaveAction),
        ),
      ],
    ),
  );

  controller.dispose();
  if (result == null || result.isEmpty) return null;
  return result;
}

Future<bool> confirmDeleteQuizFolder({
  required BuildContext context,
  required String folderName,
  required int quizCount,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.quizFolderDeleteConfirmTitle),
      content: Text(
        quizCount > 0
            ? l10n.quizFolderDeleteConfirmWithQuizzes(folderName, quizCount)
            : l10n.quizFolderDeleteConfirmMessage(folderName),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.deleteQuestionAction),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<String?> showMoveQuizFolderPicker({
  required BuildContext context,
  required List<QuizFolderModel> folders,
  required List<QuizFolderNode> folderTree,
  String? currentFolderId,
  String? excludeFolderId,
}) async {
  final l10n = AppLocalizations.of(context)!;

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final options = <_FolderPickOption>[
        _FolderPickOption(
          id: '__uncategorized__',
          label: l10n.quizFolderUncategorized,
          depth: 0,
        ),
        ...flattenFolderTree(folderTree)
            .where((folder) => folder.quizFolderId != excludeFolderId)
            .map(
              (folder) => _FolderPickOption(
                id: folder.quizFolderId,
                label: folder.name,
                depth: folder.depth + 1,
              ),
            ),
      ];

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.quizFolderMoveQuizTitle,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final selected = option.id == '__uncategorized__'
                      ? currentFolderId == null
                      : currentFolderId == option.id;
                  return ListTile(
                    leading: Icon(
                      option.id == '__uncategorized__'
                          ? Icons.inbox_outlined
                          : Icons.folder_outlined,
                      color: AppColors.accentCool,
                    ),
                    title: Padding(
                      padding: EdgeInsets.only(left: option.depth * 16.0),
                      child: Text(option.label),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_rounded, color: AppColors.accent)
                        : null,
                    onTap: () => Navigator.pop(ctx, option.id),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _FolderPickOption {
  const _FolderPickOption({
    required this.id,
    required this.label,
    required this.depth,
  });

  final String id;
  final String label;
  final int depth;
}

Future<void> handleQuizFolderMutation({
  required BuildContext context,
  required Future<void> Function() action,
  required VoidCallback onSuccess,
}) async {
  try {
    await action();
    if (context.mounted) {
      onSuccess();
    }
  } on DioException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(DioErrorMapper.map(e))),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(DioErrorMapper.genericMessage())),
    );
  }
}

Future<void> createQuizFolderFlow({
  required BuildContext context,
  required QuizRepository repository,
  required VoidCallback onSuccess,
  String? parentFolderId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final name = await showQuizFolderNameDialog(
    context: context,
    title: parentFolderId == null
        ? l10n.quizFolderCreateTitle
        : l10n.quizFolderCreateSubfolderTitle,
  );
  if (name == null || !context.mounted) return;

  await handleQuizFolderMutation(
    context: context,
    action: () async {
      await repository.createFolder(
        name: name,
        parentFolderId: parentFolderId,
      );
    },
    onSuccess: onSuccess,
  );
}

Future<void> renameQuizFolderFlow({
  required BuildContext context,
  required QuizRepository repository,
  required QuizFolderModel folder,
  required VoidCallback onSuccess,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final name = await showQuizFolderNameDialog(
    context: context,
    title: l10n.quizFolderRenameTitle,
    initialValue: folder.name,
  );
  if (name == null || !context.mounted) return;

  await handleQuizFolderMutation(
    context: context,
    action: () async {
      await repository.renameFolder(
        folderId: folder.quizFolderId,
        name: name,
      );
    },
    onSuccess: onSuccess,
  );
}

Future<void> deleteQuizFolderFlow({
  required BuildContext context,
  required QuizRepository repository,
  required QuizFolderNode node,
  required VoidCallback onSuccess,
}) async {
  final confirmed = await confirmDeleteQuizFolder(
    context: context,
    folderName: node.folder.name,
    quizCount: countQuizzesInFolderSubtree(node),
  );
  if (!confirmed || !context.mounted) return;

  await handleQuizFolderMutation(
    context: context,
    action: () async {
      await repository.deleteFolder(node.folder.quizFolderId);
    },
    onSuccess: onSuccess,
  );
}

Future<void> moveQuizToFolderFlow({
  required BuildContext context,
  required QuizRepository repository,
  required QuizModel quiz,
  required List<QuizFolderModel> folders,
  required List<QuizFolderNode> folderTree,
  required VoidCallback onSuccess,
}) async {
  final picked = await showMoveQuizFolderPicker(
    context: context,
    folders: folders,
    folderTree: folderTree,
    currentFolderId: quiz.folderId,
  );
  if (picked == null || !context.mounted) return;

  await handleQuizFolderMutation(
    context: context,
    action: () async {
      if (picked == '__uncategorized__') {
        await repository.moveQuizToFolder(
          quizId: quiz.quizId,
          clearFolder: true,
        );
      } else {
        await repository.moveQuizToFolder(
          quizId: quiz.quizId,
          folderId: picked,
        );
      }
    },
    onSuccess: onSuccess,
  );
}
