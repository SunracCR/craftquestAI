import 'dart:async';

import 'package:craftquest_app/core/billing/post_checkout_session_refresh.dart';
import 'package:craftquest_app/core/billing/mobile_store_purchase_completion.dart';
import 'package:craftquest_app/core/billing/mobile_store_product_query.dart';
import 'package:craftquest_app/core/billing/mobile_store_purchase_coordinator.dart';
import 'package:craftquest_app/core/billing/paypal_web_launcher.dart';
import 'package:craftquest_app/core/billing/payment_platform.dart';
import 'package:craftquest_app/core/compliance/parental_gate_dialog.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/ai_generation_allowance.dart';
import 'package:craftquest_app/core/widgets/app_page_header.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/features/billing/data/pending_paypal_payment_store.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AiCreditPacksPage extends StatefulWidget {
  const AiCreditPacksPage({super.key});

  @override
  State<AiCreditPacksPage> createState() => _AiCreditPacksPageState();
}

class _AiCreditPacksPageState extends State<AiCreditPacksPage> {
  final _repository = getIt<BillingRepository>();
  final _storePurchases = getIt<MobileStorePurchaseCoordinator>();

  List<AiCreditPackModel> _packs = [];
  List<ProductDetails> _storeProducts = [];
  UserBillingModel? _billing;
  bool _loading = true;
  bool _purchasing = false;
  bool _userInitiatedPurchase = false;
  String? _error;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  bool _storeAvailable = false;
  final Set<String> _handledPurchaseKeys = {};

