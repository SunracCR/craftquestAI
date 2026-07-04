import 'dart:async';

import 'package:craftquest_app/core/billing/post_checkout_session_refresh.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/navigation/app_keys.dart';
import 'package:craftquest_app/core/navigation/web_entry_url_cleanup.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/billing/data/pending_paypal_payment_store.dart';
import 'package:craftquest_app/features/billing/presentation/paypal_return_launch.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:craftquest_app/features/prep_plus/presentation/prep_plus_item_detail_page.dart';
import 'package:craftquest_app/features/shell/presentation/main_shell_tab_signal.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

enum _PayPalReturnStatus { processing, error, cancelled }

class PayPalReturnPage extends StatefulWidget {
  const PayPalReturnPage({
    super.key,
    required this.returnInfo,
  });

  final PendingPayPalReturn returnInfo;

  @override
  State<PayPalReturnPage> createState() => _PayPalReturnPageState();
}

class _PayPalReturnPageState extends State<PayPalReturnPage> {
  final _billingRepository = getIt<BillingRepository>();
  final _prepRepository = getIt<PrepPlusRepository>();
  final _paymentStore = getIt<PendingPayPalPaymentStore>();

  _PayPalReturnStatus _status = _PayPalReturnStatus.processing;
  String? _message;
  bool _continuing = false;
  PendingPayPalPayment? _pending;

  @override
  void initState() {
    super.initState();
    unawaited(_completeReturn());
  }

  Future<void> _completeReturn() async {
    final pending = await _paymentStore.read();
    if (mounted) {
      setState(() => _pending = pending);
    }

    if (widget.returnInfo.isCancel) {
      await _paymentStore.clear();
      if (!mounted) return;
      setState(() {
        _status = _PayPalReturnStatus.cancelled;
        _message = AppLocalizations.of(context)!.paypalReturnCancelled;
      });
      return;
    }

    setState(() {
      _status = _PayPalReturnStatus.processing;
      _message = null;
    });

    try {
      final l10n = AppLocalizations.of(context)!;

      if (widget.returnInfo.subscriptionId != null &&
          widget.returnInfo.subscriptionId!.isNotEmpty) {
        final subscriptionId = widget.returnInfo.subscriptionId!;
        await _billingRepository.activatePayPalSubscription(
          subscriptionId,
          billingCycle: _pending?.billingCycle,
        );
        await _handleCheckoutSuccess(
          message: l10n.paypalReturnSuccessSubscription,
        );
        return;
      }

      final orderId = widget.returnInfo.token ?? _pending?.id;
      if (orderId == null || orderId.isEmpty) {
        throw StateError(l10n.paypalReturnError);
      }

      final flow = _pending?.flow ?? PendingPayPalPaymentFlow.billingOrder;
      if (flow == PendingPayPalPaymentFlow.prep) {
        final result = await _prepRepository.capturePayPalOrder(orderId);
        if (!mounted) return;
        if (result.status != 'granted') {
          throw StateError(result.message ?? l10n.paypalReturnError);
        }
        await _handleCheckoutSuccess(message: l10n.paypalReturnSuccessPrep);
      } else if (flow == PendingPayPalPaymentFlow.aiCredit) {
        await _billingRepository.capturePayPalAiCreditOrder(orderId);
        if (!mounted) return;
        await _handleCheckoutSuccess(
          message: l10n.paypalReturnSuccessCredits,
        );
      } else if (flow == PendingPayPalPaymentFlow.subscription) {
        await _billingRepository.activatePayPalSubscription(
          orderId,
          billingCycle: _pending?.billingCycle,
        );
        if (!mounted) return;
        await _handleCheckoutSuccess(
          message: l10n.paypalReturnSuccessSubscription,
        );
      } else {
        await _billingRepository.capturePayPalOrder(orderId);
        if (!mounted) return;
        await _handleCheckoutSuccess(
          message: l10n.paypalReturnSuccessOrder,
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _PayPalReturnStatus.error;
        _message = DioErrorMapper.map(e, AppLocalizations.of(context));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _PayPalReturnStatus.error;
        _message = e.toString().replaceFirst('StateError: ', '');
      });
    }
  }

  Future<void> _handleCheckoutSuccess({
    required String message,
  }) async {
    if (!mounted) return;

    final isPrep = _pending?.flow == PendingPayPalPaymentFlow.prep;

    await _paymentStore.clear();

    if (mounted) {
      await refreshAppSessionAfterCheckout(
        context,
        affectsHomeTab: !isPrep,
      );
    }

    clearWebEntryDeepLinkUrl();

    if (!mounted) return;

    AppSnackBars.showSuccess(message);
    _returnToOrigin();
  }

  void _returnToOrigin() {
    final catalogItemId = _pending?.catalogItemId;
    final isPrepReturn = _pending?.flow == PendingPayPalPaymentFlow.prep &&
        catalogItemId != null &&
        catalogItemId.isNotEmpty;

    if (isPrepReturn) {
      getIt<MainShellTabSignal>().requestTab(kPrepPlusTabIndex);
    }

    final navigator = rootNavigatorKey.currentState;
    navigator?.popUntil((route) => route.isFirst);

    if (isPrepReturn) {
      navigator?.push(
        MaterialPageRoute<void>(
          builder: (_) => PrepPlusItemDetailPage(catalogItemId: catalogItemId!),
        ),
      );
    }
  }

  Future<void> _continue() async {
    if (_continuing) {
      return;
    }
    setState(() => _continuing = true);

    await _paymentStore.clear();
    clearWebEntryDeepLinkUrl();

    if (!mounted) {
      return;
    }

    _returnToOrigin();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.paypalReturnTitle),
      body: Padding(
        padding: AppSpacing.pageVertical,
        child: _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    switch (_status) {
      case _PayPalReturnStatus.processing:
        return AppLoadingView(message: l10n.paypalReturnProcessing);
      case _PayPalReturnStatus.cancelled:
        return _ResultView(
          icon: Icons.cancel_outlined,
          iconColor: AppColors.textSecondary,
          title: l10n.paypalReturnCancelled,
          primaryLabel: l10n.paypalReturnContinue,
          primaryLoading: _continuing,
          onPrimary: _continue,
        );
      case _PayPalReturnStatus.error:
        return _ResultView(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
          title: l10n.paypalReturnError,
          subtitle: _message,
          primaryLabel: l10n.retry,
          primaryLoading: false,
          onPrimary: _completeReturn,
          secondaryLabel: l10n.paypalReturnContinue,
          secondaryLoading: _continuing,
          onSecondary: _continue,
        );
    }
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.primaryLabel,
    required this.primaryLoading,
    required this.onPrimary,
    this.secondaryLabel,
    this.secondaryLoading = false,
    this.onSecondary,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String primaryLabel;
  final bool primaryLoading;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final bool secondaryLoading;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Icon(icon, size: 56, color: iconColor),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
        const Spacer(),
        AppGradientPrimaryButton(
          label: primaryLabel,
          isLoading: primaryLoading,
          onPressed: primaryLoading ? null : onPrimary,
        ),
        if (secondaryLabel != null && onSecondary != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: secondaryLoading ? null : onSecondary,
            child: Text(secondaryLabel!),
          ),
        ],
      ],
    );
  }
}
