import 'package:craftquest_app/core/utils/billing_plan_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillingPlanAccess.canDownloadOfflineForQuiz', () {
    test('allows free plan when user has active quiz access', () {
      expect(
        BillingPlanAccess.canDownloadOfflineForQuiz(
          planCode: 'free',
          hasActiveQuizAccess: true,
        ),
        isTrue,
      );
    });

    test('blocks free plan without quiz access', () {
      expect(
        BillingPlanAccess.canDownloadOfflineForQuiz(
          planCode: 'free',
          hasActiveQuizAccess: false,
        ),
        isFalse,
      );
    });

    test('allows paid plan without quiz access', () {
      expect(
        BillingPlanAccess.canDownloadOfflineForQuiz(
          planCode: 'pro',
          hasActiveQuizAccess: false,
        ),
        isTrue,
      );
    });
  });
}
