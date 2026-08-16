import 'package:craftquest_app/core/billing/checkout_refresh_notifier.dart';
import 'package:craftquest_app/core/billing/post_checkout_session_refresh.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/navigation/app_keys.dart';
import 'package:craftquest_app/core/utils/billing_plan_access.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';

/// Sincroniza billing (y perfil si aplica) tras webhooks de membresía o resume.
class MembershipBillingRefreshCoordinator {
  static const _resumeThrottle = Duration(seconds: 60);

  static const _billingOnlyTypes = {
    'membership_expiring',
    'payment_issue_pending',
  };

  static const _sessionRefreshTypes = {
    'membership_expired',
  };

  DateTime? _lastResumeRefreshAt;

  bool shouldRefreshForNotification(String? type) {
    if (type == null || type.isEmpty) {
      return false;
    }
    return _billingOnlyTypes.contains(type) || _sessionRefreshTypes.contains(type);
  }

  Future<void> refreshForNotification(String type) async {
    if (!shouldRefreshForNotification(type)) {
      return;
    }

    if (_sessionRefreshTypes.contains(type)) {
      await _refreshSessionAndBilling();
      return;
    }

    await _refreshBillingOnly();
  }

  Future<void> refreshOnAppResume() async {
    final now = DateTime.now();
    if (_lastResumeRefreshAt != null &&
        now.difference(_lastResumeRefreshAt!) < _resumeThrottle) {
      return;
    }

    final billingRepo = getIt<BillingRepository>();
    final cached = billingRepo.cachedBilling;
    if (cached == null || !BillingPlanAccess.isPaidPlan(cached.plan.code)) {
      return;
    }

    _lastResumeRefreshAt = now;
    await _refreshBillingOnly();
  }

  Future<void> _refreshBillingOnly() async {
    try {
      final billing =
          await getIt<BillingRepository>().getMyBilling(forceRefresh: true);
      getIt<CheckoutRefreshNotifier>().notifyCheckoutCompleted(
        billing: billing,
      );
    } catch (_) {
      // Mantener UI actual si falla la red.
    }
  }

  Future<void> _refreshSessionAndBilling() async {
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      await refreshAppSessionAfterCheckout(context);
      return;
    }

    final authRepo = getIt<AuthRepository>();
    try {
      await authRepo.refreshSession();
    } catch (_) {
      try {
        await authRepo.getProfile();
      } catch (_) {
        // Sin red: solo intentamos billing.
      }
    }

    await _refreshBillingOnly();
  }
}
