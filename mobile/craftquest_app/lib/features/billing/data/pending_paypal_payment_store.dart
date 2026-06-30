import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum PendingPayPalPaymentFlow {
  subscription,
  prep,
  aiCredit,
  billingOrder,
}

class PendingPayPalPayment {
  const PendingPayPalPayment({
    required this.flow,
    required this.id,
    required this.createdAt,
    this.billingCycle,
    this.planCode,
    this.catalogItemId,
    this.offerId,
    this.packCode,
  });

  final PendingPayPalPaymentFlow flow;
  final String id;
  final DateTime createdAt;
  final String? billingCycle;
  final String? planCode;
  final String? catalogItemId;
  final String? offerId;
  final String? packCode;

  Map<String, dynamic> toJson() => {
        'flow': flow.name,
        'id': id,
        'createdAt': createdAt.toUtc().toIso8601String(),
        if (billingCycle != null) 'billingCycle': billingCycle,
        if (planCode != null) 'planCode': planCode,
        if (catalogItemId != null) 'catalogItemId': catalogItemId,
        if (offerId != null) 'offerId': offerId,
        if (packCode != null) 'packCode': packCode,
      };

  factory PendingPayPalPayment.fromJson(Map<String, dynamic> json) {
    final flowName = json['flow'] as String? ?? '';
    final flow = PendingPayPalPaymentFlow.values.firstWhere(
      (value) => value.name == flowName,
      orElse: () => PendingPayPalPaymentFlow.billingOrder,
    );

    return PendingPayPalPayment(
      flow: flow,
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      billingCycle: json['billingCycle'] as String?,
      planCode: json['planCode'] as String?,
      catalogItemId: json['catalogItemId'] as String?,
      offerId: json['offerId'] as String?,
      packCode: json['packCode'] as String?,
    );
  }
}

class PendingPayPalPaymentStore {
  PendingPayPalPaymentStore(this._preferencesFuture);

  static const _storageKey = 'pending_paypal_payment';
  static const _maxAge = Duration(hours: 1);

  final Future<SharedPreferences> _preferencesFuture;

  Future<void> save(PendingPayPalPayment payment) async {
    final prefs = await _preferencesFuture;
    await prefs.setString(_storageKey, jsonEncode(payment.toJson()));
  }

  Future<PendingPayPalPayment?> read() async {
    final prefs = await _preferencesFuture;
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final payment = PendingPayPalPayment.fromJson(decoded);
      if (payment.id.isEmpty) {
        await clear();
        return null;
      }

      if (DateTime.now().toUtc().difference(payment.createdAt.toUtc()) > _maxAge) {
        await clear();
        return null;
      }

      return payment;
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await _preferencesFuture;
    await prefs.remove(_storageKey);
  }
}
