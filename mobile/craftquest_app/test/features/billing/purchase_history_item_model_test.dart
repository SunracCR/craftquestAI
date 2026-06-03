import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PurchaseHistoryItemModel', () {
    test('fromJson parses subscription purchase', () {
      final model = PurchaseHistoryItemModel.fromJson({
        'purchaseId': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'productCode': 'pro',
        'productDisplayName': 'Pro',
        'productType': 'subscription',
        'providerCode': 'paypal',
        'amount': 4.99,
        'currencyCode': 'USD',
        'status': 'validated',
        'purchasedAt': '2026-03-01T12:00:00Z',
        'createdAt': '2026-03-01T11:59:00Z',
      });

      expect(model.purchaseId, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(model.productCode, 'pro');
      expect(model.productDisplayName, 'Pro');
      expect(model.productType, 'subscription');
      expect(model.providerCode, 'paypal');
      expect(model.amount, 4.99);
      expect(model.currencyCode, 'USD');
      expect(model.status, 'validated');
      expect(model.purchasedAt, DateTime.parse('2026-03-01T12:00:00Z'));
      expect(model.createdAt, DateTime.parse('2026-03-01T11:59:00Z'));
      expect(model.occurredAt, model.purchasedAt);
    });

    test('fromJson uses createdAt when purchasedAt is null', () {
      final model = PurchaseHistoryItemModel.fromJson({
        'purchaseId': '11111111-2222-3333-4444-555555555555',
        'productCode': 'pro',
        'productType': 'subscription',
        'providerCode': 'paypal',
        'status': 'pending',
        'createdAt': '2026-01-15T08:30:00Z',
      });

      expect(model.purchasedAt, isNull);
      expect(model.occurredAt, DateTime.parse('2026-01-15T08:30:00Z'));
      expect(model.productDisplayName, isNull);
      expect(model.amount, isNull);
    });
  });
}
