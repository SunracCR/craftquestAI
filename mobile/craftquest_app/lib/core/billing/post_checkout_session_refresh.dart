import 'dart:async';

import 'package:craftquest_app/core/billing/checkout_refresh_notifier.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tras un checkout (PayPal, mock, IAP, etc.): renueva JWT, perfil/roles y billing.
Future<void> refreshAppSessionAfterCheckout(
  BuildContext context, {
  bool affectsHomeTab = true,
  Duration authTimeout = const Duration(seconds: 20),
  Duration billingTimeout = const Duration(seconds: 20),
}) async {
  getIt<BillingRepository>().invalidateMyBillingCache();
  await _refreshAuthBestEffort(context, timeout: authTimeout);
  await _refreshBillingBestEffort(
    context: context,
    affectsHomeTab: affectsHomeTab,
    timeout: billingTimeout,
  );
}

/// Refresh de billing cuando no hay [BuildContext] (p. ej. coordinador en background).
Future<void> refreshBillingAfterStorePurchase({
  bool affectsHomeTab = true,
}) async {
  getIt<BillingRepository>().invalidateMyBillingCache();

  final authRepo = getIt<AuthRepository>();
  try {
    await authRepo.refreshSession().timeout(const Duration(seconds: 20));
  } catch (_) {
    try {
      await authRepo.getProfile().timeout(const Duration(seconds: 15));
    } catch (_) {
      // Mantener sesión actual si falla la red.
    }
  }

  await _refreshBillingBestEffort(
    affectsHomeTab: affectsHomeTab,
    timeout: const Duration(seconds: 20),
  );
}

Future<void> _refreshAuthBestEffort(
  BuildContext context, {
  required Duration timeout,
}) async {
  final authRepo = getIt<AuthRepository>();

  try {
    final profile = await authRepo.refreshSession().timeout(timeout);
    if (context.mounted) {
      context.read<AuthBloc>().add(AuthProfileUpdated(profile));
    }
  } catch (_) {
    try {
      final profile =
          await authRepo.getProfile().timeout(const Duration(seconds: 15));
      if (context.mounted) {
        context.read<AuthBloc>().add(AuthProfileUpdated(profile));
      }
    } catch (_) {
      // Mantener estado actual si falla la red.
    }
  }
}

Future<void> _refreshBillingBestEffort({
  BuildContext? context,
  bool affectsHomeTab = true,
  required Duration timeout,
}) async {
  try {
    final billing = await getIt<BillingRepository>()
        .getMyBilling(forceRefresh: true)
        .timeout(timeout);

    if (context != null && !context.mounted) {
      return;
    }

    getIt<CheckoutRefreshNotifier>().notifyCheckoutCompleted(
      billing: billing,
      affectsHomeTab: affectsHomeTab,
    );
  } catch (_) {
    // Mantener UI actual; el usuario puede refrescar manualmente.
  }
}

/// Si otro listener ya procesó la compra, refresca billing tras un breve delay.
void scheduleDeferredCheckoutRefresh(
  BuildContext context, {
  Duration delay = const Duration(milliseconds: 1500),
}) {
  unawaited(Future<void>(() async {
    await Future.delayed(delay);
    if (!context.mounted) {
      return;
    }
    await refreshAppSessionAfterCheckout(context);
  }));
}
