import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/ai_generation_allowance.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Localized tier label and accent for known AI credit pack codes.
class AiCreditPackDisplay {
  const AiCreditPackDisplay._({
    required this.tierLabel,
    required this.accent,
    required this.isPopular,
  });

  final String tierLabel;
  final Color accent;
  final bool isPopular;

  static AiCreditPackDisplay forPack(AiCreditPackModel pack, AppLocalizations l10n) {
    return switch (pack.code) {
      'pack_120' => AiCreditPackDisplay._(
          tierLabel: l10n.aiCreditPacksTierPlus,
          accent: AppColors.accentViolet,
          isPopular: true,
        ),
      'pack_300' => AiCreditPackDisplay._(
          tierLabel: l10n.aiCreditPacksTierMax,
          accent: AppColors.accentGold,
          isPopular: false,
        ),
      _ => AiCreditPackDisplay._(
          tierLabel: l10n.aiCreditPacksTierStarter,
          accent: AppColors.accent,
          isPopular: false,
        ),
    };
  }
}

class AiCreditBalanceHero extends StatelessWidget {
  const AiCreditBalanceHero({
    super.key,
    required this.credits,
  });

  final int credits;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final generations = AiGenerationAllowance.estimateGenerations(credits);
    final theme = Theme.of(context);

    return AppSectionCard(
      variant: AppCardVariant.highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.aiCreditPacksBalanceGenerations(generations),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.accentViolet,
              height: 1.05,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.aiCreditPacksGenerationsUnit,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.aiCreditPacksBalanceCredits(credits),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.aiCreditPacksBalanceNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class AiCreditPackCard extends StatelessWidget {
  const AiCreditPackCard({
    super.key,
    required this.pack,
    required this.display,
    required this.priceLabel,
    required this.purchasing,
    required this.onBuy,
  });

  final AiCreditPackModel pack;
  final AiCreditPackDisplay display;
  final String priceLabel;
  final bool purchasing;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final generations = AiGenerationAllowance.estimateGenerations(pack.credits);
    final theme = Theme.of(context);

    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: display.accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppColors.radiusSm),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: AppColors.paddingMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                display.tierLabel,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    l10n.aiCreditPacksBalanceGenerations(
                                      generations,
                                    ),
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: display.accent,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Flexible(
                                    child: Text(
                                      l10n.aiCreditPacksGenerationsUnit,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.aiCreditPacksBalanceCredits(pack.credits),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (display.isPopular)
                              AppStatusChip(
                                label: l10n.aiCreditPacksPopularBadge,
                                color: display.accent,
                              ),
                            if (display.isPopular)
                              const SizedBox(height: AppSpacing.xs),
                            Text(
                              priceLabel,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: display.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppGradientPrimaryButton(
                      label: l10n.aiCreditPacksBuyForPrice(priceLabel),
                      icon: Icons.auto_awesome_outlined,
                      isLoading: purchasing,
                      onPressed: onBuy,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String resolveAiCreditPackPriceLabel({
  required AiCreditPackModel pack,
  required List<ProductDetails> storeProducts,
  required String Function(AiCreditPackModel pack) formatApiPrice,
}) {
  final productId = pack.storeProductId(
    isIos: defaultTargetPlatform == TargetPlatform.iOS,
  );
  if (productId != null) {
    for (final product in storeProducts) {
      if (product.id == productId && product.price.isNotEmpty) {
        return product.price;
      }
    }
  }
  return formatApiPrice(pack);
}
