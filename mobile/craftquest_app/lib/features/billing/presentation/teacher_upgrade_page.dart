import 'dart:async';

import 'package:craftquest_app/core/billing/post_checkout_session_refresh.dart';
import 'package:craftquest_app/core/billing/paypal_web_launcher.dart';
import 'package:craftquest_app/core/billing/payment_platform.dart';
import 'package:craftquest_app/core/compliance/parental_gate_dialog.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/billing_display.dart';
import 'package:craftquest_app/core/widgets/app_notice_banner.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/features/auth/data/models/auth_models.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/features/billing/data/pending_paypal_payment_store.dart';
import 'package:craftquest_app/features/billing/presentation/billing_cycle_selector.dart';
import 'package:craftquest_app/features/billing/presentation/subscription_cancel_flow.dart';
import 'package:craftquest_app/features/billing/presentation/subscription_resume_flow.dart';
import 'package:craftquest_app/features/billing/presentation/upgrade_plan_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

/// Página de pitch premium para el plan Profesor.
/// Muestra el valor específico del plan teacher, permite adquirirlo
/// y, si ya está activo, permite cancelarlo.
class TeacherUpgradePage extends StatefulWidget {
  const TeacherUpgradePage({super.key, required this.user});

  final UserProfileModel user;

  @override
  State<TeacherUpgradePage> createState() => _TeacherUpgradePageState();
}

class _TeacherUpgradePageState extends State<TeacherUpgradePage> {
  final _repo = getIt<BillingRepository>();

  UpgradeablePlanModel? _teacherPlan;
  SubscriptionModel? _subscription;
  BillingCycle _billingCycle = BillingCycle.monthly;
  bool _loadingPlans = true;
  String? _plansLoadError;
  bool _purchasing = false;
  bool _cancelling = false;
  bool _resuming = false;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool get _isAlreadyTeacher => widget.user.roles.contains('teacher');

