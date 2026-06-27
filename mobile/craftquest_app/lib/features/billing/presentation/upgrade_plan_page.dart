import 'dart:async';

import 'package:craftquest_app/core/billing/payment_platform.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/utils/billing_display.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_page_header.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/billing/presentation/billing_cycle_selector.dart';
import 'package:craftquest_app/features/billing/presentation/current_plan_subscription_banner.dart';
import 'package:craftquest_app/features/billing/presentation/plan_upgrade_highlights.dart';
import 'package:craftquest_app/features/billing/presentation/subscription_cancel_flow.dart';
import 'package:craftquest_app/features/billing/presentation/subscription_resume_flow.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

class UpgradePlanPage extends StatefulWidget {
  const UpgradePlanPage({super.key});

  @override
  State<UpgradePlanPage> createState() => _UpgradePlanPageState();
}

class _UpgradePlanPageState extends State<UpgradePlanPage> {
  final _repository = getIt<BillingRepository>();

  List<UpgradeablePlanModel> _plans = [];
  List<ProductDetails> _storeProducts = [];
  UserBillingModel? _billing;
  BillingCycle _billingCycle = BillingCycle.monthly;
  bool _loading = true;
  bool _purchasing = false;
  bool _cancelling = false;
  bool _resuming = false;
  String? _error;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  bool _storeAvailable = false;

