import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/features/quizzes/data/models/quiz_models.dart';
import 'package:craftquest_app/features/quizzes/presentation/utils/quiz_folder_tree.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

typedef QuizListItemBuilder = Widget Function(QuizModel quiz);

class QuizFolderGroupedList extends StatelessWidget {
  const QuizFolderGroupedList({
    super.key,
    required this.folders,
    required this.quizzes,
    required this.quizBuilder,
    this.scrollController,
    this.onFolderMenu,
    this.onQuizMove,
    this.initiallyExpandFolders = true,
    this.showUncategorizedSection = true,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.sm,
    ),
  });

  final List<QuizFolderModel> folders;
  final List<QuizModel> quizzes;
  final QuizListItemBuilder quizBuilder;
  final ScrollController? scrollController;
  final void Function(QuizFolderNode node)? onFolderMenu;
  final void Function(QuizModel quiz)? onQuizMove;
  final bool initiallyExpandFolders;
  final bool showUncategorizedSection;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tree = buildQuizFolderTree(folders: folders, quizzes: quizzes);
    final uncategorized = uncategorizedQuizzes(quizzes);

    if (folders.isEmpty) {
      return ListView.separated(
        controller: scrollController,
        padding: padding,
        itemCount: quizzes.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => quizBuilder(quizzes[index]),
      );
    }

    final sections = <Widget>[
      for (final node in tree)
        _FolderSection(
          node: node,
          initiallyExpanded: initiallyExpandFolders,
          quizBuilder: quizBuilder,
          onFolderMenu: onFolderMenu,
          onQuizMove: onQuizMove,
        ),
      if (showUncategorizedSection && uncategorized.isNotEmpty)
        _UncategorizedSection(
          title: l10n.quizFolderUncategorized,
          quizzes: uncategorized,
          initiallyExpanded: initiallyExpandFolders,
          quizBuilder: quizBuilder,
          onQuizMove: onQuizMove,
        ),
    ];

    if (sections.isEmpty && quizzes.isEmpty) {
      return ListView(
        controller: scrollController,
        padding: padding,
        children: [
          Text(
            l10n.quizzesEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    return ListView(
      controller: scrollController,
      padding: padding,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          sections[i],
        ],
      ],
    );
  }
}

class _FolderSection extends StatelessWidget {
  const _FolderSection({
    required this.node,
    required this.initiallyExpanded,
    required this.quizBuilder,
    this.onFolderMenu,
    this.onQuizMove,
  });

  final QuizFolderNode node;
  final bool initiallyExpanded;
  final QuizListItemBuilder quizBuilder;
  final void Function(QuizFolderNode node)? onFolderMenu;
  final void Function(QuizModel quiz)? onQuizMove;

  @override
  Widget build(BuildContext context) {
    final totalCount = countQuizzesInFolderSubtree(node);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: const Icon(Icons.folder_rounded, color: AppColors.accentCool),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  node.folder.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (onFolderMenu != null)
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onFolderMenu!(node),
                ),
            ],
          ),
          subtitle: Text('$totalCount'),
          children: [
            for (final child in node.children)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: _FolderSection(
                  node: child,
                  initiallyExpanded: initiallyExpanded,
                  quizBuilder: quizBuilder,
                  onFolderMenu: onFolderMenu,
                  onQuizMove: onQuizMove,
                ),
              ),
            for (final quiz in node.quizzes)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: _QuizTileWrapper(
                  quiz: quiz,
                  onQuizMove: onQuizMove,
                  child: quizBuilder(quiz),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UncategorizedSection extends StatelessWidget {
  const _UncategorizedSection({
    required this.title,
    required this.quizzes,
    required this.initiallyExpanded,
    required this.quizBuilder,
    this.onQuizMove,
  });

  final String title;
  final List<QuizModel> quizzes;
  final bool initiallyExpanded;
  final QuizListItemBuilder quizBuilder;
  final void Function(QuizModel quiz)? onQuizMove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: const Icon(Icons.inbox_outlined, color: AppColors.textSecondary),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text('${quizzes.length}'),
          children: [
            for (final quiz in quizzes)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: _QuizTileWrapper(
                  quiz: quiz,
                  onQuizMove: onQuizMove,
                  child: quizBuilder(quiz),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuizTileWrapper extends StatelessWidget {
  const _QuizTileWrapper({
    required this.quiz,
    required this.child,
    this.onQuizMove,
  });

  final QuizModel quiz;
  final Widget child;
  final void Function(QuizModel quiz)? onQuizMove;

  @override
  Widget build(BuildContext context) {
    if (onQuizMove == null) {
      return child;
    }

    return GestureDetector(
      onLongPress: () => onQuizMove!(quiz),
      child: child,
    );
  }
}

Future<void> showQuizFolderOptionsSheet({
  required BuildContext context,
  required QuizFolderNode node,
  required VoidCallback onRename,
  required VoidCallback onDelete,
  VoidCallback? onCreateSubfolder,
}) async {
  final l10n = AppLocalizations.of(context)!;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline_rounded),
            title: Text(l10n.quizFolderRenameAction),
            onTap: () {
              Navigator.pop(ctx);
              onRename();
            },
          ),
          if (onCreateSubfolder != null && node.folder.canHaveSubfolders)
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: Text(l10n.quizFolderCreateSubfolderAction),
              onTap: () {
                Navigator.pop(ctx);
                onCreateSubfolder();
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            title: Text(
              l10n.quizFolderDeleteAction,
              style: const TextStyle(color: AppColors.error),
            ),
            onTap: () {
              Navigator.pop(ctx);
              onDelete();
            },
          ),
        ],
      ),
    ),
  );
}
