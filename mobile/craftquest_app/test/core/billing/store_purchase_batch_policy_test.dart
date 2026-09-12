import 'package:craftquest_app/core/billing/store_purchase_batch_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorePurchaseBatchPolicy', () {
    test('batchContainsSuccessfulPurchase matches normalized ids', () {
      expect(
        StorePurchaseBatchPolicy.batchContainsSuccessfulPurchase(
          const ['craftquest_teacher_annual'],
          'craftquest_teacher_annual',
        ),
        isTrue,
      );
    });

    test('shouldIgnoreTerminalFailure when batch has purchased event', () {
      expect(
        StorePurchaseBatchPolicy.shouldIgnoreTerminalFailure(
          matchesActiveRequest: true,
          batchHasSuccessfulForProduct: true,
          isVerifyingOrSucceeded: false,
          hasInFlightVerificationForProduct: false,
        ),
        isTrue,
      );
    });

    test('shouldIgnoreTerminalFailure when verification is in flight', () {
      expect(
        StorePurchaseBatchPolicy.shouldIgnoreTerminalFailure(
          matchesActiveRequest: true,
          batchHasSuccessfulForProduct: false,
          isVerifyingOrSucceeded: false,
          hasInFlightVerificationForProduct: true,
        ),
        isTrue,
      );
    });

    test('should not ignore unrelated product failures', () {
      expect(
        StorePurchaseBatchPolicy.shouldIgnoreTerminalFailure(
          matchesActiveRequest: false,
          batchHasSuccessfulForProduct: true,
          isVerifyingOrSucceeded: true,
          hasInFlightVerificationForProduct: true,
        ),
        isFalse,
      );
    });
  });
}
