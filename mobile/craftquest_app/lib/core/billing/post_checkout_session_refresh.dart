import 'package:craftquest_app/core/billing/checkout_refresh_notifier.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tras un checkout (PayPal, mock, etc.): renueva JWT, perfil/roles y billing en caché.
Future<void> refreshAppSessionAfterCheckout(BuildContext context) async {
  final authRepo = getIt<AuthRepository>();
  final billingRepo = getIt<BillingRepository>();

  try {
    final profile = await authRepo.refreshSession();
    if (context.mounted) {
      context.read<AuthBloc>().add(AuthProfileUpdated(profile));
    }
  } catch (_) {
    try {
      final profile = await authRepo.getProfile();
      if (context.mounted) {
        context.read<AuthBloc>().add(AuthProfileUpdated(profile));
      }
    } catch (_) {
      // Mantener estado actual si falla la red.
    }
  }

  await billingRepo.getMyBilling(forceRefresh: true);

  if (context.mounted) {
    getIt<CheckoutRefreshNotifier>().notifyCheckoutCompleted();
  }
}
