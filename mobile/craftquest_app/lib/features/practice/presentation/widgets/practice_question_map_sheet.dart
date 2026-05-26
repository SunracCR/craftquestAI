import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_nav_status.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_nav_styles.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PracticeQuestionMapSheet extends StatefulWidget {
  const PracticeQuestionMapSheet({
    super.key,
    required this.currentIndex,
    required this.statuses,
    required this.onSelected,
    this.scrollController,
  });

  final int currentIndex;
  final List<PracticeQuestionNavStatus> statuses;
  final ValueChanged<int> onSelected;
  final ScrollController? scrollController;

  static Future<void> show(
    BuildContext context, {
    required int currentIndex,
    required List<PracticeQuestionNavStatus> statuses,
    required ValueChanged<int> onSelected,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final useSidePanel = width >= 720;

    if (useSidePanel) {
      return showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black54,
        pageBuilder: (dialogContext, _, __) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: AppColors.surface,
              child: SizedBox(
                width: 320,
                height: MediaQuery.sizeOf(dialogContext).height,
                child: PracticeQuestionMapSheet(
                  currentIndex: currentIndex,
                  statuses: statuses,
                  onSelected: (index) {
                    Navigator.of(dialogContext).pop();
                    onSelected(index);
                  },
                ),
              ),
            ),
          );
        },
      );
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.radiusMd)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          builder: (_, scrollController) {
            return PracticeQuestionMapSheet(
              currentIndex: currentIndex,
              statuses: statuses,
              scrollController: scrollController,
              onSelected: (index) {
                Navigator.of(sheetContext).pop();
                onSelected(index);
              },
            );
          },
        );
      },
    );
  }

  @override
  State<PracticeQuestionMapSheet> createState() => _PracticeQuestionMapSheetState();
}

class _PracticeQuestionMapSheetState extends State<PracticeQuestionMapSheet> {
  PracticeQuestionMapFilter _filter = PracticeQuestionMapFilter.all;

  List<int> get _filteredIndices {
    return List.generate(widget.statuses.length, (i) => i).where((index) {
      final status = widget.statuses[index];
      return switch (_filter) {
        PracticeQuestionMapFilter.all => true,
        PracticeQuestionMapFilter.pending =>
          status == PracticeQuestionNavStatus.pending,
        PracticeQuestionMapFilter.completed =>
          status == PracticeQuestionNavStatus.answered,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final indices = _filteredIndices;
    final crossAxisCount = MediaQuery.sizeOf(context).width >= 720 ? 4 : 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.practiceMapTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                color: AppColors.textSecondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.xs,
            children: [
              _FilterChip(
                label: l10n.practiceMapFilterAll,
                selected: _filter == PracticeQuestionMapFilter.all,
                onTap: () => setState(() => _filter = PracticeQuestionMapFilter.all),
              ),
              _FilterChip(
                label: l10n.practiceMapFilterPending,
                selected: _filter == PracticeQuestionMapFilter.pending,
                onTap: () =>
                    setState(() => _filter = PracticeQuestionMapFilter.pending),
              ),
              _FilterChip(
                label: l10n.practiceMapFilterCompleted,
                selected: _filter == PracticeQuestionMapFilter.completed,
                onTap: () =>
                    setState(() => _filter = PracticeQuestionMapFilter.completed),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: indices.isEmpty
              ? Center(
                  child: Text(
                    l10n.practiceMapEmptyFilter,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                )
              : GridView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: AppSpacing.xs,
                    crossAxisSpacing: AppSpacing.xs,
                    childAspectRatio: 1,
                  ),
                  itemCount: indices.length,
                  itemBuilder: (context, gridIndex) {
                    final index = indices[gridIndex];
                    final status = widget.statuses[index];
                    final isCurrent = index == widget.currentIndex;

                    return _MapCell(
                      number: index + 1,
                      status: status,
                      isCurrent: isCurrent,
                      tooltip: l10n.practiceQuestionNavTooltip(index + 1),
                      onTap: () => widget.onSelected(index),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.accent.withValues(alpha: 0.2),
      checkmarkColor: AppColors.accent,
      labelStyle: TextStyle(
        color: selected ? AppColors.accent : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      side: BorderSide(
        color: selected
            ? AppColors.accent
            : AppColors.textSecondary.withValues(alpha: 0.35),
      ),
      backgroundColor: AppColors.background,
    );
  }
}

class _MapCell extends StatelessWidget {
  const _MapCell({
    required this.number,
    required this.status,
    required this.isCurrent,
    required this.tooltip,
    required this.onTap,
  });

  final int number;
  final PracticeQuestionNavStatus status;
  final bool isCurrent;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = PracticeQuestionNavStyles.segmentFill(status);
    final background = switch (status) {
      PracticeQuestionNavStatus.answered => fill.withValues(alpha: 0.25),
      PracticeQuestionNavStatus.pending => AppColors.surface,
    };
    final foreground = switch (status) {
      PracticeQuestionNavStatus.answered => AppColors.accentMint,
      PracticeQuestionNavStatus.pending => AppColors.textSecondary,
    };
    final borderSide = isCurrent
        ? PracticeQuestionNavStyles.currentOutline(true)!
        : BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          );

    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          side: borderSide,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          child: Center(
            child: status == PracticeQuestionNavStatus.answered
                ? Icon(Icons.check, size: 20, color: foreground)
                : Text(
                    '$number',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                        ),
                  ),
          ),
        ),
      ),
    );
  }
}
