import 'package:flutter/foundation.dart';

class PendingPayPalReturn {
  const PendingPayPalReturn({
    this.isCancel = false,
    this.token,
    this.subscriptionId,
  });

  final bool isCancel;
  final String? token;
  final String? subscriptionId;

  String get dedupeKey => isCancel
      ? 'cancel'
      : '${subscriptionId ?? ''}:${token ?? ''}';
}

PendingPayPalReturn? readWebPayPalReturn() {
  if (!kIsWeb) {
    return null;
  }

  final uri = Uri.base;
  final path = uri.path.toLowerCase();

  if (path.contains('billing/paypal/cancel')) {
    return const PendingPayPalReturn(isCancel: true);
  }

  if (!path.contains('billing/paypal/return')) {
    return null;
  }

  final subscriptionId = _readQueryValue(uri, const [
    'subscription_id',
    'subscriptionId',
  ]);
  final token = _readQueryValue(uri, const [
    'token',
    'orderId',
    'order_id',
  ]);

  if ((subscriptionId == null || subscriptionId.isEmpty) &&
      (token == null || token.isEmpty)) {
    return const PendingPayPalReturn();
  }

  return PendingPayPalReturn(
    token: token,
    subscriptionId: subscriptionId,
  );
}

String? _readQueryValue(Uri uri, List<String> keys) {
  for (final key in keys) {
    final value = uri.queryParameters[key]?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}
