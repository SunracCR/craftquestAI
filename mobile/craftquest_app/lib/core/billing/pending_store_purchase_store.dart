import 'dart:convert';

import 'package:craftquest_app/core/billing/purchase_flow_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingStorePurchase {
  const PendingStorePurchase({
    required this.kind,
    required this.productId,
    required this.createdAt,
    this.billingCycle,
    this.catalogItemId,
    this.offerId,
    this.referralCode,
  });

  final PurchaseProductKind kind;
  final String productId;
  final DateTime createdAt;
  final String? billingCycle;
  final String? catalogItemId;
  final String? offerId;
  final String? referralCode;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'productId': productId,
        'createdAt': createdAt.toUtc().toIso8601String(),
        if (billingCycle != null) 'billingCycle': billingCycle,
        if (catalogItemId != null) 'catalogItemId': catalogItemId,
        if (offerId != null) 'offerId': offerId,
        if (referralCode != null) 'referralCode': referralCode,
      };

  factory PendingStorePurchase.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? '';
    final kind = PurchaseProductKind.values.firstWhere(
      (value) => value.name == kindName,
      orElse: () => PurchaseProductKind.subscription,
    );

    return PendingStorePurchase(
      kind: kind,
      productId: json['productId'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      billingCycle: json['billingCycle'] as String?,
      catalogItemId: json['catalogItemId'] as String?,
      offerId: json['offerId'] as String?,
      referralCode: json['referralCode'] as String?,
    );
  }
}

class PendingStorePurchaseStore {
  PendingStorePurchaseStore(this._preferencesFuture);

  static const _storageKey = 'pending_store_purchase';
  static const _maxAge = Duration(hours: 24);

  final Future<SharedPreferences> _preferencesFuture;

  Future<void> save(PendingStorePurchase purchase) async {
    final prefs = await _preferencesFuture;
    await prefs.setString(_storageKey, jsonEncode(purchase.toJson()));
  }

  Future<PendingStorePurchase?> read() async {
    final prefs = await _preferencesFuture;
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final purchase = PendingStorePurchase.fromJson(decoded);
      if (purchase.productId.isEmpty) {
        await clear();
        return null;
      }

      if (DateTime.now().toUtc().difference(purchase.createdAt.toUtc()) >
          _maxAge) {
        await clear();
        return null;
      }

      return purchase;
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
