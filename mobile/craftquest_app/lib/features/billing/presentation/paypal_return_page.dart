import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/navigation/app_keys.dart';
import 'package:craftquest_app/core/navigation/web_entry_url_cleanup.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/billing_display.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/billing/data/pending_paypal_payment_store.dart';
import 'package:craftquest_app/features/billing/presentation/paypal_return_launch.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _PayPalReturnStatus { processing, success, error, cancelled }

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
  String? _successDetail;
  bool _continuing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_completeReturn());
  }

  Future<void> _completeReturn() async {
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
      _successDetail = null;
    });

    try {
      final pending = await _paymentStore.read();
      final l10n = AppLocalizations.of(context)!;

      if (widget.returnInfo.subscriptionId != null &&
          widget.returnInfo.subscriptionId!.isNotEmpty) {
        final subscriptionId = widget.returnInfo.subscriptionId!;
        final activated = await _billingRepository.activatePayPalSubscription(
          subscriptionId,
          billingCycle: pending?.billingCycle,
        );
        if (!mounted) return;
        setState(() {
          _status = _PayPalReturnStatus.success;
          _message = l10n.paypalReturnSuccessSubscription;
          _successDetail = BillingDisplay.localizedPlanName(
            l10n,
            code: activated.planCode,
          );
        });
        context.read<AuthBloc>().add(const AuthProfileRefreshRequested());
        await _paymentStore.clear();
        return;
      }

      final orderId = widget.returnInfo.token ?? pending?.id;
      if (orderId == null || orderId.isEmpty) {
        throw StateError(l10n.paypalReturnError);
      }

      final flow = pending?.flow ?? PendingPayPalPaymentFlow.billingOrder;
      if (flow == PendingPayPalPaymentFlow.prep) {
        final result = await _prepRepository.capturePayPalOrder(orderId);
        if (!mounted) return;
        if (result.status != 'granted') {
          throw StateError(result.message ?? l10n.paypalReturnError);
        }
        setState(() {
          _status = _PayPalReturnStatus.success;
          _message = l10n.paypalReturnSuccessPrep;
        });
      } else if (flow == PendingPayPalPaymentFlow.aiCredit) {
        final captured =
            await _billingRepository.capturePayPalAiCreditOrder(orderId);
        if (!mounted) return;
        setState(() {
          _status = _PayPalReturnStatus.success;
          _message = l10n.paypalReturnSuccessCredits;
          _successDetail = captured.creditsGranted.toString();
        });
      } else if (flow == PendingPayPalPaymentFlow.subscription) {
        final activated = await _billingRepository.activatePayPalSubscription(
          orderId,
          billingCycle: pending?.billingCycle,
        );
        if (!mounted) return;
        setState(() {
          _status = _PayPalReturnStatus.success;
          _message = l10n.paypalReturnSuccessSubscription;
          _successDetail = BillingDisplay.localizedPlanName(
            l10n,
            code: activated.planCode,
          );
        });
        context.read<AuthBloc>().add(const AuthProfileRefreshRequested());
      } else {
        final captured = await _billingRepository.capturePayPalOrder(orderId);
        if (!mounted) return;
        setState(() {
          _status = _PayPalReturnStatus.success;
          _message = l10n.paypalReturnSuccessOrder;
          _successDetail = BillingDisplay.localizedPlanName(
            l10n,
            code: captured.planCode,
          );
        });
        context.read<AuthBloc>().add(const AuthProfileRefreshRequested());
      }

      await _paymentStore.clear();
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

  Future<void> _continue() async {
    if (_continuing) {
      return;
    }
    setState(() => _continuing = true);

    await _paymentStore.clear();
    clearWebEntryDeepLinkUrl();
    unawaited(_billingRepository.getMyBilling(forceRefresh: true));

    if (!mounted) {
      return;
    }

    if (_status == _PayPalReturnStatus.success && _message != null) {
      context.showSuccessSnackBar(_message!);
    }

    rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
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
      case _PayPalReturnStatus.success:
        return _ResultView(
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppColors.accentMint,
          title: _message ?? l10n.paypalReturnSuccessOrder,
          subtitle: _successDetail,
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
