import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrepPlusAccessComboCard extends StatelessWidget {
  const PrepPlusAccessComboCard({
    super.key,
    required this.offer,
    required this.selected,
    required this.onTap,
    this.showBestValueBadge = false,
  });

  final PrepAccessOfferModel offer;
  final bool selected;
  final VoidCallback onTap;
  final bool showBestValueBadge;

  static const _bestValueDays = 183;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final priceText = offer.isFree
        ? l10n.prepPlusFilterFree
        : NumberFormat.simpleCurrency(name: offer.currencyCode, locale: locale)
            .format(offer.priceAmount);
    final perDay = offer.isFree || offer.isLifetimeAccess || offer.durationDays <= 0
        ? null
        : offer.priceAmount / offer.durationDays;
    final perDayText = perDay == null
        ? null
        : l10n.prepPlusPricePerDay(
            NumberFormat.simpleCurrency(name: offer.currencyCode, locale: locale)
                .format(perDay),
          );

    final borderColor = selected ? AppColors.accentGold : AppColors.inputBorder;
    final fill = selected
        ? AppColors.accentGold.withValues(alpha: 0.08)
        : AppColors.surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          side: BorderSide(
            color: borderColor,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: selected
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accentGold.withValues(alpha: 0.14),
                        Colors.transparent,
                      ],
                    ),
                  )
                : null,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.accentGold : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              offer.isLifetimeAccess
                                  ? l10n.prepPlusAccessLifetime
                                  : _durationLabel(l10n, offer.durationDays),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!offer.isLifetimeAccess &&
                              (showBestValueBadge ||
                                  offer.durationDays == _bestValueDays))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.accentGold.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                l10n.prepPlusBestValueBadge,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentGold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        offer.isLifetimeAccess
                            ? l10n.prepPlusAccessLifetimeSubtitle
                            : l10n.prepPlusComboIncludesAccess,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (perDayText != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          perDayText,
                          style: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? AppColors.accentMint
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      priceText,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: offer.isFree
                            ? AppColors.accentMint
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (!offer.isFree)
                      Text(
                        offer.currencyCode,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _durationLabel(AppLocalizations l10n, int days) => switch (days) {
        30 => l10n.prepPlusDuration30,
        60 => l10n.prepPlusDuration60,
        90 => l10n.prepPlusDuration90,
        183 => l10n.prepPlusDuration6Months,
        _ => l10n.prepPlusDurationDays(days),
      };
}
