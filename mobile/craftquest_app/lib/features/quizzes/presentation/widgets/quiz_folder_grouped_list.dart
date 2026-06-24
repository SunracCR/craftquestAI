import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/features/quizzes/data/models/quiz_models.dart';
import 'package:craftquest_app/features/quizzes/presentation/utils/quiz_folder_tree.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

typedef QuizListItemBuilder = Widget Function(QuizModel quiz);

class QuizFolderGroupedList extends StatefulWidget {
  const QuizFolderGroupedList({
    super.key,
    required this.folders,
    required this.quizzes,
    required this.quizBuilder,
    this.scrollController,
    this.onFolderMenu,
    this.onQuizMove,
    this.onReparentFolder,
    this.onReassignQuiz,
    this.initiallyExpandFolders = false,
    this.showUncategorizedSection = true,
    this.enableDrag = false,
    this.searchQuery = '',
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
  final void Function(QuizFolderModel folder, String? newParentId)? onReparentFolder;
  final void Function(QuizModel quiz, String? folderId)? onReassignQuiz;
  final bool initiallyExpandFolders;
  final bool showUncategorizedSection;
  final bool enableDrag;
  final String searchQuery;
  final EdgeInsets padding;

  @override
  State<QuizFolderGroupedList> createState() => _QuizFolderGroupedListState();
}

class _QuizFolderGroupedListState extends State<QuizFolderGroupedList> {
  QuizDragData? _dragging;
  String? _hoverFolderId;
  bool _hoverRoot = false;

  void _setDragging(QuizDragData? data) {
    if (!widget.enableDrag) return;
    setState(() {
      _dragging = data;
      if (data == null) {
        _hoverFolderId = null;
        _hoverRoot = false;
      }
    });
  }

  void _setHoverFolder(String? folderId) {
    if (!widget.enableDrag || _dragging == null) return;
    setState(() {
      _hoverFolderId = folderId;
      if (folderId != null) {
        _hoverRoot = false;
      }
    });
  }

  void _setHoverRoot(bool hover) {
    if (!widget.enableDrag || _dragging == null) return;
    setState(() {
      _hoverRoot = hover;
      if (hover) {
        _hoverFolderId = null;
      }
    });
  }

  bool _canAcceptDrop(String? targetFolderId) {
    final dragging = _dragging;
    if (dragging == null) return false;

    return switch (dragging) {
      QuizFolderDrag(:final folder) => canDropFolderInto(
          folders: widget.folders,
          dragFolderId: folder.quizFolderId,
          targetFolderId: targetFolderId,
        ),
      QuizItemDrag(:final quiz) => canDropQuizInto(
          quiz: quiz,
          targetFolderId: targetFolderId,
        ),
    };
  }

  void _handleDrop(String? targetFolderId) {
    final dragging = _dragging;
    if (dragging == null || !_canAcceptDrop(targetFolderId)) {
      return;
    }

    switch (dragging) {
      case QuizFolderDrag(:final folder):
        widget.onReparentFolder?.call(folder, targetFolderId);
      case QuizItemDrag(:final quiz):
        widget.onReassignQuiz?.call(quiz, targetFolderId);
    }
    _setDragging(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = widget.searchQuery.trim();

    if (query.isNotEmpty) {
      return _buildSearchResults(context, l10n, query);
    }

    if (widget.folders.isEmpty) {
      return ListView.separated(
        controller: widget.scrollController,
        padding: widget.padding,
        itemCount: widget.quizzes.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => widget.quizBuilder(widget.quizzes[index]),
      );
    }

    final tree = buildQuizFolderTree(
      folders: widget.folders,
      quizzes: widget.quizzes,
    );
    final uncategorized = uncategorizedQuizzes(widget.quizzes);

    final sections = <Widget>[
      if (widget.enableDrag && _dragging != null)
        _RootDropZone(
          label: l10n.quizFolderDropToRoot,
          isActive: _canAcceptDrop(null),
          isHovered: _hoverRoot,
          onWillAccept: (_) {
            _setHoverRoot(true);
            return _canAcceptDrop(null);
          },
          onLeave: (_) => _setHoverRoot(false),
          onAccept: (_) => _handleDrop(null),
        ),
      for (final node in tree)
        _FolderSection(
          key: ValueKey(node.folder.quizFolderId),
          node: node,
          folders: widget.folders,
          initiallyExpanded: widget.initiallyExpandFolders,
          quizBuilder: widget.quizBuilder,
          onFolderMenu: widget.onFolderMenu,
          onQuizMove: widget.onQuizMove,
          enableDrag: widget.enableDrag,
          dragging: _dragging,
          hoverFolderId: _hoverFolderId,
          canAcceptDrop: _canAcceptDrop,
          onDragStarted: _setDragging,
          onDragEnded: () => _setDragging(null),
          onHoverFolder: _setHoverFolder,
          onDrop: _handleDrop,
          onReparentFolder: widget.onReparentFolder,
          onReassignQuiz: widget.onReassignQuiz,
        ),
      if (widget.showUncategorizedSection && uncategorized.isNotEmpty)
        _UncategorizedSection(
          key: const ValueKey('__uncategorized__'),
          title: l10n.quizFolderUncategorized,
          quizzes: uncategorized,
          initiallyExpanded: widget.initiallyExpandFolders,
          quizBuilder: widget.quizBuilder,
          onQuizMove: widget.onQuizMove,
          enableDrag: widget.enableDrag,
          dragging: _dragging,
          canAcceptDrop: _canAcceptDrop,
          onDragStarted: _setDragging,
          onDragEnded: () => _setDragging(null),
          onDrop: _handleDrop,
        ),
    ];

    if (sections.length == (widget.enableDrag && _dragging != null ? 1 : 0) &&
        widget.quizzes.isEmpty) {
      return ListView(
        controller: widget.scrollController,
        padding: widget.padding,
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
      controller: widget.scrollController,
      padding: widget.padding,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          sections[i],
        ],
      ],
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    AppLocalizations l10n,
    String query,
  ) {
    final results = filterQuizzesBySearch(quizzes: widget.quizzes, query: query);

    if (results.isEmpty) {
      return ListView(
        controller: widget.scrollController,
        padding: widget.padding,
        children: [
          Text(
            l10n.quizSearchNoResults,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: widget.scrollController,
      padding: widget.padding,
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final quiz = results[index];
        final path = folderPathLabel(
          folders: widget.folders,
          folderId: quiz.folderId,
          uncategorizedLabel: l10n.quizFolderUncategorized,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xs,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                path,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            widget.quizBuilder(quiz),
          ],
        );
      },
    );
  }
}

class _RootDropZone extends StatelessWidget {
  const _RootDropZone({
    required this.label,
    required this.isActive,
    required this.isHovered,
    required this.onWillAccept,
    required this.onLeave,
    required this.onAccept,
  });

  final String label;
  final bool isActive;
  final bool isHovered;
  final bool Function(QuizDragData? data) onWillAccept;
  final void Function(QuizDragData? data) onLeave;
  final void Function(QuizDragData data) onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<QuizDragData>(
      onWillAcceptWithDetails: (details) => onWillAccept(details.data),
      onLeave: onLeave,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        final highlight = isHovered && isActive;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: highlight
                ? AppColors.accentCool.withValues(alpha: 0.2)
                : AppColors.surfaceHighlight,
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            border: Border.all(
              color: highlight ? AppColors.accentCool : AppColors.inputBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.vertical_align_top_outlined,
                color: highlight ? AppColors.accentCool : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: highlight
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FolderSection extends StatelessWidget {
  const _FolderSection({
    super.key,
    required this.node,
    required this.folders,
    required this.initiallyExpanded,
    required this.quizBuilder,
    this.onFolderMenu,
    this.onQuizMove,
    this.enableDrag = false,
    this.dragging,
    this.hoverFolderId,
    required this.canAcceptDrop,
    this.onDragStarted,
    this.onDragEnded,
    this.onHoverFolder,
    this.onDrop,
    this.onReparentFolder,
    this.onReassignQuiz,
  });

  final QuizFolderNode node;
  final List<QuizFolderModel> folders;
  final bool initiallyExpanded;
  final QuizListItemBuilder quizBuilder;
  final void Function(QuizFolderNode node)? onFolderMenu;
  final void Function(QuizModel quiz)? onQuizMove;
  final bool enableDrag;
  final QuizDragData? dragging;
  final String? hoverFolderId;
  final bool Function(String? targetFolderId) canAcceptDrop;
  final void Function(QuizDragData data)? onDragStarted;
  final VoidCallback? onDragEnded;
  final void Function(String? folderId)? onHoverFolder;
  final void Function(String? targetFolderId)? onDrop;
  final void Function(QuizFolderModel folder, String? newParentId)? onReparentFolder;
  final void Function(QuizModel quiz, String? folderId)? onReassignQuiz;

  @override
  Widget build(BuildContext context) {
    final totalCount = countQuizzesInFolderSubtree(node);
    final depthColor = AppColors.quizFolderColor(node.folder.depth);
    final isHovered = hoverFolderId == node.folder.quizFolderId;
    final canAccept = canAcceptDrop(node.folder.quizFolderId);

    Widget header = ExpansionTile(
      key: ValueKey('expansion-${node.folder.quizFolderId}'),
      initiallyExpanded: initiallyExpanded,
      leading: Icon(Icons.folder_rounded, color: depthColor),
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
              key: ValueKey(child.folder.quizFolderId),
              node: child,
              folders: folders,
              initiallyExpanded: initiallyExpanded,
              quizBuilder: quizBuilder,
              onFolderMenu: onFolderMenu,
              onQuizMove: onQuizMove,
              enableDrag: enableDrag,
              dragging: dragging,
              hoverFolderId: hoverFolderId,
              canAcceptDrop: canAcceptDrop,
              onDragStarted: onDragStarted,
              onDragEnded: onDragEnded,
              onHoverFolder: onHoverFolder,
              onDrop: onDrop,
              onReparentFolder: onReparentFolder,
              onReassignQuiz: onReassignQuiz,
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
              enableDrag: enableDrag,
              onDragStarted: onDragStarted,
              onDragEnded: onDragEnded,
              onQuizMove: onQuizMove,
              child: quizBuilder(quiz),
            ),
          ),
      ],
    );

    if (enableDrag) {
      header = LongPressDraggable<QuizDragData>(
        data: QuizFolderDrag(node.folder),
        feedback: _DragFeedbackChip(
          label: node.folder.name,
          color: depthColor,
          icon: Icons.folder_rounded,
        ),
        onDragStarted: () => onDragStarted?.call(QuizFolderDrag(node.folder)),
        onDragEnd: (_) => onDragEnded?.call(),
        childWhenDragging: Opacity(opacity: 0.45, child: header),
        child: header,
      );
    }

    return DragTarget<QuizDragData>(
      onWillAcceptWithDetails: (details) {
        onHoverFolder?.call(node.folder.quizFolderId);
        return canAcceptDrop(node.folder.quizFolderId);
      },
      onLeave: (_) => onHoverFolder?.call(null),
      onAcceptWithDetails: (_) => onDrop?.call(node.folder.quizFolderId),
      builder: (context, candidate, rejected) {
        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            side: BorderSide(
              color: isHovered && canAccept
                  ? depthColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: depthColor, width: 4),
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: header,
            ),
          ),
        );
      },
    );
  }
}

class _UncategorizedSection extends StatelessWidget {
  const _UncategorizedSection({
    super.key,
    required this.title,
    required this.quizzes,
    required this.initiallyExpanded,
    required this.quizBuilder,
    this.onQuizMove,
    this.enableDrag = false,
    this.dragging,
    required this.canAcceptDrop,
    this.onDragStarted,
    this.onDragEnded,
    this.onDrop,
  });

