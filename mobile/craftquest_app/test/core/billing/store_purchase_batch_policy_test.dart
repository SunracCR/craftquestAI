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
        ),
        isTrue,
      );
    });

    test('a confirmed rejection is not ignored because verification started', () {
      expect(
        StorePurchaseBatchPolicy.shouldIgnoreTerminalFailure(
          matchesActiveRequest: true,
          batchHasSuccessfulForProduct: false,
        ),
        isFalse,
      );
    });

    test('should not ignore unrelated product failures', () {
      expect(
        StorePurchaseBatchPolicy.shouldIgnoreTerminalFailure(
          matchesActiveRequest: false,
          batchHasSuccessfulForProduct: true,
        ),
        isFalse,
      );
    });

    test('restored or tokenless events do not drive the confirming overlay', () {
      expect(
        StorePurchaseBatchPolicy.drivesActivePurchaseUi(
          inFlight: true,
          productMatchesActiveRequest: true,
          isRestored: true,
          hasProductId: true,
          hasPurchaseToken: true,
        ),
        isFalse,
      );
      expect(
        StorePurchaseBatchPolicy.drivesActivePurchaseUi(
          inFlight: true,
          productMatchesActiveRequest: true,
          isRestored: false,
          hasProductId: false,
          hasPurchaseToken: false,
        ),
        isFalse,
      );
      expect(
        StorePurchaseBatchPolicy.drivesActivePurchaseUi(
          inFlight: false,
          productMatchesActiveRequest: true,
          isRestored: false,
          hasProductId: true,
          hasPurchaseToken: true,
        ),
        isFalse,
      );
    });

    test('a real purchased token drives the confirming overlay', () {
      expect(
        StorePurchaseBatchPolicy.drivesActivePurchaseUi(
          inFlight: true,
          productMatchesActiveRequest: true,
          isRestored: false,
          hasProductId: true,
          hasPurchaseToken: true,
        ),
        isTrue,
      );
    });

    test('background cancel surfaces while the payment sheet is open', () {
      expect(
        StorePurchaseBatchPolicy.shouldSurfaceTerminalFailure(
          listenerMarkedBackground: true,
          inFlight: true,
          waitingForStoreOutcome: true,
          productIdEmpty: true,
          productMatchesActiveRequest: false,
        ),
        isTrue,
      );
    });

    test('background cancel still surfaces after verification started', () {
      expect(
        StorePurchaseBatchPolicy.shouldSurfaceTerminalFailure(
          listenerMarkedBackground: true,
          inFlight: true,
          waitingForStoreOutcome: true,
          productIdEmpty: true,
          productMatchesActiveRequest: false,
        ),
        isTrue,
      );
    });

    test('background cancel is ignored when no checkout is waiting', () {
      expect(
        StorePurchaseBatchPolicy.shouldSurfaceTerminalFailure(
          listenerMarkedBackground: true,
          inFlight: false,
          waitingForStoreOutcome: false,
          productIdEmpty: true,
          productMatchesActiveRequest: false,
        ),
        isFalse,
      );
    });
  });
}