  /// InAppPurchase solo está disponible en Android/iOS.
  /// En Windows/Web acceder a `InAppPurchase.instance` lanza LateInitializationError.
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
      _loadingPlans = true;
      _plansLoadError = null;
    });
    try {
      final plans = await _repo.getUpgradeablePlans();
      final teacher = plans.where((p) => p.code == 'teacher').firstOrNull;
      SubscriptionModel? subscription;
      if (_isAlreadyTeacher) {
        final billing = await _repo.getMyBilling(forceRefresh: forceRefreshBilling);
        subscription = billing.subscription;
      }
      if (!mounted) return;
      setState(() {
        _teacherPlan = teacher;
        _subscription = subscription;
        _loadingPlans = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _plansLoadError = DioErrorMapper.map(e, AppLocalizations.of(context));
        _loadingPlans = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _plansLoadError = DioErrorMapper.genericMessage(
          AppLocalizations.of(context),
        );
        _loadingPlans = false;
      });
    }
  }

  Future<void> _buy() async {
    if (!await showParentalGate(context)) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final plan = _teacherPlan;
    if (plan == null) {
      context.showErrorSnackBar(l10n.genericRequestErrorMessage);
      await _load();
      return;
    }

    if (_supportsStorePurchase) {
      final storeAvailable = await InAppPurchase.instance.isAvailable();
      if (storeAvailable) {
        await _buyWithStore(plan);
        return;
      }
      context.showErrorSnackBar(l10n.storeProductNotConfigured);
      return;
    }
    if (PaymentPlatform.supportsPayPalCheckout) {
      await _buyWithPayPal(plan);
    }
  }

  Future<void> _buyWithStore(UpgradeablePlanModel plan) async {
    final iap = InAppPurchase.instance;
    final productId = plan.storeProductId(
      isIos: defaultTargetPlatform == TargetPlatform.iOS,
      billingCycle: _billingCycle.apiValue,
    );
    final l10n = AppLocalizations.of(context)!;
    if (productId == null) {
      context.showErrorSnackBar(l10n.storeProductNotConfigured);
      return;
    }
    final response = await iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      context.showErrorSnackBar(l10n.storeProductNotFound(productId));
      return;
    }
    setState(() => _purchasing = true);
    final param = PurchaseParam(productDetails: response.productDetails.first);
    await iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> _buyWithPayPal(UpgradeablePlanModel plan) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _purchasing = true);
    try {
      final subscription = await _repo.createPayPalSubscription(
        plan.code,
        billingCycle: _billingCycle.apiValue,
      );
      if (subscription.mockMode) {
        await _repo.activatePayPalSubscription(
          subscription.subscriptionId,
          billingCycle: _billingCycle.apiValue,
        );
        if (!mounted) return;
        await refreshAppSessionAfterCheckout(context);
        if (!mounted) return;
        context.showSuccessSnackBar(
          l10n.upgradeSuccess(
            BillingDisplay.localizedPlanName(l10n, code: plan.code),
          ),
        );
        Navigator.of(context).pop(true);
        return;
      }
      if (subscription.approvalUrl != null) {
        final uri = Uri.parse(subscription.approvalUrl!);
        if (await canLaunchUrl(uri)) {
          await getIt<PendingPayPalPaymentStore>().save(
            PendingPayPalPayment(
              flow: PendingPayPalPaymentFlow.subscription,
              id: subscription.subscriptionId,
              createdAt: DateTime.now().toUtc(),
              billingCycle: _billingCycle.apiValue,
              planCode: plan.code,
            ),
          );
          await launchPayPalApproval(uri);
          if (!mounted) return;
          if (!kIsWeb) {
            context.showSuccessSnackBar(
              l10n.paypalAwaitingSubscriptionActivation,
            );
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

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    final l10n = AppLocalizations.of(context)!;
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          final platform = defaultTargetPlatform == TargetPlatform.iOS
              ? 'app_store'
              : 'google_play';
          final token =
              purchase.verificationData.serverVerificationData;
          final verified = await _repo.verifyMobilePurchase(
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
          await refreshAppSessionAfterCheckout(context);
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
        context.showErrorSnackBar(purchase.error?.message ?? l10n.purchaseFailed);
      }
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _cancelSubscription() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.teacherUpgradeCancelTitle,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(l10n.teacherUpgradeCancelMessage,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.teacherUpgradeKeepPlan,
                  style: const TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.teacherUpgradeCancelConfirm,
                  style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final result = await _repo.cancelSubscription();
      if (!mounted) return;
      final accessDate = BillingDisplay.formatSubscriptionDate(
        context,
        result.accessUntil,
      );
      context.showSuccessSnackBar(
        l10n.teacherUpgradeCancelSuccessUntil(accessDate),
      );
      await _load(forceRefreshBilling: true);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _resumeSubscription() async {
    final subscription = _subscription;
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
      onRequiresResubscribe: _buy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(l10n),
          SliverToBoxAdapter(child: _buildBody(l10n)),
        ],
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.teacherAccentSurface,
      foregroundColor: AppColors.textPrimary,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.textSecondary),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _GridPatternPainter()),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.teacherAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.teacherAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        l10n.teacherUpgradePopularBadge,
                        style: const TextStyle(
                          color: AppColors.teacherAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.teacherUpgradeHeroTitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
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

  Widget _buildBody(AppLocalizations l10n) {
    final price = BillingDisplay.formatPlanPrice(
      context,
      l10n,
      monthlyPrice: _teacherPlan?.monthlyPrice,
      annualPrice: _teacherPlan?.annualPrice,
      cycle: _billingCycle,
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.teacherUpgradeHeroSubtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_plansLoadError != null) ...[
            AppNoticeBanner(
              message: _plansLoadError!,
              variant: AppNoticeVariant.warning,
              actionLabel: l10n.retry,
              onAction: _loadingPlans ? null : _load,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_loadingPlans)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: AppLoadingView(),
            )
          else ...[
            if (!_isAlreadyTeacher) ...[
              BillingCycleSelector(
                value: _billingCycle,
                enabled: !_purchasing && !_cancelling,
                onChanged: (cycle) => setState(() => _billingCycle = cycle),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              price,
              style: const TextStyle(
                color: AppColors.teacherAccent,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ],
          const SizedBox(height: 28),
          _pillar(
            icon: Icons.class_rounded,
            title: l10n.teacherUpgradePillar1Title,
            body: l10n.teacherUpgradePillar1Body,
            color: AppColors.teacherAccent,
          ),
          _pillar(
            icon: Icons.assignment_rounded,
            title: l10n.teacherUpgradePillar2Title,
            body: l10n.teacherUpgradePillar2Body,
            color: AppColors.accentCool,
          ),
          _pillar(
            icon: Icons.bar_chart_rounded,
            title: l10n.teacherUpgradePillar3Title,
            body: l10n.teacherUpgradePillar3Body,
            color: AppColors.accentMint,
          ),

          const SizedBox(height: 32),

          if (_isAlreadyTeacher) ...[
            AppNoticeBanner(
              message: _activePlanBannerMessage(l10n),
              variant: AppNoticeVariant.success,
            ),
            if (_subscription?.canResumeAutoRenew == true) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _resuming ? null : _resumeSubscription,
                style: TextButton.styleFrom(foregroundColor: AppColors.accentCool),
                child: _resuming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accentCool,
                        ),
                      )
                    : Text(
                        SubscriptionCancelFlow.isMobileStore(
                              _subscription?.providerCode,
                            )
                            ? l10n.billingResumeStoreTitle
                            : l10n.billingResumeAutoRenewConfirm,
                      ),
              ),
            ],
            if (_subscription?.autoRenewEnabled == true) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _cancelling ? null : _cancelSubscription,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: _cancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.error,
                        ),
                      )
                    : Text(
                        SubscriptionCancelFlow.isMobileStore(
                              _subscription?.providerCode,
                            )
                            ? l10n.billingCancelStoreTitle
                            : l10n.teacherUpgradeCancelConfirm,
                      ),
              ),
            ],
          ] else ...[
            // CTA principal
            SizedBox(
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teacherAccent,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _purchasing ? null : _buy,
                child: _purchasing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.background))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.school_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            l10n.teacherUpgradeCta,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.teacherUpgradeCancelHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const UpgradePlanPage(),
                  ),
                );
              },
              child: Text(l10n.teacherUpgradeSeeAllPlans),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  String _activePlanBannerMessage(AppLocalizations l10n) {
    final subscription = _subscription;
    if (subscription == null) {
      return l10n.teacherUpgradeAlreadyActive;
    }
    return BillingDisplay.activePlanBannerMessage(
      context,
      l10n,
      planName: BillingDisplay.localizedPlanName(l10n, code: 'teacher'),
      subscription: subscription,
      activeMessage: l10n.teacherUpgradeAlreadyActive,
    );
  }

  Widget _pillar({
    required IconData icon,
    required String title,
    required String body,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Patrón de cuadrícula sutil para el hero background.
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.teacherAccent.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPatternPainter _) => false;
}