  final String title;
  final List<QuizModel> quizzes;
  final bool initiallyExpanded;
  final QuizListItemBuilder quizBuilder;
  final void Function(QuizModel quiz)? onQuizMove;
  final bool enableDrag;
  final QuizDragData? dragging;
  final bool Function(String? targetFolderId) canAcceptDrop;
  final void Function(QuizDragData data)? onDragStarted;
  final VoidCallback? onDragEnded;
  final void Function(String? targetFolderId)? onDrop;

  @override
  Widget build(BuildContext context) {
    final tile = ExpansionTile(
      key: const ValueKey('expansion-uncategorized'),
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
              enableDrag: enableDrag,
              onDragStarted: onDragStarted,
              onDragEnded: onDragEnded,
              onQuizMove: onQuizMove,
              child: quizBuilder(quiz),
            ),
          ),
      ],
    );

    if (!enableDrag) {
      return Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: tile,
        ),
      );
    }

    return DragTarget<QuizDragData>(
      onWillAcceptWithDetails: (details) => canAcceptDrop(null),
      onAcceptWithDetails: (_) => onDrop?.call(null),
      builder: (context, candidate, rejected) {
        final highlight = candidate.isNotEmpty && canAcceptDrop(null);
        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            side: BorderSide(
              color: highlight ? AppColors.textSecondary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: tile,
          ),
        );
      },
    );
  }
}