  static bool get _supportsStorePurchase =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _storePurchases.pushBillingPageHandler();
    if (_supportsStorePurchase) {
      _purchaseSub =
          InAppPurchase.instance.purchaseStream.listen(_onPurchaseUpdate);
    }
    _load();
  }

  @override
  void dispose() {
    _storePurchases.popBillingPageHandler();
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final packs = await _repository.getAiCreditPacks();
      final billing = await _repository.getMyBilling();
      _storeAvailable =
          _supportsStorePurchase && await isMobileStoreAvailable();

      var storeProducts = <ProductDetails>[];
      if (_storeAvailable) {
        final ids = <String>{};
        for (final pack in packs) {
          final id = pack.storeProductId(
            isIos: defaultTargetPlatform == TargetPlatform.iOS,
          );
          if (id != null && id.isNotEmpty) {
            ids.add(id);
          }
        }
        if (ids.isNotEmpty) {
          final response = await queryMobileStoreProducts(ids);
          storeProducts = response.productDetails;
        }
        // Reintenta compras pendientes (p. ej. verify falló tras el cobro en Play).
        await InAppPurchase.instance.restorePurchases();
      }

      if (!mounted) return;
      setState(() {
        _packs = packs;
        _billing = billing;
        _storeProducts = storeProducts;
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

  Future<void> _buyPack(AiCreditPackModel pack) async {
    if (!await showParentalGate(context)) {
      return;
    }
    if (_supportsStorePurchase && _storeAvailable) {
      await _buyWithStore(pack);
    } else if (PaymentPlatform.supportsPayPalCheckout) {
      await _buyWithPayPal(pack);
    }
  }

  Future<void> _buyWithPayPal(AiCreditPackModel pack) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _purchasing = true);
    try {
      final order = await _repository.createPayPalAiCreditOrder(pack.code);
      if (order.mockMode) {
        final captured =
            await _repository.capturePayPalAiCreditOrder(order.orderId);
        if (!mounted) return;
        await refreshAppSessionAfterCheckout(context);
        if (!mounted) return;
        context.showSuccessSnackBar(
          l10n.aiCreditPacksPurchaseSuccess(captured.creditsGranted),
        );
        Navigator.of(context).pop(true);
        return;
      }

      if (order.approvalUrl != null && order.approvalUrl!.isNotEmpty) {
        final uri = Uri.parse(order.approvalUrl!);
        if (await canLaunchUrl(uri)) {
          await getIt<PendingPayPalPaymentStore>().save(
            PendingPayPalPayment(
              flow: PendingPayPalPaymentFlow.aiCredit,
              id: order.orderId,
              createdAt: DateTime.now().toUtc(),
              packCode: pack.code,
            ),
          );
          await launchPayPalApproval(uri);
          if (!mounted) return;
          if (!kIsWeb) {
            context.showInfoSnackBar(l10n.paypalAwaitingCapture);
          }
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _buyWithStore(AiCreditPackModel pack) async {
    final l10n = AppLocalizations.of(context)!;
    final productId = pack.storeProductId(
      isIos: defaultTargetPlatform == TargetPlatform.iOS,
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
    product ??= await findMobileStoreProduct(productId);
    if (product == null) {
      if (mounted) {
        context.showErrorSnackBar(l10n.storeProductNotFound(productId));
      }
      return;
    }

    setState(() => _purchasing = true);
    _userInitiatedPurchase = true;
    await InAppPurchase.instance.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    final l10n = AppLocalizations.of(context)!;
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (!_isAiCreditProduct(purchase.productID)) {
          continue;
        }

        final purchaseKey = _purchaseKey(purchase);
        if (!_storePurchases.claimPurchase(purchaseKey)) {
          if (_userInitiatedPurchase) {
            scheduleDeferredCheckoutRefresh(context);
          }
          _resetPurchasingIfUserInitiated(purchase);
          continue;
        }

        final userInitiated = _userInitiatedPurchase;
        var verified = false;
        try {
          final platform = defaultTargetPlatform == TargetPlatform.iOS
              ? 'app_store'
              : 'google_play';
          final token = purchase.verificationData.serverVerificationData;
          final result = await _repository.verifyMobileAiCreditPurchase(
            platform: platform,
            productId: purchase.productID,
            purchaseToken: token.isNotEmpty ? token : purchase.purchaseID ?? '',
            transactionId: purchase.purchaseID,
          );
          verified = true;
          await completeMobileStorePurchaseIfNeeded(purchase);
          if (!mounted) return;

          await refreshAppSessionAfterCheckout(context);
          if (!mounted) return;

          if (userInitiated) {
            context.showSuccessSnackBar(
              l10n.aiCreditPacksPurchaseSuccess(result.creditsGranted),
            );
            Navigator.of(context).pop(true);
          } else {
            final billing = await _repository.getMyBilling(forceRefresh: true);
            if (!mounted) return;
            setState(() => _billing = billing);
          }
        } on DioException catch (e) {
          if (!verified) {
            _storePurchases.releasePurchase(purchaseKey);
          }
          if (!mounted) return;
          if (userInitiated) {
            context.showDioErrorSnackBar(e);
          }
        } catch (_) {
          if (!verified) {
            _storePurchases.releasePurchase(purchaseKey);
          }
          if (!mounted) return;
          if (userInitiated) {
            context.showErrorSnackBar(l10n.purchaseVerificationFailed);
          }
        } finally {
          if (userInitiated) {
            _userInitiatedPurchase = false;
          }
          if (mounted) setState(() => _purchasing = false);
        }
        continue;
      }

      if ((purchase.status == PurchaseStatus.error ||
              purchase.status == PurchaseStatus.canceled) &&
          mounted) {
        if (purchase.status == PurchaseStatus.error) {
          context.showErrorSnackBar(
            purchase.error?.message ?? l10n.purchaseFailed,
          );
        }
        _userInitiatedPurchase = false;
        setState(() => _purchasing = false);
      }
    }
  }

  void _resetPurchasingIfUserInitiated(PurchaseDetails purchase) {
    if (!_userInitiatedPurchase) {
      return;
    }
    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      return;
    }
    _userInitiatedPurchase = false;
    if (mounted) {
      setState(() => _purchasing = false);
    }
  }

  String _purchaseKey(PurchaseDetails purchase) {
    final token = purchase.verificationData.serverVerificationData;
    if (token.isNotEmpty) {
      return '${purchase.productID}|$token';
    }
    return '${purchase.productID}|${purchase.purchaseID ?? purchase.transactionDate ?? ''}';
  }

  bool _isAiCreditProduct(String productId) {
    if (_storePurchases.isAiCreditProduct(productId)) {
      return true;
    }
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    for (final pack in _packs) {
      if (pack.storeProductId(isIos: isIos) == productId) {
        return true;
      }
    }
    for (final product in _storeProducts) {
      if (product.id == productId) {
        return true;
      }
    }
    return false;
  }

  String _formatPrice(AiCreditPackModel pack, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat.simpleCurrency(
      name: pack.currencyCode,
      locale: locale,
    );
    return formatter.format(pack.price);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.aiCreditPacksTitle),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  title: l10n.aiCreditPacksTitle,
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : _packs.isEmpty
                  ? AppEmptyView(message: l10n.aiCreditPacksEmpty)
                  : ListView(
                  padding: AppSpacing.pageVertical,
                  children: [
                    AppPageHeader(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.aiCreditPacksSubtitle,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ),
                    if (_billing != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppSectionCard(
                        child: Text(
                          l10n.aiCreditPacksCurrentBalance(
                            AiGenerationAllowance.estimateGenerations(
                              _billing!.credits.aiCredits,
                            ),
                            _billing!.credits.aiCredits,
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    ..._packs.map(
                      (pack) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                pack.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                l10n.aiCreditPacksCreditsLabel(
                                  AiGenerationAllowance.estimateGenerations(
                                    pack.credits,
                                  ),
                                  pack.credits,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FilledButton(
                                onPressed: _purchasing
                                    ? null
                                    : () => _buyPack(pack),
                                child: _purchasing
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        l10n.aiCreditPacksBuyForPrice(
                                          _formatPrice(pack, l10n),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
