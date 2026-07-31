import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class PracticeReviewJustificationSource {
  const PracticeReviewJustificationSource({
    this.title,
    this.sourceUrl,
    this.snippet,
    this.pageNumber,
    this.isPrimary = false,
  });

  final String? title;
  final String? sourceUrl;
  final String? snippet;
  final int? pageNumber;
  final bool isPrimary;
}

class PracticeReviewJustificationPanel extends StatefulWidget {
  const PracticeReviewJustificationPanel({
    super.key,
    required this.title,
    required this.expandHint,
    required this.text,
    required this.sources,
    required this.pageLabel,
  });

  final String title;
  final String expandHint;
  final String text;
  final List<PracticeReviewJustificationSource> sources;
  final String Function(int page) pageLabel;

  @override
  State<PracticeReviewJustificationPanel> createState() =>
      _PracticeReviewJustificationPanelState();
}

class _PracticeReviewJustificationPanelState
    extends State<PracticeReviewJustificationPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.accentGold,
          fontWeight: FontWeight.w800,
        );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.35),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: titleStyle),
                          if (!_expanded) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.expandHint,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.accentGold,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.35),
                  ),
                  ...widget.sources.map((s) {
                    if (s.pageNumber == null &&
                        (s.snippet == null || s.snippet!.isEmpty)) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        s.pageNumber != null
                            ? widget.pageLabel(s.pageNumber!)
                            : s.snippet!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
