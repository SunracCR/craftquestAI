import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Compact chapter row for custom / offline practice configurators.
class PracticeChapterOption {
  const PracticeChapterOption({
    required this.sectionId,
    required this.name,
    required this.questionCount,
  });

  final String sectionId;
  final String name;
  final int questionCount;
}

/// Checkbox grid for optional chapter filtering (2–4 columns by width).
class PracticeChapterSelectionGrid extends StatelessWidget {
  const PracticeChapterSelectionGrid({
    super.key,
    required this.chapters,
    required this.selectedSectionIds,
    required this.onSectionToggled,
    this.loading = false,
    this.onSelectAll,
    this.onClearAll,
  });

  final List<PracticeChapterOption> chapters;
  final Set<String> selectedSectionIds;
  final void Function(String sectionId, bool selected) onSectionToggled;
  final bool loading;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearAll;

  static int poolCountFromSections({
    required int totalQuestionCount,
    required List<PracticeChapterOption> chapters,
    required Set<String> selectedSectionIds,
  }) {
    if (chapters.isEmpty || selectedSectionIds.isEmpty) {
      return totalQuestionCount;
    }
    return chapters
        .where((s) => selectedSectionIds.contains(s.sectionId))
        .fold<int>(0, (sum, s) => sum + s.questionCount);
  }

  int _gridCrossAxisCount(double width) {
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (chapters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.prepPlusCustomPracticeSectionsTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (onSelectAll != null)
                TextButton(
                  onPressed: loading ? null : onSelectAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(l10n.prepPlusCustomPracticeSelectAll),
                ),
              if (onClearAll != null)
                TextButton(
                  onPressed: loading ? null : onClearAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(l10n.prepPlusCustomPracticeSelectNone),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = _gridCrossAxisCount(constraints.maxWidth);
              const spacing = AppSpacing.xs;
              final cellWidth =
                  (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                      crossAxisCount;

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: chapters.map((section) {
                      final selected =
                          selectedSectionIds.contains(section.sectionId);
                      final label =
                          '${section.name} · ${section.questionCount}';
                      return SizedBox(
                        width: cellWidth,
                        child: InkWell(
                          onTap: () => onSectionToggled(
                            section.sectionId,
                            !selected,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusSm),
                          child: Row(
                            children: [
                              Checkbox(
                                value: selected,
                                onChanged: (value) => onSectionToggled(
                                  section.sectionId,
                                  value ?? false,
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              Expanded(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
