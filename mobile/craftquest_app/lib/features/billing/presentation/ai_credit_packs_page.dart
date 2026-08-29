import 'dart:async';

import 'package:craftquest_app/core/billing/mobile_store_product_query.dart';
import 'package:craftquest_app/core/billing/paypal_checkout_launch.dart';
import 'package:craftquest_app/core/billing/paypal_payment_reconciler.dart';
import 'package:craftquest_app/core/billing/post_checkout_session_refresh.dart';
import 'package:craftquest_app/core/billing/purchase_flow_state.dart';
import 'package:craftquest_app/core/billing/purchase_orchestrator.dart';
import 'package:craftquest_app/core/billing/store_purchase_feedback.dart';
import 'package:craftquest_app/core/billing/payment_platform.dart';
import 'package:craftquest_app/core/compliance/parental_gate_dialog.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/features/billing/data/pending_paypal_payment_store.dart';
import 'package:craftquest_app/features/billing/presentation/widgets/ai_credit_pack_widgets.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

class AiCreditPacksPage extends StatefulWidget {
  const AiCreditPacksPage({super.key});

  @override
  State<AiCreditPacksPage> createState() => _AiCreditPacksPageState();
}

class _AiCreditPacksPageState extends State<AiCreditPacksPage> {
  final _repository = getIt<BillingRepository>();
  final _orchestrator = getIt<PurchaseOrchestrator>();

  List<AiCreditPackModel> _packs = [];
  List<ProductDetails> _storeProducts = [];
  UserBillingModel? _billing;
  bool _loading = true;
  bool _paypalPurchasing = false;
  String? _error;
  bool _storeAvailable = false;
  String? _pendingPayPalOrderId;

  bool get _purchasing => _orchestrator.isBusy || _paypalPurchasing;

  static bool get _supportsStorePurchase =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _orchestrator.addListener(_onOrchestratorChanged);
    _load();
  }

  @override
  void dispose() {
    _orchestrator.removeListener(_onOrchestratorChanged);
    super.dispose();
  }

  void _onOrchestratorChanged() {
    if (!mounted) {
      return;
    }
    final state = _orchestrator.state;
    if (state is PurchaseDeferred) {
      showStorePurchaseDeferred(context);
    } else if (state is PurchaseFailed) {
      showStorePurchaseFailure(context, state);
      _orchestrator.resetToIdle();
    }
    setState(() {});
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
      }

      if (!mounted) return;
      final pendingPayPal = await getIt<PendingPayPalPaymentStore>().read();
      final pendingPayPalOrderId =
          pendingPayPal?.flow == PendingPayPalPaymentFlow.aiCredit
              ? pendingPayPal!.id
              : null;
      setState(() {
        _packs = packs;
        _billing = billing;
        _storeProducts = storeProducts;
        _loading = false;
        _pendingPayPalOrderId = kIsWeb ? null : pendingPayPalOrderId;
      });
      if (kIsWeb && pendingPayPalOrderId != null) {
        unawaited(_autoFulfillPendingPayPalOnWeb());
      }
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
    setState(() => _paypalPurchasing = true);
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
        await getIt<PendingPayPalPaymentStore>().save(
          PendingPayPalPayment(
            flow: PendingPayPalPaymentFlow.aiCredit,
            id: order.orderId,
            createdAt: DateTime.now().toUtc(),
            packCode: pack.code,
          ),
        );
        final launched = await openPayPalApprovalUrl(context, uri, l10n: l10n);
        if (!mounted) return;
        if (launched && !kIsWeb) {
          setState(() => _pendingPayPalOrderId = order.orderId);
          context.showInfoSnackBar(l10n.paypalAwaitingCapture);
        }
      } else if (!order.mockMode) {
        context.showErrorSnackBar(l10n.paypalReturnError);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _paypalPurchasing = false);
    }
  }

  Future<void> _autoFulfillPendingPayPalOnWeb() async {
    if (!kIsWeb || _paypalPurchasing) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() => _paypalPurchasing = true);
    try {
      final fulfilled =
          await getIt<PayPalPaymentReconciler>().tryFulfillStoredPending();
      if (!mounted || !fulfilled) {
        return;
      }
      await refreshAppSessionAfterCheckout(context);
      if (!mounted) {
        return;
      }
      context.showSuccessSnackBar(l10n.paypalReturnSuccessCredits);
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _paypalPurchasing = false);
      }
    }
  }

  Future<void> _confirmPayPalCapture() async {
    if (_pendingPayPalOrderId == null) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() => _paypalPurchasing = true);
    try {
      final fulfilled = await getIt<PayPalPaymentReconciler>().tryFulfillStoredPending();
      if (!mounted) return;
      if (fulfilled) {
        setState(() => _pendingPayPalOrderId = null);
        await refreshAppSessionAfterCheckout(context);
        if (!mounted) return;
        context.showSuccessSnackBar(l10n.paypalReturnSuccessCredits);
        Navigator.of(context).pop(true);
        return;
      }
      context.showErrorSnackBar(l10n.paypalReturnError);
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _paypalPurchasing = false);
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

    final result = await _orchestrator.buy(
      StorePurchaseRequest(
        kind: PurchaseProductKind.aiCredits,
        productId: productId,
        product: product,
      ),
    );

    if (!mounted) return;
    _orchestrator.resetToIdle();

    if (result is AiCreditsPurchaseResult) {
      context.showSuccessSnackBar(
        l10n.aiCreditPacksPurchaseSuccess(result.creditsGranted),
      );
      Navigator.of(context).pop(true);
    }
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
                    if (_billing != null) ...[
                      AiCreditBalanceHero(
                        credits: _billing!.credits.aiCredits,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (_pendingPayPalOrderId != null && !kIsWeb) ...[
                      AppSectionCard(
                        variant: AppCardVariant.highlight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.paypalAwaitingCapture,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppPrimaryButton(
                              label: l10n.prepPlusConfirmPayPalPayment,
                              isLoading: _paypalPurchasing,
                              onPressed:
                                  _paypalPurchasing ? null : _confirmPayPalCapture,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    ..._packs.asMap().entries.map(
                      (entry) {
                        final pack = entry.value;
                        final display = AiCreditPackDisplay.forPack(pack, l10n);
                        final priceLabel = resolveAiCreditPackPriceLabel(
                          pack: pack,
                          storeProducts: _storeProducts,
                          formatApiPrice: (p) => _formatPrice(p, l10n),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AiCreditPackCard(
                            pack: pack,
                            display: display,
                            priceLabel: priceLabel,
                            purchasing: _purchasing,
                            onBuy: _purchasing ? null : () => _buyPack(pack),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.aiCreditPacksFootnote,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
    );
  }
}
