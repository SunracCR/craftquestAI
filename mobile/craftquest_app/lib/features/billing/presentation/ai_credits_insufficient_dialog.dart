import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/utils/billing_plan_access.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/features/billing/presentation/ai_credit_packs_page.dart';
import 'package:craftquest_app/features/billing/presentation/upgrade_plan_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

Future<void> showAiCreditsInsufficientDialog(
  BuildContext context, {
  UserBillingModel? billing,
}) async {
  final l10n = AppLocalizations.of(context)!;
  billing ??= await _tryLoadBilling();
  if (!context.mounted) return;
  final canBuyPacks = BillingPlanAccess.canBuyAiCreditPacks(billing?.plan.code);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.errorAiCreditsInsufficient),
      content: Text(
        canBuyPacks
            ? l10n.aiCreditsInsufficientDialogMessage
            : l10n.aiCreditsInsufficientFreePlanMessage,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
        if (canBuyPacks)
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const AiCreditPacksPage(),
                ),
              );
            },
            child: Text(l10n.aiCreditPacksBuyAction),
          )
        else
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const UpgradePlanPage(),
                ),
              );
            },
            child: Text(l10n.upgradePlanAction),
          ),
      ],
    ),
  );
}

Future<UserBillingModel?> _tryLoadBilling() async {
  try {
    return await getIt<BillingRepository>().getMyBilling();
  } catch (_) {
    return null;
  }
}
