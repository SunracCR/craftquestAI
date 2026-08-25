import 'package:craftquest_app/core/billing/ios_store_unfinished_transactions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isIosDuplicateUnfinishedStoreError', () {
    test('detects storekit_duplicate_product_object code', () {
      final error = PlatformException(
        code: 'storekit_duplicate_product_object',
        message:
            'There is a pending transaction for the same product identifier.',
      );

      expect(isIosDuplicateUnfinishedStoreError(error), isTrue);
    });

    test('detects pending transaction message', () {
      final error = PlatformException(
        code: 'purchase_error',
        message:
            'There is a pending transaction for the same product identifier.',
      );

      expect(isIosDuplicateUnfinishedStoreError(error), isTrue);
    });

    test('ignores unrelated store errors', () {
      final error = PlatformException(
        code: 'storekit2_failed_to_fetch_product',
        message: 'Product not found',
      );

      expect(isIosDuplicateUnfinishedStoreError(error), isFalse);
    });
  });
}
