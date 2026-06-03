import 'package:craftquest_app/core/guest/anonymous_practice_limit_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getCount returns 0 when key is absent', () async {
    expect(await AnonymousPracticeLimitStore.getCount(), 0);
  });

  test('canRedeemCode is true until max redemptions per day', () async {
    expect(await AnonymousPracticeLimitStore.canRedeemCode(), isTrue);

    await AnonymousPracticeLimitStore.recordSuccessfulRedemption();
    expect(await AnonymousPracticeLimitStore.getCount(), 1);
    expect(await AnonymousPracticeLimitStore.canRedeemCode(), isTrue);

    await AnonymousPracticeLimitStore.recordSuccessfulRedemption();
    expect(await AnonymousPracticeLimitStore.getCount(), 2);
    expect(await AnonymousPracticeLimitStore.canRedeemCode(), isTrue);

    await AnonymousPracticeLimitStore.recordSuccessfulRedemption();
    expect(await AnonymousPracticeLimitStore.getCount(), 3);
    expect(await AnonymousPracticeLimitStore.canRedeemCode(), isFalse);
  });

  test('count resets when stored day is not today', () async {
    SharedPreferences.setMockInitialValues({
      'anonymous_practice_count': 3,
      'anonymous_practice_day': '1999-12-31',
    });

    expect(await AnonymousPracticeLimitStore.getCount(), 0);
    expect(await AnonymousPracticeLimitStore.canRedeemCode(), isTrue);
  });
}
