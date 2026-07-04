import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/prep_plus/presentation/widgets/prep_plus_access_countdown_badge.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card compacta de estado de acceso + CTA para abrir opciones de compra/extensión.
class PrepPlusAccessUpsellCard extends StatelessWidget {
  const PrepPlusAccessUpsellCard({
    super.key,
    required this.userAccessState,
    required this.canPractice,
    required this.accessExpiresAt,
    required this.offers,
    required this.onTap,
    required this.formatDate,
  });

  final String userAccessState;
  final bool canPractice;
  final DateTime? accessExpiresAt;
  final List<PrepAccessOfferModel> offers;
  final VoidCallback onTap;
  final String Function(DateTime date) formatDate;

  PrepAccessOfferModel? get _cheapestPaidOffer {
    PrepAccessOfferModel? cheapest;
    for (final offer in offers) {
      if (offer.isFree) continue;
      if (cheapest == null || offer.priceAmount < cheapest.priceAmount) {
        cheapest = offer;
      }
    }
    return cheapest;
  }

  bool get _hasFreeOffer => offers.any((o) => o.isFree);

  String _actionLabel(AppLocalizations l10n) {
    if (canPractice) return l10n.prepPlusExtendAccessAction;
    if (userAccessState == 'expired') return l10n.prepPlusRenewAction;
    if (_hasFreeOffer) return l10n.prepPlusGetFreeAccessAction;
    return l10n.prepPlusBuyAction;
  }

  String _title(AppLocalizations l10n) {
    if (canPractice && accessExpiresAt != null) {
      return l10n.prepPlusAccessUntil(formatDate(accessExpiresAt!));
    }
    if (userAccessState == 'expired') {
      return l10n.prepPlusAccessExpired;
    }
    return l10n.prepPlusAccessCardNoAccessTitle;
  }

  String? _subtitle(AppLocalizations l10n, BuildContext context) {
    if (canPractice &&
        accessExpiresAt != null &&
        PrepPlusAccessCountdown.shouldShow(
          canPractice: canPractice,
          accessExpiresAt: accessExpiresAt,
        )) {
      return null;
    }
    if (canPractice) return l10n.prepPlusExtendAccessCardSubtitle;
    final cheapest = _cheapestPaidOffer;
    if (cheapest != null) {
      final locale = Localizations.localeOf(context).toString();
      final price = NumberFormat.simpleCurrency(
        name: cheapest.currencyCode,
        locale: locale,
      ).format(cheapest.priceAmount);
      return l10n.prepPlusAccessFromPrice(price);
    }
    if (_hasFreeOffer) return l10n.prepPlusGetFreeAccessAction;
    return l10n.prepPlusAccessCombosSubtitle;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showCountdown = canPractice &&
        accessExpiresAt != null &&
        PrepPlusAccessCountdown.shouldShow(
          canPractice: canPractice,
          accessExpiresAt: accessExpiresAt,
        );
    final subtitle = _subtitle(l10n, context);

    return AppSectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (canPractice ? AppColors.accentMint : AppColors.warning)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              canPractice
                  ? Icons.schedule_rounded
                  : Icons.lock_clock_rounded,
              color: canPractice ? AppColors.accentMint : AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(l10n),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showCountdown && accessExpiresAt != null) ...[
                  const SizedBox(height: 4),
                  PrepPlusAccessCountdownText(expiresAt: accessExpiresAt!),
                ] else if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          FilledButton.tonal(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.accentGold,
              backgroundColor: AppColors.accentGold.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              _actionLabel(l10n),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