  static bool get _supportsStorePurchase =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_supportsStorePurchase) {
      _purchaseSub =
          InAppPurchase.instance.purchaseStream.listen(_onPurchaseUpdate);
    }
    _load();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _load({bool forceRefreshBilling = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plans = await _repository.getUpgradeablePlans();
      UserBillingModel? billing;
      try {
        billing = await _repository.getMyBilling(forceRefresh: forceRefreshBilling);
      } catch (_) {
        billing = null;
      }
      _storeAvailable =
          _supportsStorePurchase && await InAppPurchase.instance.isAvailable();

      var storeProducts = <ProductDetails>[];
      if (_storeAvailable) {
        final ids = <String>{};
        for (final plan in plans) {
          for (final id in [
            plan.googlePlayProductId,
            plan.googlePlayAnnualProductId,
            plan.appStoreProductId,
            plan.appStoreAnnualProductId,
          ]) {
            if (id != null && id.isNotEmpty) {
              ids.add(id);
            }
          }
        }
        if (ids.isNotEmpty) {
          final response = await InAppPurchase.instance.queryProductDetails(ids);
          storeProducts = response.productDetails;
        }
      }

      if (!mounted) return;
      setState(() {
        _plans = plans;
        _storeProducts = storeProducts;
        _billing = billing;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.map(e, AppLocalizations.of(context));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.genericMessage(AppLocalizations.of(context));
        _loading = false;
      });
    }
  }

  Future<void> _buyWithStore(UpgradeablePlanModel plan) async {
    final l10n = AppLocalizations.of(context)!;
    final productId = plan.storeProductId(
      isIos: defaultTargetPlatform == TargetPlatform.iOS,
      billingCycle: _billingCycle.apiValue,
    );

    if (productId == null || productId.isEmpty) {
      context.showErrorSnackBar(l10n.storeProductNotConfigured);
      return;
    }

    ProductDetails? product;
    for (final candidate in _storeProducts) {
      if (candidate.id == productId) {
        product = candidate;
        break;
      }
    }
    if (product == null) {
      context.showErrorSnackBar(l10n.storeProductNotFound(productId));
      return;
    }

    setState(() => _purchasing = true);
    final param = PurchaseParam(productDetails: product);
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
  }

  Future<void> _buyWithPayPal(UpgradeablePlanModel plan) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _purchasing = true);
    try {
      final subscription = await _repository.createPayPalSubscription(
        plan.code,
        billingCycle: _billingCycle.apiValue,
      );
      if (subscription.mockMode) {
        final activated = await _repository.activatePayPalSubscription(
          subscription.subscriptionId,
          billingCycle: _billingCycle.apiValue,
        );
        if (!mounted) return;
        context.showSuccessSnackBar(
          l10n.upgradeSuccess(
            BillingDisplay.localizedPlanName(l10n, code: activated.planCode),
          ),
        );
        Navigator.of(context).pop(true);
        return;
      }

      if (subscription.approvalUrl != null &&
          subscription.approvalUrl!.isNotEmpty) {
        final uri = Uri.parse(subscription.approvalUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!mounted) return;
          context.showSuccessSnackBar(l10n.paypalAwaitingSubscriptionActivation);
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  bool get _showCurrentPlanBanner {
    final billing = _billing;
    if (billing == null) {
      return false;
    }
    final code = billing.plan.code.toLowerCase();
    return code == 'pro' || code == 'premium';
  }

  Future<void> _cancelSubscription() async {
    final subscription = _billing?.subscription;
    if (subscription == null) {
      return;
    }
    await SubscriptionCancelFlow.showCancelDialog(
      context: context,
      providerCode: subscription.providerCode,
      onCompleted: () async {
        setState(() => _cancelling = true);
        try {
          await _load(forceRefreshBilling: true);
        } finally {
          if (mounted) setState(() => _cancelling = false);
        }
      },
    );
  }

  Future<void> _resumeSubscription() async {
    final subscription = _billing?.subscription;
    if (subscription == null) {
      return;
    }
    await SubscriptionResumeFlow.showResumeDialog(
      context: context,
      providerCode: subscription.providerCode,
      onCompleted: () async {
        setState(() => _resuming = true);
        try {
          await _load(forceRefreshBilling: true);
        } finally {
          if (mounted) setState(() => _resuming = false);
        }
      },
      onRequiresResubscribe: () async {
        final code = _billing?.plan.code ?? 'pro';
        final plan = _plans
            .where((p) => p.code.toLowerCase() == code.toLowerCase())
            .firstOrNull;
        if (plan != null) {
          if (_supportsStorePurchase && _storeAvailable) {
            await _buyWithStore(plan);
          } else if (PaymentPlatform.supportsPayPalCheckout) {
            await _buyWithPayPal(plan);
          }
        }
      },
    );
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    final l10n = AppLocalizations.of(context)!;
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          final platform = defaultTargetPlatform == TargetPlatform.iOS
              ? 'app_store'
              : 'google_play';
          final token = purchase.verificationData.serverVerificationData;
          final verified = await _repository.verifyMobilePurchase(
            platform: platform,
            productId: purchase.productID,
            purchaseToken: token.isNotEmpty ? token : purchase.purchaseID ?? '',
            transactionId: purchase.purchaseID,
            billingCycle: _billingCycle.apiValue,
          );
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
          if (!mounted) return;
          context.showSuccessSnackBar(
            l10n.upgradeSuccess(
              BillingDisplay.localizedPlanName(l10n, code: verified.planCode),
            ),
          );
          Navigator.of(context).pop(true);
        } catch (_) {
          if (!mounted) return;
          context.showErrorSnackBar(l10n.purchaseVerificationFailed);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        if (!mounted) return;
        context.showErrorSnackBar(
          purchase.error?.message ?? l10n.purchaseFailed,
        );
      }
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.upgradePlanTitle),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  title: l10n.upgradePlanTitle,
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : _plans.isEmpty
                  ? AppEmptyView(message: l10n.upgradePlanAlreadyHighest)
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    AppPageHeader(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.upgradePlanSubtitle,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            if (_plans.any((p) => !p.isInstitutionPlan)) ...[
                              const SizedBox(height: 16),
                              Text(
                                l10n.subscriptionAutoRenewDisclaimer,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              BillingCycleSelector(
                                value: _billingCycle,
                                enabled: !_purchasing,
                                onChanged: (cycle) {
                                  setState(() => _billingCycle = cycle);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          if (_showCurrentPlanBanner && _billing != null) ...[
                            CurrentPlanSubscriptionBanner(
                              planName: BillingDisplay.localizedPlanName(
                                l10n,
                                code: _billing!.plan.code,
                                name: _billing!.plan.name,
                              ),
                              subscription: _billing!.subscription,
                              onCancelPressed: _cancelSubscription,
                              cancelling: _cancelling,
                              onResumePressed: _resumeSubscription,
                              resuming: _resuming,
                            ),
                            const SizedBox(height: 16),
                          ],
                          ..._plans.asMap().entries.map(
                                (e) => _planCard(e.value, l10n, e.key),
                              ),
                        ],
                      ),
                    ),
                    if (kIsWeb) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.paypalWebHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
    );
  }

  Widget _planCard(UpgradeablePlanModel plan, AppLocalizations l10n, int index) {
    final price = BillingDisplay.formatPlanPrice(
      context,
      l10n,
      monthlyPrice: plan.monthlyPrice,
      annualPrice: plan.annualPrice,
      cycle: _billingCycle,
    );
    final planName = BillingDisplay.localizedPlanName(
      l10n,
      code: plan.code,
      name: plan.name,
    );
    final highlights = PlanUpgradeHighlights.forPlan(
      l10n,
      plan,
      currentEntitlements: _billing?.entitlements ??
          const PlanEntitlementsModel(
            monthlyAiCredits: 0,
            monthlyShareCodes: 0,
            currentRedeemedSharedQuizzes: 0,
          ),
    );

    final accent = switch (index % 3) {
      0 => AppColors.accent,
      1 => AppColors.accentViolet,
      _ => AppColors.accentGold,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppSectionCard(
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppColors.radiusSm),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(planName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              price,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (highlights.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...highlights.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.accentMint.withValues(alpha: 0.95),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          line,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textPrimary.withValues(alpha: 0.9),
                                height: 1.35,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (plan.isInstitutionPlan)
              Text(
                l10n.institutionPlanContactHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              )
            else ...[
              if (!kIsWeb && _storeAvailable)
                FilledButton(
                  onPressed: _purchasing ? null : () => _buyWithStore(plan),
                  child: _purchasing
                      ? const AppButtonLoader()
                      : Text(l10n.buyWithStoreAction),
                ),
              if (PaymentPlatform.supportsPayPalCheckout) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: accent.withValues(alpha: 0.6)),
                  ),
                  onPressed: _purchasing ? null : () => _buyWithPayPal(plan),
                  child: Text(l10n.buyWithPayPalAction),
                ),
              ],
            ],
          ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