class _QuizTileWrapper extends StatelessWidget {
  const _QuizTileWrapper({
    required this.quiz,
    required this.child,
    this.onQuizMove,
    this.enableDrag = false,
    this.onDragStarted,
    this.onDragEnded,
  });

  final QuizModel quiz;
  final Widget child;
  final void Function(QuizModel quiz)? onQuizMove;
  final bool enableDrag;
  final void Function(QuizDragData data)? onDragStarted;
  final VoidCallback? onDragEnded;

  @override
  Widget build(BuildContext context) {
    if (!enableDrag) {
      if (onQuizMove == null) {
        return child;
      }
      return GestureDetector(
        onLongPress: () => onQuizMove!(quiz),
        child: child,
      );
    }

    return LongPressDraggable<QuizDragData>(
      data: QuizItemDrag(quiz),
      feedback: _DragFeedbackChip(
        label: quiz.title,
        color: AppColors.accent,
        icon: Icons.quiz_outlined,
      ),
      onDragStarted: () => onDragStarted?.call(QuizItemDrag(quiz)),
      onDragEnd: (_) => onDragEnded?.call(),
      childWhenDragging: Opacity(opacity: 0.45, child: child),
      child: child,
    );
  }
}

class _DragFeedbackChip extends StatelessWidget {
  const _DragFeedbackChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(AppColors.radiusSm),
      color: AppColors.surfaceHighlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
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
