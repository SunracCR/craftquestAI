import 'dart:async';

import 'package:craftquest_app/core/billing/payment_platform.dart';
import 'package:craftquest_app/core/compliance/parental_gate_dialog.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_page_header.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
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

  List<AiCreditPackModel> _packs = [];
  List<ProductDetails> _storeProducts = [];
  UserBillingModel? _billing;
  bool _loading = true;
  bool _purchasing = false;
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final packs = await _repository.getAiCreditPacks();
      final billing = await _repository.getMyBilling();
      _storeAvailable =
          _supportsStorePurchase && await InAppPurchase.instance.isAvailable();

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
          final response =
              await InAppPurchase.instance.queryProductDetails(ids);
          storeProducts = response.productDetails;
        }
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
        context.showSuccessSnackBar(
          l10n.aiCreditPacksPurchaseSuccess(captured.creditsGranted),
        );
        Navigator.of(context).pop(true);
        return;
      }

      if (order.approvalUrl != null && order.approvalUrl!.isNotEmpty) {
        final uri = Uri.parse(order.approvalUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!mounted) return;
          context.showInfoSnackBar(l10n.paypalAwaitingCapture);
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
    if (product == null) {
      context.showErrorSnackBar(l10n.storeProductNotFound(productId));
      return;
    }

    setState(() => _purchasing = true);
    await InAppPurchase.instance.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    final l10n = AppLocalizations.of(context)!;
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        try {
          final platform = defaultTargetPlatform == TargetPlatform.iOS
              ? 'app_store'
              : 'google_play';
          final token = purchase.verificationData.serverVerificationData;
          final result = await _repository.verifyMobileAiCreditPurchase(
            platform: platform,
            productId: purchase.productID,
            purchaseToken: token,
            transactionId: purchase.purchaseID,
          );
          if (!mounted) return;
          context.showSuccessSnackBar(
            l10n.aiCreditPacksPurchaseSuccess(result.creditsGranted),
          );
          Navigator.of(context).pop(true);
        } on DioException catch (e) {
          if (!mounted) return;
          context.showDioErrorSnackBar(e);
        } finally {
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
        }
      }
      if (mounted) setState(() => _purchasing = false);
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
                                l10n.aiCreditPacksCreditsLabel(pack.credits),
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
