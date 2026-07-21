import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/features/prep_plus/presentation/widgets/prep_plus_access_status_chip.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Cabecera compacta del detalle Prep+ (sin duplicar título del AppBar).
class PrepPlusItemHero extends StatefulWidget {
  const PrepPlusItemHero({
    super.key,
    required this.categoryName,
    required this.questionCount,
    this.description,
    this.tags = const [],
    required this.userAccessState,
    required this.canPractice,
    required this.isLifetimeAccess,
    this.accessExpiresAt,
    required this.formatDate,
    this.onCountdownTap,
  });

  final String categoryName;
  final int questionCount;
  final String? description;
  final List<String> tags;
  final String userAccessState;
  final bool canPractice;
  final bool isLifetimeAccess;
  final DateTime? accessExpiresAt;
  final String Function(DateTime date) formatDate;
  final VoidCallback? onCountdownTap;

  static const _maxVisibleTags = 4;

  @override
  State<PrepPlusItemHero> createState() => _PrepPlusItemHeroState();
}

class _PrepPlusItemHeroState extends State<PrepPlusItemHero> {
  bool _descriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final description = widget.description?.trim();
    final hasLongDescription =
        description != null && description.length > 140;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _metaLine(l10n),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PrepPlusAccessStatusChip(
            userAccessState: widget.userAccessState,
            canPractice: widget.canPractice,
            isLifetimeAccess: widget.isLifetimeAccess,
            accessExpiresAt: widget.accessExpiresAt,
            formatDate: widget.formatDate,
            onCountdownTap: widget.onCountdownTap,
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              maxLines: _descriptionExpanded ? null : 3,
              overflow: _descriptionExpanded ? null : TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            if (hasLongDescription && !_descriptionExpanded)
              TextButton(
                onPressed: () => setState(() => _descriptionExpanded = true),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.accentGold,
                ),
                child: Text(l10n.prepPlusExpandDescription),
              ),
          ],
          if (widget.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _TagsRow(tags: widget.tags),
          ],
        ],
      ),
    );
  }

  String _metaLine(AppLocalizations l10n) {
    final parts = <String>[];
    if (widget.categoryName.isNotEmpty) {
      parts.add(widget.categoryName);
    }
    parts.add(l10n.prepPlusQuestionCount(widget.questionCount));
    return parts.join(' · ');
  }
}

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final visible = tags.take(PrepPlusItemHero._maxVisibleTags).toList();
    final overflow = tags.length - visible.length;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final tag in visible)
          Chip(
            label: Text(tag, style: const TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.zero,
            side: BorderSide(
              color: AppColors.inputBorder.withValues(alpha: 0.5),
            ),
            backgroundColor: AppColors.surfaceSecondary.withValues(alpha: 0.25),
          ),
        if (overflow > 0)
          Chip(
            label: Text('+$overflow', style: const TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.zero,
            side: BorderSide(
              color: AppColors.inputBorder.withValues(alpha: 0.5),
            ),
            backgroundColor: AppColors.surfaceSecondary.withValues(alpha: 0.25),
          ),
      ],
    );
  }
}
