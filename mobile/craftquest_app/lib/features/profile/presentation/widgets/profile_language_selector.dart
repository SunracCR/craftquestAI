import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Selector compacto de idioma con banderas (ES, US, PT).
class ProfileLanguageSelector extends StatelessWidget {
  const ProfileLanguageSelector({
    super.key,
    required this.currentLanguageCode,
    required this.onLanguageSelected,
  });

  final String currentLanguageCode;
  final ValueChanged<String> onLanguageSelected;

  static const _languageCodes = ['es', 'en', 'pt'];

  static String flagFor(String code) => switch (code) {
        'es' => '🇪🇸',
        'en' => '🇺🇸',
        'pt' => '🇵🇹',
        _ => '🌐',
      };

  String _label(AppLocalizations l10n, String code) => switch (code) {
        'es' => l10n.languageSpanish,
        'en' => l10n.languageEnglish,
        'pt' => l10n.languagePortuguese,
        _ => code,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppSectionCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          for (var i = 0; i < _languageCodes.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _LanguageChip(
                flag: flagFor(_languageCodes[i]),
                label: _label(l10n, _languageCodes[i]),
                selected: currentLanguageCode == _languageCodes[i],
                onTap: () => onLanguageSelected(_languageCodes[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentMint.withValues(alpha: 0.12)
                : AppColors.surfaceHighlight.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            border: Border.all(
              color: selected
                  ? AppColors.accentMint
                  : AppColors.textSecondary.withValues(alpha: 0.15),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag, style: const TextStyle(fontSize: 26, height: 1.1)),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected
                          ? AppColors.accentMint
                          : AppColors.textPrimary,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (selected) ...[
                const SizedBox(height: 4),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AppColors.accentMint,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
