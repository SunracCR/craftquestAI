import 'package:flutter/foundation.dart';

import 'paypal_return_persist_stub.dart'
    if (dart.library.html) 'paypal_return_persist_web.dart' as persist;

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

  Map<String, dynamic> toJson() => {
        'isCancel': isCancel,
        'token': token,
        'subscriptionId': subscriptionId,
      };

  factory PendingPayPalReturn.fromJson(Map<String, dynamic> json) {
    return PendingPayPalReturn(
      isCancel: json['isCancel'] == true,
      token: json['token'] as String?,
      subscriptionId: json['subscriptionId'] as String?,
    );
  }
}

PendingPayPalReturn? readWebPayPalReturn() {
  if (!kIsWeb) {
    return null;
  }

  final fromUrl = _readPayPalReturnFromUri(Uri.base);
  if (fromUrl != null) {
    persist.persistWebPayPalReturnJson(fromUrl.toJson());
    return fromUrl;
  }

  final stored = persist.readPersistedWebPayPalReturnJson();
  if (stored == null) {
    return null;
  }
  return PendingPayPalReturn.fromJson(stored);
}

void consumeWebPayPalReturn() {
  persist.clearPersistedWebPayPalReturn();
}

PendingPayPalReturn? _readPayPalReturnFromUri(Uri uri) {
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
