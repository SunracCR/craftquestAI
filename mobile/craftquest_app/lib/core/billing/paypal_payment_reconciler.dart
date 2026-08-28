import 'package:craftquest_app/core/billing/post_checkout_session_refresh.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/l10n/localized_message_holder.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/billing/data/pending_paypal_payment_store.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Confirma pagos PayPal pendientes al volver a la app (móvil nativo).
class PayPalPaymentReconciler {
  PayPalPaymentReconciler({
    PendingPayPalPaymentStore? paymentStore,
    BillingRepository? billingRepository,
    PrepPlusRepository? prepPlusRepository,
  })  : _paymentStore = paymentStore ?? getIt<PendingPayPalPaymentStore>(),
        _billingRepository = billingRepository ?? getIt<BillingRepository>(),
        _prepPlusRepository = prepPlusRepository ?? getIt<PrepPlusRepository>();

  final PendingPayPalPaymentStore _paymentStore;
  final BillingRepository _billingRepository;
  final PrepPlusRepository _prepPlusRepository;

  bool _reconciling = false;

  Future<bool> tryReconcileOnAppResume() async {
    if (kIsWeb || _reconciling) {
      return false;
    }

    _reconciling = true;
    try {
      var fulfilled = false;

      final pending = await _paymentStore.read();
      if (pending != null) {
        fulfilled = await _tryFulfillLocalPending(pending);
      }

      try {
        final serverResult = await _billingRepository.reconcilePendingPurchases();
        if (serverResult.fulfilledCount > 0) {
          fulfilled = true;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[PayPal] server reconcile failed: $e');
        }
      }

      if (fulfilled) {
        await refreshBillingAfterStorePurchase(
          affectsHomeTab: pending?.flow != PendingPayPalPaymentFlow.prep,
        );
        _showSuccessMessage(pending?.flow);
      }

      return fulfilled;
    } finally {
      _reconciling = false;
    }
  }

  Future<bool> tryFulfillStoredPending({bool showMessage = true}) async {
    final pending = await _paymentStore.read();
    if (pending == null) {
      return false;
    }

    final fulfilled = await _tryFulfillLocalPending(pending);
    if (fulfilled) {
      await refreshBillingAfterStorePurchase(
        affectsHomeTab: pending.flow != PendingPayPalPaymentFlow.prep,
      );
      if (showMessage) {
        _showSuccessMessage(pending.flow);
      }
    }
    return fulfilled;
  }

  static const _subscriptionRetryDelays = [
    Duration.zero,
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 6),
    Duration(seconds: 8),
  ];

  Future<bool> _tryFulfillLocalPending(PendingPayPalPayment pending) async {
    for (var attempt = 0; attempt < _subscriptionRetryDelays.length; attempt++) {
      final delay = _subscriptionRetryDelays[attempt];
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      try {
        var retryPrepCapture = false;
        switch (pending.flow) {
          case PendingPayPalPaymentFlow.subscription:
            await _billingRepository.activatePayPalSubscription(
              pending.id,
              billingCycle: pending.billingCycle,
            );
          case PendingPayPalPaymentFlow.aiCredit:
            await _billingRepository.capturePayPalAiCreditOrder(pending.id);
          case PendingPayPalPaymentFlow.prep:
            final result = await _prepPlusRepository.capturePayPalOrder(pending.id);
            if (result.status != 'granted') {
              retryPrepCapture = _shouldRetryPayPalFulfillment(
                null,
                pending.flow,
                attempt,
              );
              if (!retryPrepCapture) {
                return false;
              }
            }
          case PendingPayPalPaymentFlow.billingOrder:
            await _billingRepository.capturePayPalOrder(pending.id);
        }

        if (retryPrepCapture) {
          continue;
        }

        await _paymentStore.clear();
        return true;
      } on DioException catch (e) {
        if (_isAlreadyFulfilled(e)) {
          await _paymentStore.clear();
          return true;
        }
        if (_shouldRetryPayPalFulfillment(e, pending.flow, attempt)) {
          continue;
        }
        if (kDebugMode) {
          debugPrint(
            '[PayPal] local fulfill failed flow=${pending.flow} '
            'id=${pending.id} attempt=$attempt: $e',
          );
        }
        return false;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[PayPal] local fulfill failed flow=${pending.flow} id=${pending.id}: $e');
        }
        return false;
      }
    }

    return false;
  }

  bool _shouldRetryPayPalFulfillment(
    DioException? error,
    PendingPayPalPaymentFlow flow,
    int attempt,
  ) {
    if (attempt >= _subscriptionRetryDelays.length - 1) {
      return false;
    }

    if (flow == PendingPayPalPaymentFlow.subscription) {
      if (error == null) {
        return false;
      }
      final code = _readErrorCode(error);
      return code == 'PAYPAL_SUBSCRIPTION_NOT_ACTIVE';
    }

    if (flow != PendingPayPalPaymentFlow.prep) {
      return false;
    }

    if (error == null) {
      return true;
    }

    final status = error.response?.statusCode;
    if (status == null || status >= 500 || status == 409) {
      return true;
    }

    final code = _readErrorCode(error)?.toUpperCase() ?? '';
    return code.contains('NOT_APPROVED') || code.contains('NOT_CAPTUREABLE');
  }

  String? _readErrorCode(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return data['code']?.toString();
    }
    return null;
  }

  bool _isAlreadyFulfilled(DioException error) {
    final code = _readErrorCode(error)?.toLowerCase() ?? '';
    if (code == 'paypal_subscription_not_active') {
      return false;
    }
    if (code.contains('already') || code.contains('validated')) {
      return true;
    }

    final status = error.response?.statusCode;
    return status == 200;
  }

  void _showSuccessMessage(PendingPayPalPaymentFlow? flow) {
    final l10n = LocalizedMessageHolder.current;
    if (l10n == null) {
      return;
    }

    final message = switch (flow) {
      PendingPayPalPaymentFlow.subscription => l10n.paypalReturnSuccessSubscription,
      PendingPayPalPaymentFlow.aiCredit => l10n.paypalReturnSuccessCredits,
      PendingPayPalPaymentFlow.prep => l10n.paypalReturnSuccessPrep,
      PendingPayPalPaymentFlow.billingOrder => l10n.paypalReturnSuccessOrder,
      null => l10n.paypalReturnSuccessOrder,
    };

    AppSnackBars.showSuccess(message);
  }
}
